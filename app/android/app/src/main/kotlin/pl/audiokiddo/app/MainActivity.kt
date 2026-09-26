package pl.audiokiddo.app

import android.os.StatFs
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// AudioServiceActivity keeps one Flutter engine shared with the background playback service.
class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Free disk space for downloads (`pl.audiokiddo/storage`). Backups are already
        // disabled for the whole app (allowBackup=false), so excludeFromBackup is a no-op.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pl.audiokiddo/storage")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "freeBytes" -> result.success(StatFs(filesDir.path).availableBytes)
                    "excludeFromBackup" -> result.success(null)
                    else -> result.notImplemented()
                }
            }
    }
}
