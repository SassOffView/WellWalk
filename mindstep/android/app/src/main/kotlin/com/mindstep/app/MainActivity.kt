package com.mindstep.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mindstep.app/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "getDeviceInfo" -> result.success(mapOf(
                    "sdk" to android.os.Build.VERSION.SDK_INT,
                    "model" to android.os.Build.MODEL,
                ))
                else -> result.notImplemented()
            }
        }
    }
}
