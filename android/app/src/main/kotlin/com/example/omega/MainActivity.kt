package com.example.omega

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SCREEN_SECURITY_CHANNEL = "omega/screen_security"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SCREEN_SECURITY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    window.setFlags(
                        WindowManager.LayoutParams.FLAG_SECURE,
                        WindowManager.LayoutParams.FLAG_SECURE
                    )
                    result.success(null)
                }
                "disable" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(null)
                }
                "isEnabled" -> {
                    val isSecure = (window.attributes.flags and
                        WindowManager.LayoutParams.FLAG_SECURE) != 0
                    result.success(isSecure)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Prevent screenshot / app-switcher preview (matches screen security setting)
        // Flutter will call the MethodChannel to toggle this at runtime
        super.onCreate(savedInstanceState)
    }
}
