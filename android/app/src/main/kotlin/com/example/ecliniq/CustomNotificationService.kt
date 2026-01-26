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
    private val channelId = "appointment_tracking"
    private val channelName = "Appointment Tracking"
    private val notificationId = 1001

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Check if channel already exists
            val existingChannel = notificationManager.getNotificationChannel(channelId)
            
            // If channel exists but has wrong settings, delete and recreate it
            // Note: This requires the app to be uninstalled/reinstalled or channel deleted manually
            // For now, we'll create it with correct settings if it doesn't exist
            if (existingChannel == null) {
                val channel = NotificationChannel(
                    channelId,
                    channelName,
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Shows appointment token updates on lock screen"
                    setShowBadge(false)
                    enableVibration(false)
                    enableLights(false)
                    lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    setBypassDnd(false)
                    enableLights(false)
                }
                notificationManager.createNotificationChannel(channel)
            }
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
        expandedView.setTextViewText(R.id.hospital_name, hospitalName)
        expandedView.setTextViewText(R.id.doctor_name, doctorName)
        
        // Set status type and time
        expandedView.setTextViewText(R.id.status_type, "On time")
        expandedView.setTextViewText(R.id.estimated_time, " | Arriving in $timeInfo")
        expandedView.setTextViewText(R.id.expected_time, "Expected Time: $expectedTime")
        
        // Set token values
        // expandedView.setTextViewText(12, "S") // Removed: Invalid ID '12'
        expandedView.setTextViewText(R.id.current_token, currentToken.toString())
        expandedView.setTextViewText(R.id.your_token, userToken.toString())

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

        // Build notification with custom layout (matching Zomato structure)
        val notification = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setCustomContentView(smallView) // Collapsed view
            .setCustomBigContentView(expandedView) // Expanded view
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setAutoCancel(false)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setColor(0xFF2372EC.toInt())
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setShowWhen(false)
            .setOnlyAlertOnce(false) // Allow updates to be visible
            .setDefaults(0) // No sound, vibration, or lights
            .setSilent(true)
            .build()

        // Show notification
        val notificationManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        } else {
            null
        }
        
        try {
            if (notificationManager != null) {
                notificationManager.notify(notificationId, notification)
            } else {
                NotificationManagerCompat.from(context).notify(notificationId, notification)
            }
        } catch (e: SecurityException) {
            e.printStackTrace()
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