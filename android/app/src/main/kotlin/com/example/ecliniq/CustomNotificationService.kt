package com.example.ecliniq

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.util.TypedValue
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat

class CustomNotificationService(private val context: Context) {

    companion object {
        const val CHANNEL_ID = "appt_live_tracking_v7"
        const val CHANNEL_NAME = "Live Appointment Tracking"
        const val NOTIFICATION_ID = 9999
        private const val TAG = "CustomNotificationService"

        // Total usable track width in dp (match_parent minus 16dp margin each side = ~260dp on ~360dp screen)
        // The current circle (32dp) slides within this range, stopping 32dp before the end to avoid overlap
        private const val TRACK_WIDTH_DP = 260f
        private const val CIRCLE_DP = 32f
        private const val USABLE_TRACK_DP = TRACK_WIDTH_DP - CIRCLE_DP  // 228dp max margin
    }

    init {
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                CHANNEL_ID, CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Live tracking of appointment token progress"
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableVibration(false)
                enableLights(false)
            }
            manager.createNotificationChannel(channel)
        }
    }

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
        updateNotificationUI(doctorName, hospitalName, currentToken, userToken, expectedTime)
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
        updateNotificationUI(doctorName, hospitalName, currentToken, userToken, expectedTime)
    }

    fun dismissNotification() {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(NOTIFICATION_ID)
    }

    private fun updateNotificationUI(
        doctorName: String,
        hospitalName: String,
        currentToken: Int,
        userToken: Int,
        expectedTime: String
    ) {
        try {
            val notification = buildNotification(doctorName, hospitalName, currentToken, userToken, expectedTime)
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "UI Update Error: \${e.message}")
        }
    }

    private fun buildNotification(
        doctorName: String,
        hospitalName: String,
        currentToken: Int,
        userToken: Int,
        expectedTime: String
    ): Notification {
        val smallView = RemoteViews(context.packageName, R.layout.custom_appointment_notification_small).apply {
            setTextViewText(R.id.notification_title, "\$hospitalName • \$doctorName")
        }

        val expandedView = RemoteViews(context.packageName, R.layout.custom_appointment_notification).apply {
            setTextViewText(R.id.doctor_name, doctorName)
            setTextViewText(R.id.estimated_time, calculateTimeInfo(userToken, currentToken))
            setTextViewText(R.id.expected_time, "Expected Time: \$expectedTime")
            setTextViewText(R.id.current_token, currentToken.toString())
            setTextViewText(R.id.your_token, userToken.toString())
            setTextViewText(R.id.start_circle, "S")

            if (userToken > 0 && currentToken > 0) {
                // --- Progress fraction ---
                // Range is token 1 (start) to userToken (your token)
                val startToken = 1
                val totalRange = (userToken - startToken).coerceAtLeast(1).toFloat()
                val progressFrac = ((currentToken - startToken).toFloat() / totalRange)
                    .coerceIn(0f, 1f)

                // --- Current token group margin ---
                // Moves from 0dp (at Start circle) to USABLE_TRACK_DP (just touching Your No circle)
                val currentMarginDp = progressFrac * USABLE_TRACK_DP

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    // Apply margin to the GROUP
                    setViewLayoutMargin(
                        R.id.current_token_group,
                        RemoteViews.MARGIN_START,
                        currentMarginDp,
                        TypedValue.COMPLEX_UNIT_DIP
                    )

                    // --- Right grey line width ---
                    val greyLineWidthDp = ((1f - progressFrac) * TRACK_WIDTH_DP).coerceAtLeast(0f)
                    setViewLayoutWidth(
                        R.id.progress_line_right,
                        greyLineWidthDp,
                        TypedValue.COMPLEX_UNIT_DIP
                    )
                }
            } else {
                // No progress yet — full grey line, current circle at start
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setViewLayoutMargin(
                        R.id.current_token_group,
                        RemoteViews.MARGIN_START,
                        0f,
                        TypedValue.COMPLEX_UNIT_DIP
                    )
                    setViewLayoutWidth(
                        R.id.progress_line_right,
                        TRACK_WIDTH_DP,
                        TypedValue.COMPLEX_UNIT_DIP
                    )
                }
            }
        }

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setCustomContentView(smallView)
            .setCustomBigContentView(expandedView)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .build()
    }

    private fun calculateTimeInfo(userToken: Int, currentToken: Int): String {
        return when {
            currentToken == 0 -> "Queue not started"
            userToken > currentToken -> "\${(userToken - currentToken) * 2} min"
            userToken == currentToken -> "🎉 Your turn!"
            else -> "Called"
        }
    }
}