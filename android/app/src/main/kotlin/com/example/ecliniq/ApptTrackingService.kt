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
import kotlinx.coroutines.*
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class ApptTrackingService : Service() {

    companion object {
        const val CHANNEL_ID = "appt_live_tracking_v7"
        const val CHANNEL_NAME = "Live Appointment Tracking"
        const val NOTIFICATION_ID = 9999
        private const val TAG = "ApptTrackingService"
    }

    private var serviceJob = Job()
    private val serviceScope = CoroutineScope(Dispatchers.Main + serviceJob)
    private var pollingJob: Job? = null

    // Persistent state
    private var currentDoctorName = ""
    private var currentHospitalName = ""
    private var currentUserToken = 0
    private var currentTargetToken = 0
    private var currentExpectedTime = ""
    private var currentId = ""
    private var authToken = ""

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        // Initialize with basic notification to satisfy foreground service requirements immediately
        val initialNotification = buildNotification()
        startForeground(NOTIFICATION_ID, initialNotification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == "STOP_SERVICE") {
            stopPolling()
            stopForeground(true)
            stopSelf()
            return START_NOT_STICKY
        }

        // Update state from intent
        intent?.let {
            currentDoctorName = it.getStringExtra("doctorName") ?: currentDoctorName
            currentHospitalName = it.getStringExtra("hospitalName") ?: currentHospitalName
            currentUserToken = it.getIntExtra("userToken", 0).takeIf { it > 0 } ?: currentUserToken
            currentTargetToken = it.getIntExtra("currentToken", 0).takeIf { it > 0 } ?: currentTargetToken
            currentExpectedTime = it.getStringExtra("expectedTime") ?: currentExpectedTime
            currentId = it.getStringExtra("appointmentId") ?: currentId
            authToken = it.getStringExtra("authToken") ?: authToken
        }

        updateNotificationUI()

        // Manage polling
        if (currentId.isNotEmpty() && authToken.isNotEmpty()) {
            if (pollingJob == null) {
                startPolling()
            }
        } else {
            stopPolling()
        }

        return START_STICKY
    }

    private fun startPolling() {
        pollingJob?.cancel()
        pollingJob = serviceScope.launch(Dispatchers.IO) {
            while (isActive) {
                try {
                    pollStatusBar()
                } catch (e: Exception) {
                    Log.e(TAG, "Polling error: ${e.message}")
                }
                delay(30000)
            }
        }
    }

    private fun stopPolling() {
        pollingJob?.cancel()
        pollingJob = null
    }

    private suspend fun pollStatusBar() {
        if (currentId.isEmpty() || authToken.isEmpty()) return
        
        val url = URL("https://api.upcharq.com/api/eta/appointment/$currentId/status")
        try {
            val connection = (url.openConnection() as HttpURLConnection).apply {
                requestMethod = "GET"
                setRequestProperty("Authorization", "Bearer $authToken")
                setRequestProperty("x-access-token", authToken)
                setRequestProperty("Content-Type", "application/json")
                connectTimeout = 5000
                readTimeout = 5000
            }

            if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                val json = JSONObject(response)
                val msg = json.optJSONObject("message")
                if (msg != null) {
                    val newToken = msg.optInt("tokenNo", currentTargetToken)
                    if (newToken != currentTargetToken && newToken > 0) {
                        currentTargetToken = newToken
                        withContext(Dispatchers.Main) {
                            updateNotificationUI()
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to poll API: ${e.message}")
        }
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

            // Dynamic positioning logic matching Zomato's margin approach
            if (currentUserToken > 0) {
                val startToken = if (currentTargetToken > 0 && currentTargetToken < currentUserToken) 1 else 0
                val totalRange = (currentUserToken - startToken).coerceAtLeast(1)
                val progressFrac = (currentTargetToken - startToken).toFloat() / totalRange.toFloat()
                
                // Max margin as proportion of screen width (approx 260dp for safe layout)
                val maxMarginDp = 260f
                val progressMarginDp = (progressFrac * maxMarginDp).coerceIn(0f, maxMarginDp)

                // Use marginStart for compatibility with API 31+
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setViewLayoutMargin(R.id.current_token, RemoteViews.MARGIN_START, progressMarginDp, TypedValue.COMPLEX_UNIT_DIP)
                    setViewLayoutMargin(R.id.label_current, RemoteViews.MARGIN_START, progressMarginDp, TypedValue.COMPLEX_UNIT_DIP)
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
        return if (currentTargetToken == 0) {
            "Queue not started"
        } else if (currentUserToken > currentTargetToken) {
            "${(currentUserToken - currentTargetToken) * 2} min"
        } else if (currentUserToken == currentTargetToken) {
            "🎉 Your turn!"
        } else {
            "Called"
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
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

    override fun onDestroy() {
        stopPolling()
        serviceJob.cancel()
        super.onDestroy()
    }
}
