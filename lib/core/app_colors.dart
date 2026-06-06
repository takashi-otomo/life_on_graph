import 'package:flutter/material.dart';

/// アプリ全体のカラートークン (Pencil デザイン `designs/m6_visualization.pen` 準拠, #65)。
class AppColors {
  AppColors._();

  // 背景・サーフェス
  static const Color background = Color(0xFFF5F6FA);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFEEF1F5);

  // テキスト階層
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // アクセント
  static const Color accent = Color(0xFF4338CA);
  static const Color accentSoft = Color(0xFFEEF2FF);
  static const Color accentText = Color(0xFF6366F1);

  // 睡眠ステージ色 (設計doc 6.1 / デザイン準拠)
  static const Color sleepDeep = Color(0xFF4338CA);
  static const Color sleepLight = Color(0xFF6366F1);
  static const Color sleepRem = Color(0xFFA78BFA);
  static const Color sleepAwake = Color(0xFFF59E0B);
  static const Color sleepOutOfBed = Color(0xFFFBBF24);
  static const Color sleepAwakeInBed = Color(0xFFFCD34D);
  static const Color sleepUnknown = Color(0xFFCBD5E1);

  // 歩数・心拍
  static const Color steps = Color(0xFF10B981);
  static const Color stepsSoft = Color(0xFFA7F3D0);
  static const Color heart = Color(0xFFF43F5E);

  // 状態
  static const Color positive = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);

  /// 睡眠ステージ種別 → 表示色。未知のステージは [sleepUnknown]。
  static Color sleepStage(String stage) => switch (stage) {
    'deep' => sleepDeep,
    'light' => sleepLight,
    'rem' => sleepRem,
    'awake' => sleepAwake,
    'out_of_bed' => sleepOutOfBed,
    'awake_in_bed' => sleepAwakeInBed,
    _ => sleepUnknown,
  };
}

/// 睡眠ステージの表示メタデータ (積層タイムラインの層順・ラベル, #34)。
class SleepStageInfo {
  const SleepStageInfo(this.key, this.label, this.level);

  /// モデル上のステージ種別キー。
  final String key;

  /// 日本語表示ラベル。
  final String label;

  /// 積層タイムラインの層レベル (0=最上層 awake 〜 大きいほど下層 deep)。
  final int level;

  /// 層順 (上→下): 覚醒 → レム → 浅い → 深い (設計doc 6.1)。
  static const List<SleepStageInfo> ordered = <SleepStageInfo>[
    SleepStageInfo('awake', '覚醒', 0),
    SleepStageInfo('awake_in_bed', '覚醒(在床)', 0),
    SleepStageInfo('out_of_bed', '離床', 0),
    SleepStageInfo('rem', 'レム', 1),
    SleepStageInfo('light', '浅い', 2),
    SleepStageInfo('deep', '深い', 3),
    SleepStageInfo('unknown', '不明', 1),
  ];

  /// [key] に対応するメタdata (無ければ unknown)。
  static SleepStageInfo of(String key) => ordered.firstWhere(
    (s) => s.key == key,
    orElse: () => const SleepStageInfo('unknown', '不明', 1),
  );

  /// 表示する代表ステージ層 (覚醒/レム/浅い/深い) の 4 段階。
  static const List<SleepStageInfo> displayLevels = <SleepStageInfo>[
    SleepStageInfo('awake', '覚醒', 0),
    SleepStageInfo('rem', 'レム', 1),
    SleepStageInfo('light', '浅い', 2),
    SleepStageInfo('deep', '深い', 3),
  ];
}
