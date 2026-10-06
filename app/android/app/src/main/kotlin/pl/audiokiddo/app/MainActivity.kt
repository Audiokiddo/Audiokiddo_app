package pl.audiokiddo.app

import android.content.Intent
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.media.MediaRouter2
import android.os.Build
import android.os.StatFs
import android.provider.Settings
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
        // Where the sound goes (`pl.audiokiddo/audio_route`): the system output switcher and
        // the name of the current output (Bluetooth or wired first, else the phone's speaker).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "pl.audiokiddo/audio_route")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "current" -> result.success(currentRoute())
                    "pick" -> result.success(showOutputSwitcher())
                    else -> result.notImplemented()
                }
            }
    }

    private fun currentRoute(): Map<String, String> {
        val audio = getSystemService(AudioManager::class.java)
        val outputs = audio?.getDevices(AudioManager.GET_DEVICES_OUTPUTS).orEmpty()
        val bluetooth = outputs.firstOrNull {
            it.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP ||
                (Build.VERSION.SDK_INT >= 31 && it.type == AudioDeviceInfo.TYPE_BLE_HEADSET)
        }
        if (bluetooth != null) return mapOf("name" to bluetooth.productName.toString(), "kind" to "bluetooth")
        val wired = outputs.firstOrNull {
            it.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES || it.type == AudioDeviceInfo.TYPE_WIRED_HEADSET ||
                it.type == AudioDeviceInfo.TYPE_USB_HEADSET
        }
        if (wired != null) return mapOf("name" to "Słuchawki", "kind" to "headphones")
        return mapOf("name" to "Głośnik telefonu", "kind" to "speaker")
    }

    private fun showOutputSwitcher(): Boolean = try {
        when {
            Build.VERSION.SDK_INT >= 34 -> MediaRouter2.getInstance(this).showSystemOutputSwitcher()
            Build.VERSION.SDK_INT >= 30 -> {
                startActivity(
                    Intent("com.android.settings.panel.action.MEDIA_OUTPUT")
                        .putExtra("com.android.settings.panel.extra.PACKAGE_NAME", packageName)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                )
                true
            }
            else -> {
                startActivity(Intent(Settings.ACTION_BLUETOOTH_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                true
            }
        }
    } catch (e: Exception) {
        false
    }
}
