package com.example.ecliniq

import android.content.Context
import android.content.res.Configuration
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.ecliniq/custom_notifications"
    private lateinit var customNotificationService: CustomNotificationService

    override fun attachBaseContext(newBase: Context) {
        // Override font scale to always be 1.0, ignoring system font size settings
        val configuration = Configuration(newBase.resources.configuration)
        configuration.fontScale = 1.0f
        val context = newBase.createConfigurationContext(configuration)
        super.attachBaseContext(context)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        customNotificationService = CustomNotificationService(this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showCustomNotification" -> {
                    try {
                        val title = call.argument<String>("title") ?: "Your Appointment with"
                        val doctorName = call.argument<String>("doctorName") ?: ""
                        val timeInfo = call.argument<String>("timeInfo") ?: ""
                        val expectedTime = call.argument<String>("expectedTime") ?: ""
                        val currentToken = call.argument<Int>("currentToken") ?: 0
                        val userToken = call.argument<Int>("userToken") ?: 0
                        val hospitalName = call.argument<String>("hospitalName") ?: "eClinic-Q"
                        
                        customNotificationService.showCustomNotification(
                            title = title,
                            doctorName = doctorName,
                            timeInfo = timeInfo,
                            expectedTime = expectedTime,
                            currentToken = currentToken,
                            userToken = userToken,
                            hospitalName = hospitalName
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to show custom notification: ${e.message}", null)
                    }
                }
                "updateCustomNotification" -> {
                    try {
                        val doctorName = call.argument<String>("doctorName") ?: ""
                        val timeInfo = call.argument<String>("timeInfo") ?: ""
                        val expectedTime = call.argument<String>("expectedTime") ?: ""
                        val currentToken = call.argument<Int>("currentToken") ?: 0
                        val userToken = call.argument<Int>("userToken") ?: 0
                        val hospitalName = call.argument<String>("hospitalName") ?: "eClinic-Q"
                        
                        customNotificationService.updateCustomNotification(
                            doctorName = doctorName,
                            timeInfo = timeInfo,
                            expectedTime = expectedTime,
                            currentToken = currentToken,
                            userToken = userToken,
                            hospitalName = hospitalName
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to update custom notification: ${e.message}", null)
                    }
                }
                "dismissCustomNotification" -> {
                    try {
                        customNotificationService.dismissNotification()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to dismiss notification: ${e.message}", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}