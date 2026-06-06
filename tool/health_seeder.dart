// Health Connect テストデータ シーダー (デバッグ専用ツール)。
//
// 過去 2 か月分 (60 日) の睡眠・歩数・心拍ダミーデータを Health Connect へ書き込む。
// エッジケースを網羅し、各日のシナリオと目的は docs/health_seed_data.md に対応する。
//
// 使い方:
//   1) エミュレータ/実機を起動
//   2) flutter run -t tool/health_seeder.dart -d <serial>
//   3) 画面の「投入する」をタップ → Health Connect の WRITE 権限を許可
//
// 注意: 本ツールはデバッグビルド専用 (WRITE 権限は src/debug にのみ宣言)。
// 製品アプリ (release) は READ 権限のみで、本ファイルは出荷物に含めない。
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:health/health.dart';

void main() => runApp(const SeederApp());

/// 1 件の書き込みデータ。
class _Write {
  _Write(this.type, this.value, this.start, this.end);
  final HealthDataType type;
  final double value;
  final DateTime start;
  final DateTime end;
}

/// 1 日分のシナリオ (ドキュメントと対応)。
class _DayScenario {
  _DayScenario({
    required this.daysAgo,
    required this.label,
    required this.purpose,
    required this.writes,
  });

  /// 何日前か (1 = 昨日)。
  final int daysAgo;

  /// シナリオ名。
  final String label;

  /// 投入目的 (検証観点)。
  final String purpose;

  final List<_Write> writes;
}

const List<HealthDataType> _writeTypes = <HealthDataType>[
  HealthDataType.SLEEP_DEEP,
  HealthDataType.SLEEP_LIGHT,
  HealthDataType.SLEEP_REM,
  HealthDataType.SLEEP_AWAKE,
  HealthDataType.SLEEP_AWAKE_IN_BED,
  HealthDataType.SLEEP_OUT_OF_BED,
  HealthDataType.SLEEP_UNKNOWN,
  HealthDataType.STEPS,
  HealthDataType.HEART_RATE,
];

/// ステージ種別キー → HealthDataType。
const Map<String, HealthDataType> _stageType = <String, HealthDataType>{
  'deep': HealthDataType.SLEEP_DEEP,
  'light': HealthDataType.SLEEP_LIGHT,
  'rem': HealthDataType.SLEEP_REM,
  'awake': HealthDataType.SLEEP_AWAKE,
  'awake_in_bed': HealthDataType.SLEEP_AWAKE_IN_BED,
  'out_of_bed': HealthDataType.SLEEP_OUT_OF_BED,
  'unknown': HealthDataType.SLEEP_UNKNOWN,
};

/// シードデータ生成器。`today` は当日 0:00。
class _SeedGenerator {
  _SeedGenerator(this.today);
  final DateTime today;

  DateTime _day(int daysAgo) =>
      DateTime(today.year, today.month, today.day - daysAgo);

  /// 睡眠セグメント (key, 開始分, 終了分) を基準日の 23:00 起点で書き込みへ変換。
  /// 分は 23:00 を 0 とした相対分。
  List<_Write> _sleep(
    DateTime base,
    List<(String, int, int)> segs, {
    int startHour = 23,
  }) {
    final DateTime origin = DateTime(
      base.year,
      base.month,
      base.day,
      startHour,
    );
    return <_Write>[
      for (final (stage, s, e) in segs)
        _Write(
          _stageType[stage]!,
          0,
          origin.add(Duration(minutes: s)),
          origin.add(Duration(minutes: e)),
        ),
    ];
  }

  /// 標準的な夜の睡眠 (全ステージ・日跨ぎ ~7.5h)。
  List<(String, int, int)> _normalNight(Random r) {
    // 23:00(0) 〜 翌6:40(460) 相当をステージで構成。
    return <(String, int, int)>[
      ('light', 0, 25),
      ('deep', 25, 95),
      ('light', 95, 140),
      ('rem', 140, 175),
      ('light', 175, 210),
      ('deep', 210, 250),
      ('awake', 250, 256),
      ('light', 256, 305),
      ('rem', 305, 350),
      ('light', 350, 405),
      ('rem', 405, 440),
      ('light', 440, 460 + r.nextInt(30)),
    ];
  }

  /// 歩数 (時間帯別)。activeHours の各時間に歩数を割り当てる。
  List<_Write> _steps(DateTime day, Map<int, int> hourly) {
    final DateTime d0 = DateTime(day.year, day.month, day.day);
    return <_Write>[
      for (final entry in hourly.entries)
        _Write(
          HealthDataType.STEPS,
          entry.value.toDouble(),
          d0.add(Duration(hours: entry.key)),
          d0.add(Duration(hours: entry.key, minutes: 59)),
        ),
    ];
  }

