package com.example.fighub

import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val display = windowManager.defaultDisplay
            val currentMode = display.mode
            val highestRefreshMode = display.supportedModes
                .filter {
                    it.physicalWidth == currentMode.physicalWidth &&
                        it.physicalHeight == currentMode.physicalHeight
                }
                .maxByOrNull { it.refreshRate }

            if (highestRefreshMode != null) {
                val windowAttributes = window.attributes
                windowAttributes.preferredDisplayModeId = highestRefreshMode.modeId
                window.attributes = windowAttributes
            }
        }
    }
}
