package app.ergon.ergon

import android.content.Intent
import app.ergon.ergon.widget.AgendaWidgetProvider
import app.ergon.ergon.widget.WidgetStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter UI and bridges the few Android-only features:
 * the home-screen widget data and "open task" / "new task" launch intents.
 * Purely local: nothing here touches the network.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var launchTaskId: Int? = null
    private var launchQuickAdd = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        readLaunch(intent)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidget" -> {
                        WidgetStore.save(this@MainActivity, call.arguments as String)
                        AgendaWidgetProvider.refreshAll(this@MainActivity)
                        result.success(null)
                    }
                    "consumeLaunchTaskId" -> {
                        result.success(launchTaskId)
                        launchTaskId = null
                    }
                    "consumeLaunchQuickAdd" -> {
                        result.success(launchQuickAdd)
                        launchQuickAdd = false
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        // App already running: forward straight to Dart.
        when (intent.action) {
            ACTION_OPEN_TASK -> {
                val id = intent.getIntExtra(EXTRA_TASK_ID, -1)
                if (id >= 0) channel?.invokeMethod("openTask", id)
            }
            ACTION_QUICK_ADD -> channel?.invokeMethod("quickAdd", null)
        }
    }

    private fun readLaunch(intent: Intent?) {
        when (intent?.action) {
            ACTION_OPEN_TASK -> intent.getIntExtra(EXTRA_TASK_ID, -1).takeIf { it >= 0 }?.let { launchTaskId = it }
            ACTION_QUICK_ADD -> launchQuickAdd = true
        }
    }

    companion object {
        const val CHANNEL = "app.ergon/platform"
        const val ACTION_OPEN_TASK = "app.ergon.action.OPEN_TASK"
        const val ACTION_QUICK_ADD = "app.ergon.action.QUICK_ADD"
        const val EXTRA_TASK_ID = "ergon_task_id"
    }
}
