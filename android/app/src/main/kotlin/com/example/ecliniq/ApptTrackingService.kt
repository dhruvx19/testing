package com.example.ecliniq

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.util.TypedValue
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat

class ApptTrackingService : Service() {

    companion object {
        const val CHANNEL_ID = "appt_live_tracking_v7"
        const val CHANNEL_NAME = "Live Appointment Tracking"
        const val NOTIFICATION_ID = 9999
        private const val TAG = "ApptTrackingService"

        // Total usable track width in dp (match_parent minus 16dp margin each side = ~260dp on ~360dp screen)
        // The current circle (32dp) slides within this range, stopping 32dp before the end to avoid overlap
        private const val TRACK_WIDTH_DP = 260f
        private const val CIRCLE_DP = 32f
        private const val USABLE_TRACK_DP = TRACK_WIDTH_DP - CIRCLE_DP  // 228dp max margin
    }

    // Persistent state — updated by FCM push data messages via SLOT_LIVE_UPDATE
    // No HTTP polling; all updates come from the backend via FCM data-only push.
    private var currentDoctorName = ""
    private var currentHospitalName = ""
    private var currentUserToken = 0
    private var currentTargetToken = 0
    private var currentExpectedTime = ""
    private var currentId = ""

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        val initialNotification = buildNotification()
        startForeground(NOTIFICATION_ID, initialNotification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == "STOP_SERVICE") {
            stopForeground(true)
            stopSelf()
            return START_NOT_STICKY
        }

        intent?.let {
            currentDoctorName = it.getStringExtra("doctorName") ?: currentDoctorName
            currentHospitalName = it.getStringExtra("hospitalName") ?: currentHospitalName
            currentUserToken = it.getIntExtra("userToken", 0).takeIf { v -> v > 0 } ?: currentUserToken
            // currentToken=0 is valid (queue not started yet), so accept 0
            val incomingCurrentToken = it.getIntExtra("currentToken", -1)
            if (incomingCurrentToken >= 0) currentTargetToken = incomingCurrentToken
            currentExpectedTime = it.getStringExtra("expectedTime") ?: currentExpectedTime
            currentId = it.getStringExtra("appointmentId") ?: currentId
        }

        updateNotificationUI()

        return START_STICKY
    }

    private fun buildNotification(): Notification {
        val smallView = RemoteViews(packageName, R.layout.custom_appointment_notification_small).apply {
            setTextViewText(R.id.notification_title, "$currentHospitalName • $currentDoctorName")
        }

        val expandedView = RemoteViews(packageName, R.layout.custom_appointment_notification).apply {
            setTextViewText(R.id.doctor_name, currentDoctorName)
            setTextViewText(R.id.estimated_time, calculateTimeInfo())
            setTextViewText(R.id.expected_time, "Expected Time: $currentExpectedTime")
            setTextViewText(R.id.current_token, currentTargetToken.toString())
            setTextViewText(R.id.your_token, currentUserToken.toString())
            setTextViewText(R.id.start_circle, "S")

            if (currentUserToken > 0) {
                // --- Progress fraction ---
                // Range is token 1 (start) to currentUserToken (your token)
                val startToken = 1
                val totalRange = (currentUserToken - startToken).coerceAtLeast(1).toFloat()
                val progressFrac = ((currentTargetToken - startToken).toFloat() / totalRange)
                    .coerceIn(0f, 1f)

                // --- Current token group margin ---
                // Moves from 0dp (at Start circle) to USABLE_TRACK_DP (at Your No circle)
                val currentMarginDp = progressFrac * USABLE_TRACK_DP

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setViewLayoutMargin(
                        R.id.current_token_group,
                        RemoteViews.MARGIN_START,
                        currentMarginDp,
                        TypedValue.COMPLEX_UNIT_DIP
                    )

                    // Right grey line shrinks as current token advances toward your token
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

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
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

    private fun updateNotificationUI() {
        try {
            val notification = buildNotification()
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "UI Update Error: ${e.message}")
        }
    }

    private fun calculateTimeInfo(): String {
        return when {
            currentTargetToken == 0 -> "Queue not started"
            currentUserToken > currentTargetToken -> "${(currentUserToken - currentTargetToken) * 2} min"
            currentUserToken == currentTargetToken -> "🎉 Your turn!"
            else -> "Called"
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                CHANNEL_ID, CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Live tracking of appointment token progress (FCM-driven)"
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                enableVibration(false)
                enableLights(false)
            }
            manager.createNotificationChannel(channel)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
    }
}