package dev.otomo.life_on_graph

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// health プラグインは権限要求に registerForActivityResult を使用する。
// これを動作させるため FlutterActivity ではなく FlutterFragmentActivity を継承する
// (Activity を ComponentActivity にキャストできるようにするため)。
class MainActivity : FlutterFragmentActivity() {
    private val channelName = "dev.otomo.life_on_graph/launch"
    private var channel: MethodChannel? = null

    private val rationaleActions = setOf(
        "androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE",
        "android.intent.action.VIEW_PERMISSION_USAGE",
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 起動インテントの action を Flutter へ提供し、Health Connect の権限根拠
        // (ACTION_SHOW_PERMISSIONS_RATIONALE) / 権限使用状況 (VIEW_PERMISSION_USAGE)
        // からの起動時に根拠画面へ遷移させる (#54)。
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .apply {
                setMethodCallHandler { call, result ->
                    when (call.method) {
                        "getLaunchAction" -> result.success(intent?.action)
                        else -> result.notImplemented()
                    }
                }
            }
    }

    // singleTop により、実行中の Activity へ権限根拠インテントが onNewIntent で
    // 配信される場合がある。その際は Flutter 側へ通知して根拠画面を表示させる (#54)。
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action in rationaleActions) {
            channel?.invokeMethod("showRationale", null)
        }
    }
}
