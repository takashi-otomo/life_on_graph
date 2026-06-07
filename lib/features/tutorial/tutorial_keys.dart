import 'package:flutter/widgets.dart';

/// チュートリアル (#109) のスポットライト対象に付与する GlobalKey 群。
///
/// 各対象ウィジェットにこのキーを付け、オーバーレイが画面上の矩形を測って
/// ハイライトする。
class TutorialKeys {
  TutorialKeys._();

  /// 日付ナビ (タップでカレンダー)。
  static final GlobalKey dateNav = GlobalKey(debugLabel: 'tut_dateNav');

  /// データカード領域 (ホームのコンテンツ)。
  static final GlobalKey cards = GlobalKey(debugLabel: 'tut_cards');

  /// 下部タブバー。
  static final GlobalKey tabBar = GlobalKey(debugLabel: 'tut_tabBar');
}
