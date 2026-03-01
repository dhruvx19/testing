package com.example.ecliniq

import android.content.Context
import android.content.Intent
import android.os.Build

class CustomNotificationService(private val context: Context) {

    fun showCustomNotification(
        title: String,
        doctorName: String,
        timeInfo: String,
        expectedTime: String,
        currentToken: Int,
        userToken: Int,
        appointmentId: String = "",
        authToken: String = "",
        hospitalName: String = "eClinic-Q"
    ) {
        val serviceIntent = Intent(context, ApptTrackingService::class.java).apply {
            putExtra("title", title)
            putExtra("doctorName", doctorName)
            putExtra("timeInfo", timeInfo)
            putExtra("expectedTime", expectedTime)
            putExtra("currentToken", currentToken)
            putExtra("userToken", userToken)
            putExtra("appointmentId", appointmentId)
            putExtra("authToken", authToken)
            putExtra("hospitalName", hospitalName)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }

    fun updateCustomNotification(
        doctorName: String,
        timeInfo: String,
        expectedTime: String,
        currentToken: Int,
        userToken: Int,
        appointmentId: String = "",
        authToken: String = "",
        hospitalName: String = "eClinic-Q"
    ) {
        showCustomNotification(
            title = "Your Appointment with",
            doctorName = doctorName,
            timeInfo = timeInfo,
            expectedTime = expectedTime,
            currentToken = currentToken,
            userToken = userToken,
            appointmentId = appointmentId,
            authToken = authToken,
            hospitalName = hospitalName
        )
    }

    fun dismissNotification() {
        val stopIntent = Intent(context, ApptTrackingService::class.java).apply {
            action = "STOP_SERVICE"
        }
        context.startService(stopIntent)
    }
}