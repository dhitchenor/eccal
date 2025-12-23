package com.dhitchenor.eccal

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var safHandler: SafHandler
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize SAF handler
        safHandler = SafHandler(this)
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SafHandler.CHANNEL_NAME
        )
        safHandler.setupMethodChannel(channel)
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        // Forward to SAF handler
        safHandler.handleActivityResult(requestCode, resultCode, data)
    }
}