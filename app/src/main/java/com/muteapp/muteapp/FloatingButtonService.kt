package com.muteapp.muteapp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.Toast
import androidx.core.app.NotificationCompat

class FloatingButtonService : Service() {
    
    private lateinit var windowManager: WindowManager
    private lateinit var floatingView: View
    private lateinit var muteButton: ImageView
    private lateinit var audioManager: AudioManager
    
    private var isMuted = false
    private var clickCount = 0
    private val clickHandler = Handler(Looper.getMainLooper())
    private val clickTimeout = 500L // 500ms timeout for triple click detection
    
    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    
    override fun onCreate() {
        super.onCreate()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        createNotificationChannel()
        createFloatingButton()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, createNotification())
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Floating Button Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Service for floating mute button"
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("MuteApp")
            .setContentText("Floating mute button is active")
            .setSmallIcon(android.R.drawable.sym_def_app_icon)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }
    
    private fun createFloatingButton() {
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        
        // Inflate the floating button layout
        floatingView = LayoutInflater.from(this).inflate(R.layout.floating_button_layout, null)
        muteButton = floatingView.findViewById(R.id.floating_mute_button)
        
        // Set initial button state
        updateButtonAppearance()
        
        // Configure window layout parameters
        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        
        val params = WindowManager.LayoutParams(
            300, // 300px width as requested
            300, // 300px height as requested
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 100
            y = 100
        }
        
        // Add touch listener for drag and click functionality
        floatingView.setOnTouchListener(object : View.OnTouchListener {
            override fun onTouch(view: View, event: MotionEvent): Boolean {
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = params.x
                        initialY = params.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        return true
                    }
                    
                    MotionEvent.ACTION_MOVE -> {
                        params.x = initialX + (event.rawX - initialTouchX).toInt()
                        params.y = initialY + (event.rawY - initialTouchY).toInt()
                        windowManager.updateViewLayout(floatingView, params)
                        return true
                    }
                    
                    MotionEvent.ACTION_UP -> {
                        val deltaX = Math.abs(event.rawX - initialTouchX)
                        val deltaY = Math.abs(event.rawY - initialTouchY)
                        
                        // If it's a tap (not a drag), handle click
                        if (deltaX < 10 && deltaY < 10) {
                            handleButtonClick()
                        }
                        return true
                    }
                }
                return false
            }
        })
        
        // Add the floating button to window manager
        windowManager.addView(floatingView, params)
    }
    
    private fun handleButtonClick() {
        clickCount++
        
        // Remove any pending click timeout
        clickHandler.removeCallbacksAndMessages(null)
        
        when (clickCount) {
            1 -> {
                // Wait for potential additional clicks
                clickHandler.postDelayed({
                    if (clickCount == 1) {
                        // Single click - toggle mute
                        toggleMute()
                    }
                    clickCount = 0
                }, clickTimeout)
            }
            
            2 -> {
                // Double click - just wait for potential third click
                clickHandler.postDelayed({
                    if (clickCount == 2) {
                        // Double click - toggle mute
                        toggleMute()
                    }
                    clickCount = 0
                }, clickTimeout)
            }
            
            3 -> {
                // Triple click - close app
                clickHandler.removeCallbacksAndMessages(null)
                closeApp()
                clickCount = 0
            }
        }
        
        // Reset click count after timeout if no more clicks
        if (clickCount > 3) {
            clickCount = 0
        }
    }
    
    private fun toggleMute() {
        try {
            if (isMuted) {
                // Unmute
                audioManager.adjustStreamVolume(
                    AudioManager.STREAM_MUSIC,
                    AudioManager.ADJUST_UNMUTE,
                    0
                )
                audioManager.adjustStreamVolume(
                    AudioManager.STREAM_RING,
                    AudioManager.ADJUST_UNMUTE,
                    0
                )
                audioManager.adjustStreamVolume(
                    AudioManager.STREAM_NOTIFICATION,
                    AudioManager.ADJUST_UNMUTE,
                    0
                )
                isMuted = false
                Toast.makeText(this, getString(R.string.volume_unmuted), Toast.LENGTH_SHORT).show()
            } else {
                // Mute
                audioManager.adjustStreamVolume(
                    AudioManager.STREAM_MUSIC,
                    AudioManager.ADJUST_MUTE,
                    0
                )
                audioManager.adjustStreamVolume(
                    AudioManager.STREAM_RING,
                    AudioManager.ADJUST_MUTE,
                    0
                )
                audioManager.adjustStreamVolume(
                    AudioManager.STREAM_NOTIFICATION,
                    AudioManager.ADJUST_MUTE,
                    0
                )
                isMuted = true
                Toast.makeText(this, getString(R.string.volume_muted), Toast.LENGTH_SHORT).show()
            }
            
            updateButtonAppearance()
            
        } catch (e: Exception) {
            Toast.makeText(this, "Failed to toggle mute", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun updateButtonAppearance() {
        if (isMuted) {
            muteButton.setImageResource(android.R.drawable.ic_lock_silent_mode)
            muteButton.setBackgroundColor(androidx.core.content.ContextCompat.getColor(this, R.color.mute_button_inactive))
        } else {
            muteButton.setImageResource(android.R.drawable.ic_lock_silent_mode_off)
            muteButton.setBackgroundColor(androidx.core.content.ContextCompat.getColor(this, R.color.mute_button_active))
        }
    }
    
    private fun closeApp() {
        Toast.makeText(this, "Closing MuteApp", Toast.LENGTH_SHORT).show()
        
        // Clear login state to force re-login
        val sharedPref = getSharedPreferences("MuteAppPrefs", MODE_PRIVATE)
        with(sharedPref.edit()) {
            clear()
            apply()
        }
        
        // Stop the service
        stopSelf()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        if (::floatingView.isInitialized) {
            windowManager.removeView(floatingView)
        }
        clickHandler.removeCallbacksAndMessages(null)
    }
    
    companion object {
        private const val CHANNEL_ID = "FloatingButtonChannel"
        private const val NOTIFICATION_ID = 1
    }
}
