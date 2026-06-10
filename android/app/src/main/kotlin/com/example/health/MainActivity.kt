package com.example.health

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val channelName = "vn.healthpath/pip"
    private var pipEnabled = false
    private var pipChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pipChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        pipChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isSupported" -> {
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                }
                "isInPipMode" -> {
                    result.success(isInPictureInPictureMode)
                }
                "setPipEnabled" -> {
                    pipEnabled = call.arguments as? Boolean ?: false
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        updateAutoEnterPip()
                    }
                    result.success(null)
                }
                "enterPip" -> {
                    result.success(enterPipNow())
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onUserLeaveHint() {
        if (pipEnabled) {
            notifyPipMode("willEnterPip", true)
            enterPipNow()
        }
        super.onUserLeaveHint()
    }

    private fun enterPipNow(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O || !pipEnabled) {
            return false
        }
        return try {
            val builder = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(1, 1))
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                builder.setAutoEnterEnabled(true)
                builder.setSeamlessResizeEnabled(false)
            }
            val entered = enterPictureInPictureMode(builder.build())
            if (entered) {
                notifyPipMode("pipModeChanged", true)
            }
            entered
        } catch (_: Exception) {
            false
        }
    }

    private fun notifyPipMode(method: String, inPip: Boolean) {
        pipChannel?.invokeMethod(method, inPip)
    }

    private fun updateAutoEnterPip() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        try {
            val builder = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(1, 1))
                .setAutoEnterEnabled(pipEnabled)
                .setSeamlessResizeEnabled(false)
            setPictureInPictureParams(builder.build())
        } catch (_: Exception) {
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration?
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        notifyPipMode("pipModeChanged", isInPictureInPictureMode)
        if (!isInPictureInPictureMode && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            updateAutoEnterPip()
        }
    }
}
