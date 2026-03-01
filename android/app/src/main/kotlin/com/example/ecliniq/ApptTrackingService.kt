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
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL

class ApptTrackingService : Service() {

    private val channelId = "appt_live_tracking"
    private val channelName = "Appointment Live Tracking"
    private val notificationId = 9999
    private var serviceJob = Job()
    private val serviceScope = CoroutineScope(Dispatchers.Main + serviceJob)
    private var pollingJob: Job? = null

    // State variables
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
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        if (action == "STOP_SERVICE") {
            stopPolling()
            stopForeground(true)
            stopSelf()
            return START_NOT_STICKY
        }

        // Extract data
        currentDoctorName = intent?.getStringExtra("doctorName") ?: currentDoctorName
        currentHospitalName = intent?.getStringExtra("hospitalName") ?: currentHospitalName
        currentUserToken = intent?.getIntExtra("userToken", 0) ?: currentUserToken
        currentTargetToken = intent?.getIntExtra("currentToken", 0) ?: currentTargetToken
        currentExpectedTime = intent?.getStringExtra("expectedTime") ?: currentExpectedTime
        currentId = intent?.getStringExtra("appointmentId") ?: currentId
        authToken = intent?.getStringExtra("authToken") ?: authToken

        updateNotificationUI()

        // Start polling if we have an ID and token
        if (currentId.isNotEmpty() && authToken.isNotEmpty() && pollingJob == null) {
            startPolling()
        }

        return START_STICKY
    }

    private fun startPolling() {
        pollingJob?.cancel()
        pollingJob = serviceScope.launch(Dispatchers.IO) {
            while (isActive) {
                try {
                    pollStatus()
                } catch (e: Exception) {
                    Log.e("ApptTrackingService", "Polling error: ${e.message}")
                }
                delay(30000) // Poll every 30 seconds
            }
        }
    }

    private fun stopPolling() {
        pollingJob?.cancel()
        pollingJob = null
    }

    private suspend fun pollStatus() {
        if (currentId.isEmpty() || authToken.isEmpty()) return

        val url = URL("https://api.upcharq.com/api/eta/appointment/$currentId/status")
        with(url.openConnection() as HttpURLConnection) {
            requestMethod = "GET"
            setRequestProperty("Authorization", "Bearer $authToken")
            setRequestProperty("x-access-token", authToken)
            setRequestProperty("Content-Type", "application/json")

            if (responseCode == HttpURLConnection.HTTP_OK) {
                val response = inputStream.bufferedReader().use { it.readText() }
                val json = JSONObject(response)
                val msg = json.optJSONObject("message")
                if (msg != null) {
                    val newToken = msg.optInt("tokenNo", currentTargetToken)
                    if (newToken != currentTargetToken) {
                        currentTargetToken = newToken
                        withContext(Dispatchers.Main) {
                            updateNotificationUI()
                        }
                    }
                }
            } else {
                Log.e("ApptTrackingService", "Server error: $responseCode")
            }
        }
    }

    private fun updateNotificationUI() {
        val smallView = RemoteViews(packageName, R.layout.custom_appointment_notification_small).apply {
            setTextViewText(R.id.notification_title, "$currentHospitalName • Your Appointment with $currentDoctorName")
        }

        val expandedView = RemoteViews(packageName, R.layout.custom_appointment_notification).apply {
            setTextViewText(R.id.doctor_name, currentDoctorName)
            setTextViewText(R.id.estimated_time, calculateTimeInfo())
            setTextViewText(R.id.expected_time, "Expected Time: $currentExpectedTime")
            setTextViewText(R.id.current_token, currentTargetToken.toString())
            setTextViewText(R.id.your_token, currentUserToken.toString())
            setTextViewText(R.id.start_circle, "S")

            val startToken = if (currentTargetToken > 0 && currentTargetToken < currentUserToken) 1 else 0
            val totalRange = (currentUserToken - startToken).coerceAtLeast(1)
            val progress = (currentTargetToken - startToken).coerceIn(0, totalRange)
            val weight1 = (progress.toFloat() / totalRange.toFloat() * 100).toInt().coerceIn(1, 99)
            val weight2 = 100 - weight1

            setInt(R.id.spacer1, "setLayoutWeight", weight1)
            setInt(R.id.spacer2, "setLayoutWeight", weight2)
            setInt(R.id.spacer_label1, "setLayoutWeight", weight1)
            setInt(R.id.spacer_label2, "setLayoutWeight", weight2)
        }

        val notificationIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            notificationIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setCustomContentView(smallView)
            .setCustomBigContentView(expandedView)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOnlyAlertOnce(true)
            .build()

        startForeground(notificationId, notification)
    }

    private fun calculateTimeInfo(): String {
        val tokensAhead = if (currentTargetToken > 0 && currentUserToken > currentTargetToken) {
            currentUserToken - currentTargetToken
        } else {
            null
        }
        
        return if (currentTargetToken == 0) {
            "Queue not started"
        } else if (tokensAhead != null && tokensAhead > 0) {
            "${tokensAhead * 2} min"
        } else if (currentUserToken == currentTargetToken) {
            "🎉 Your turn!"
        } else {
            "Called"
        }
    }

    override fun onDestroy() {
        stopPolling()
        serviceJob.cancel()
        super.onDestroy()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Shows live appointment updates on lock screen"
                setShowBadge(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }
    }
}