  /// 標準的な活動量 (合計 ~8000-11000)。
  Map<int, int> _activeDay(Random r) => <int, int>{
    7: 400 + r.nextInt(300),
    8: 1200 + r.nextInt(600),
    9: 600 + r.nextInt(400),
    12: 900 + r.nextInt(500),
    13: 500 + r.nextInt(300),
    15: 700 + r.nextInt(500),
    18: 1400 + r.nextInt(800),
    19: 1000 + r.nextInt(600),
    21: 400 + r.nextInt(400),
  };

  /// 心拍 (intervalMin 毎、安静時 resting〜日中 active を緩やかに変動)。
  List<_Write> _hr(
    DateTime day, {
    int intervalMin = 120,
    int resting = 56,
    int active = 95,
    int? spikeHour,
    int spikeBpm = 150,
  }) {
    final DateTime d0 = DateTime(day.year, day.month, day.day);
    final List<_Write> out = <_Write>[];
    for (int m = 0; m < 24 * 60; m += intervalMin) {
      final int hour = m ~/ 60;
      // 夜間 (0-6, 22-24) は安静、日中はやや高め。
      final bool night = hour < 6 || hour >= 22;
      int bpm = night ? resting + (m % 7) : active - 10 + (m % 15);
      if (spikeHour != null && hour == spikeHour) bpm = spikeBpm;
      final DateTime t = d0.add(Duration(minutes: m));
      out.add(_Write(HealthDataType.HEART_RATE, bpm.toDouble(), t, t));
    }
    return out;
  }

