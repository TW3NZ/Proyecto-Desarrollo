package com.example.my_daily_routine

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var updater: AppUpdater? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        updater = AppUpdater(this, flutterEngine.dartExecutor.binaryMessenger)
    }
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        updater?.close()
        updater = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
