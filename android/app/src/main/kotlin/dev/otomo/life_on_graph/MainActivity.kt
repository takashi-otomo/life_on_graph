package dev.otomo.life_on_graph

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// health プラグインは権限要求に registerForActivityResult を使用する。
// これを動作させるため FlutterActivity ではなく FlutterFragmentActivity を継承する
// (Activity を ComponentActivity にキャストできるようにするため)。
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "dev.otomo.life_on_graph/launch"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 起動インテントの action を Flutter へ渡し、Health Connect の
        // 権限根拠 (ACTION_SHOW_PERMISSIONS_RATIONALE) / 権限使用状況
        // (VIEW_PERMISSION_USAGE) からの起動時に根拠画面へ遷移させる (#54)。
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLaunchAction" -> result.success(intent?.action)
                    else -> result.notImplemented()
                }
            }
    }
}