  /// 全シナリオを生成する。
  List<_DayScenario> generate() {
    final List<_DayScenario> days = <_DayScenario>[];

    void add(int daysAgo, String label, String purpose, List<_Write> writes) {
      days.add(
        _DayScenario(
          daysAgo: daysAgo,
          label: label,
          purpose: purpose,
          writes: writes,
        ),
      );
    }

    // --- エッジケース (固定シナリオ) ---
    final Random r = Random(42);

    add(1, '標準的な夜 + 活動的な日', '全ステージ・日跨ぎ睡眠/通常歩数/通常心拍の基本表示', <_Write>[
      ..._sleep(_day(1), _normalNight(r)),
      ..._steps(_day(1), _activeDay(r)),
      ..._hr(_day(1)),
    ]);

    add(2, '短時間睡眠 (3時間)', '睡眠合計が短い場合のサマリー/タイムライン', <_Write>[
      ..._sleep(_day(2), const <(String, int, int)>[
        ('light', 0, 40),
        ('deep', 40, 90),
        ('rem', 90, 130),
        ('light', 130, 180),
      ]),
      ..._steps(_day(2), _activeDay(r)),
      ..._hr(_day(2)),
    ]);

    add(3, '長時間睡眠 (10時間)', '睡眠合計が長い場合の比率バー/合計表示', <_Write>[
      ..._sleep(_day(3), const <(String, int, int)>[
        ('light', 0, 60),
        ('deep', 60, 180),
        ('light', 180, 280),
        ('rem', 280, 340),
        ('light', 340, 440),
        ('deep', 440, 520),
        ('rem', 520, 600),
      ]),
      ..._steps(_day(3), _activeDay(r)),
      ..._hr(_day(3)),
    ]);

    add(4, '睡眠なし (歩数/心拍あり)', '睡眠カードの空状態 + 他データは表示', <_Write>[
      ..._steps(_day(4), _activeDay(r)),
      ..._hr(_day(4)),
    ]);

    add(5, '昼寝のみ (日中睡眠)', '夜以外の睡眠セッションのタイムライン表示', <_Write>[
      ..._sleep(_day(5), const <(String, int, int)>[
        ('light', 0, 20),
        ('deep', 20, 60),
        ('light', 60, 90),
      ], startHour: 14),
      ..._steps(_day(5), _activeDay(r)),
      ..._hr(_day(5)),
    ]);

    add(6, '分断睡眠 (微小覚醒多数)', '隣接結合 (mergeAdjacentSameStage) と覚醒過多の表示', <_Write>[
      ..._sleep(_day(6), <(String, int, int)>[
        for (int i = 0; i < 12; i++) ...<(String, int, int)>[
          ('light', i * 40, i * 40 + 18),
          ('awake', i * 40 + 18, i * 40 + 22),
          ('deep', i * 40 + 22, i * 40 + 40),
        ],
      ]),
      ..._steps(_day(6), _activeDay(r)),
      ..._hr(_day(6)),
    ]);

    add(7, '歩数ゼロ日', '歩数カードの空/ゼロ表示', <_Write>[
      ..._sleep(_day(7), _normalNight(r)),
      ..._hr(_day(7)),
    ]);

    add(8, '高歩数日 (約25000)', '棒グラフの最大値スケーリング', <_Write>[
      ..._sleep(_day(8), _normalNight(r)),
      ..._steps(_day(8), <int, int>{
        for (int h = 6; h <= 21; h++) h: 1200 + r.nextInt(600),
      }),
      ..._hr(_day(8)),
    ]);

    add(9, '歩数が日跨ぎ', '区間が午前0時をまたぐ歩数の按分集計 (P1-2 検証)', <_Write>[
      ..._sleep(_day(9), _normalNight(r)),
      // 23:30(前日) → 00:30(当日) の歩数。
      _Write(
        HealthDataType.STEPS,
        600,
        DateTime(_day(10).year, _day(10).month, _day(10).day, 23, 30),
        DateTime(_day(9).year, _day(9).month, _day(9).day, 0, 30),
      ),
      ..._steps(_day(9), _activeDay(r)),
      ..._hr(_day(9)),
    ]);

    add(10, '運動による高心拍スパイク (180)', '心拍折れ線の上振れ・最高値表示', <_Write>[
      ..._sleep(_day(10), _normalNight(r)),
      ..._steps(_day(10), _activeDay(r)),
      ..._hr(_day(10), spikeHour: 18, spikeBpm: 180),
    ]);

    add(11, '安静時心拍が非常に低い (40)', '心拍の下振れ・安静値表示', <_Write>[
      ..._sleep(_day(11), _normalNight(r)),
      ..._steps(_day(11), _activeDay(r)),
      ..._hr(_day(11), resting: 40, active: 70),
    ]);

    add(12, '心拍データなし', '心拍カードの空状態', <_Write>[
      ..._sleep(_day(12), _normalNight(r)),
      ..._steps(_day(12), _activeDay(r)),
    ]);

    add(13, '浅い睡眠のみ (deep/rem なし)', '一部ステージ欠如時の比率バー/凡例', <_Write>[
      ..._sleep(_day(13), const <(String, int, int)>[
        ('light', 0, 200),
        ('awake', 200, 210),
        ('light', 210, 420),
      ]),
      ..._steps(_day(13), _activeDay(r)),
      ..._hr(_day(13)),
    ]);

    add(14, '覚醒過多の夜', '覚醒比率が高い場合の表示', <_Write>[
      ..._sleep(_day(14), const <(String, int, int)>[
        ('light', 0, 40),
        ('awake', 40, 90),
        ('light', 90, 130),
        ('awake', 130, 200),
        ('deep', 200, 240),
        ('awake', 240, 300),
        ('light', 300, 360),
      ]),
      ..._steps(_day(14), _activeDay(r)),
      ..._hr(_day(14)),
    ]);

    add(
      15,
      'out_of_bed / awake_in_bed ステージ',
      '覚醒エイリアスの正規化 (awake へ畳み込み)',
      <_Write>[
        ..._sleep(_day(15), const <(String, int, int)>[
          ('light', 0, 60),
          ('deep', 60, 140),
          ('awake_in_bed', 140, 160),
          ('out_of_bed', 160, 180),
          ('light', 180, 300),
          ('rem', 300, 360),
        ]),
        ..._steps(_day(15), _activeDay(r)),
        ..._hr(_day(15)),
      ],
    );

    add(16, '睡眠セグメント重複 (同一ソース)', 'オーバーラップ解消 (mergeOverlaps) の検証', <_Write>[
      ..._sleep(_day(16), const <(String, int, int)>[
        ('deep', 0, 120),
        ('light', 60, 180), // 60-120 が deep と重複
        ('rem', 150, 240),
        ('light', 220, 360),
      ]),
      ..._steps(_day(16), _activeDay(r)),
      ..._hr(_day(16)),
    ]);

    final DateTime d17 = _day(17);
    add(17, '正午境界をまたぐ昼寝', '境界クリッピング (clipSegmentsToDay) の検証', <_Write>[
      // 11:30 → 12:30 (LOG の正午 noon 境界をまたぐ)。
      _Write(
        HealthDataType.SLEEP_LIGHT,
        0,
        DateTime(d17.year, d17.month, d17.day, 11, 30),
        DateTime(d17.year, d17.month, d17.day, 12, 0),
      ),
      _Write(
        HealthDataType.SLEEP_DEEP,
        0,
        DateTime(d17.year, d17.month, d17.day, 12, 0),
        DateTime(d17.year, d17.month, d17.day, 12, 30),
      ),
      ..._steps(d17, _activeDay(r)),
      ..._hr(d17),
    ]);

    add(18, '不明 (unknown) ステージ含む', 'unknown ステージの集計/凡例表示', <_Write>[
      ..._sleep(_day(18), const <(String, int, int)>[
        ('light', 0, 60),
        ('unknown', 60, 120),
        ('deep', 120, 200),
        ('light', 200, 360),
      ]),
      ..._steps(_day(18), _activeDay(r)),
      ..._hr(_day(18)),
    ]);

    add(19, '心拍が疎 (1日数点)', '心拍データが少ない場合の折れ線', <_Write>[
      ..._sleep(_day(19), _normalNight(r)),
      ..._steps(_day(19), _activeDay(r)),
      ..._hr(_day(19), intervalMin: 240),
    ]);

    add(20, '心拍が密 (15分毎)', '心拍データが多い場合の折れ線描画性能', <_Write>[
      ..._sleep(_day(20), _normalNight(r)),
      ..._steps(_day(20), _activeDay(r)),
      ..._hr(_day(20), intervalMin: 15),
    ]);

    // --- ベースライン (21〜60 日前: 正常範囲のランダム変動) ---
    for (int k = 21; k <= 60; k++) {
      final Random rk = Random(1000 + k);
      add(k, 'ベースライン', '通常範囲の睡眠/歩数/心拍 (時系列の連続性・サマリーの平均/トレンド)', <_Write>[
        ..._sleep(_day(k), _normalNight(rk)),
        ..._steps(_day(k), _activeDay(rk)),
        ..._hr(
          _day(k),
          resting: 52 + rk.nextInt(8),
          active: 88 + rk.nextInt(20),
        ),
      ]);
    }

    return days;
  }
}

