package com.example.fighub

import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val highestRefreshMode = windowManager.defaultDisplay
                .supportedModes
                .maxByOrNull { it.refreshRate }

            if (highestRefreshMode != null) {
                val windowAttributes = window.attributes
                windowAttributes.preferredDisplayModeId = highestRefreshMode.modeId
                window.attributes = windowAttributes
            }
        }
    }
}
