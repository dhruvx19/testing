package com.example.ecliniq

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class CustomNotificationService(private val context: Context) {
    private val channelId = "appt_push_v5"
    private val channelName = "Appointments"
    private val notificationId = 9999

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Always ensure channel is created/updated
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Shows appointment token updates on lock screen"
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
            android.util.Log.d("CustomNotification", "Channel created: $channelId")
        }
    }

    fun showCustomNotification(
        title: String,
        doctorName: String,
        timeInfo: String,
        expectedTime: String,
        currentToken: Int,
        userToken: Int,
        hospitalName: String = "eClinic-Q"
    ) {
        // Create custom RemoteViews for small (collapsed) notification
        val smallView = RemoteViews(
            context.packageName,
            R.layout.custom_appointment_notification_small
        )
        // Set small view title: "eClinic-Q • Your Appointment with Dr. Name"
        smallView.setTextViewText(
            R.id.notification_title,
            "$hospitalName • Your Appointment with $doctorName"
        )

        // Create custom RemoteViews for expanded notification
        val expandedView = RemoteViews(
            context.packageName,
            R.layout.custom_appointment_notification
        )

        // Set text values for expanded view
        // Note: notification_label is static "Your appointment with" in XML
        expandedView.setTextViewText(R.id.doctor_name, doctorName)
        
        // Status type (hidden by default in XML, can be shown if needed)
        // expandedView.setViewVisibility(R.id.status_type, android.view.View.GONE)
        
        // Time info (e.g. "8 min")
        expandedView.setTextViewText(R.id.estimated_time, timeInfo.replace("in ", ""))
        
        // Expected Time (e.g. "Expected Time: 12:30 PM")
        expandedView.setTextViewText(R.id.expected_time, "Expected Time: $expectedTime")
        
        // Token values in circles
        expandedView.setTextViewText(R.id.current_token, currentToken.toString())
        expandedView.setTextViewText(R.id.your_token, userToken.toString())
        
        // Start circle text is set to "S" in XML but we can set it here too
        expandedView.setTextViewText(R.id.start_circle, "S")

        // Calculate progress weights for logical placement
        // range: Start (assuming token 1 or 0) to userToken
        val startToken = if (currentToken > 0 && currentToken < userToken) 1 else 0
        val totalRange = (userToken - startToken).coerceAtLeast(1)
        val progress = (currentToken - startToken).coerceIn(0, totalRange)
        
        val weight1 = (progress.toFloat() / totalRange.toFloat() * 100).toInt().coerceIn(1, 99)
        val weight2 = 100 - weight1

        // Create intent for notification tap
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build notification with custom layout
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info) 
            .setContentTitle(title)
            .setContentText("$doctorName - $timeInfo")
            .setCustomContentView(smallView)
            .setCustomBigContentView(expandedView)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setColor(0xFF2372EC.toInt())
            .setShowWhen(false)
            .setOnlyAlertOnce(true)
            .setDefaults(Notification.DEFAULT_ALL)
            .build()

        android.util.Log.d("CustomNotification", "Showing notification with ID $notificationId on channel $channelId")
        
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        try {
            notificationManager.notify(notificationId, notification)
            android.util.Log.d("CustomNotification", "notify() called successfully")
        } catch (e: Exception) {
            android.util.Log.e("CustomNotification", "Error calling notify()", e)
            throw e
        }
    }

    fun updateCustomNotification(
        doctorName: String,
        timeInfo: String,
        expectedTime: String,
        currentToken: Int,
        userToken: Int,
        hospitalName: String = "eClinic-Q"
    ) {
        showCustomNotification(
            title = "Your Appointment with",
            doctorName = doctorName,
            timeInfo = timeInfo,
            expectedTime = expectedTime,
            currentToken = currentToken,
            userToken = userToken,
            hospitalName = hospitalName
        )
    }

    fun dismissNotification() {
        val notificationManager = NotificationManagerCompat.from(context)
        notificationManager.cancel(notificationId)
    }
}