class SeederApp extends StatelessWidget {
  const SeederApp({super.key});
  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: SeederPage(), debugShowCheckedModeBanner: false);
}

class SeederPage extends StatefulWidget {
  const SeederPage({super.key});
  @override
  State<SeederPage> createState() => _SeederPageState();
}

class _SeederPageState extends State<SeederPage> {
  final Health _health = Health();
  String _status = 'Health Connect テストデータ シーダー';
  bool _running = false;
  double _progress = 0;

  Future<void> _seed() async {
    setState(() {
      _running = true;
      _status = '権限を要求しています...';
      _progress = 0;
    });
    try {
      await _health.configure();
      final bool granted = await _health.requestAuthorization(
        _writeTypes,
        permissions: List<HealthDataAccess>.filled(
          _writeTypes.length,
          HealthDataAccess.WRITE,
        ),
      );
      if (!granted) {
        setState(() {
          _status = 'WRITE 権限が許可されませんでした';
          _running = false;
        });
        return;
      }

      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);

      // 既存のシードデータを削除して再投入時の重複を防ぐ (過去 ~62 日)。
      setState(() => _status = '既存データを削除中...');
      final DateTime clearFrom = today.subtract(const Duration(days: 62));
      final DateTime clearTo = today.add(const Duration(days: 1));
      for (final HealthDataType t in _writeTypes) {
        try {
          await _health.delete(type: t, startTime: clearFrom, endTime: clearTo);
        } catch (_) {}
      }

      final List<_DayScenario> scenarios = _SeedGenerator(today).generate();
      final List<_Write> all = <_Write>[for (final s in scenarios) ...s.writes];

      int done = 0;
      int ok = 0;
      for (final _Write w in all) {
        // Health Connect の書き込みクォータ超過に備え、失敗時はバックオフして
        // リトライする (クォータは時間で回復する)。
        bool success = false;
        for (int attempt = 0; attempt < 8 && !success; attempt++) {
          try {
            success = await _health.writeHealthData(
              value: w.value,
              type: w.type,
              startTime: w.start,
              endTime: w.end,
              recordingMethod: RecordingMethod.automatic,
            );
          } catch (_) {
            success = false;
          }
          if (!success) {
            await Future<void>.delayed(
              Duration(milliseconds: 200 * (attempt + 1)),
            );
          }
        }
        if (success) ok++;
        done++;
        // バースト的なクォータ消費を避けるため軽くスロットルする。
        await Future<void>.delayed(const Duration(milliseconds: 15));
        if (done % 25 == 0 || done == all.length) {
          setState(() {
            _progress = done / all.length;
            _status = '投入中... $done / ${all.length} 件 (成功 $ok)';
          });
        }
      }

      setState(() {
        _status =
            '完了: ${scenarios.length} 日分 / $ok 件投入。\nLOG アプリで日付を選択して確認してください。';
        _running = false;
        _progress = 1;
      });
    } catch (e) {
      setState(() {
        _status = 'エラー: $e';
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Health Seeder (debug)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            if (_running) LinearProgressIndicator(value: _progress),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _running ? null : _seed,
              child: const Text('過去2か月分のテストデータを投入する'),
            ),
          ],
        ),
      ),
    );
  }
}
