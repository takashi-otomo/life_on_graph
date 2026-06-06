import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ボトムタブの選択インデックス (0=ホーム, 1=サマリー, 2=設定) (#66)。
///
/// サマリー[日]からホーム詳細へのドリルダウン等、画面横断でタブを切り替えるため
/// プロバイダとして公開する。
class NavTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// タブを選択する。
  void select(int index) => state = index;
}

/// 選択中タブのプロバイダ。
final navTabProvider = NotifierProvider<NavTabNotifier, int>(
  NavTabNotifier.new,
);
