package com.vitalsense.health

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.vitalsense.health/settings"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openWiFiSettings") {
                try {
                    val intent = Intent(android.provider.Settings.ACTION_WIFI_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                } catch (e: Exception) {
                    result.error("ERROR", "Failed to open Wi-Fi settings", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
