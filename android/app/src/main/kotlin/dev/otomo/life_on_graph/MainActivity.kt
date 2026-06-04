package dev.otomo.life_on_graph

import io.flutter.embedding.android.FlutterFragmentActivity

// health プラグインは権限要求に registerForActivityResult を使用する。
// これを動作させるため FlutterActivity ではなく FlutterFragmentActivity を継承する
// (Activity を ComponentActivity にキャストできるようにするため)。
class MainActivity : FlutterFragmentActivity()
