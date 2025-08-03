package com.company.kioskapp

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    
    companion object {
        private const val CHANNEL = "com.kiosk/native"
        private const val TAG = "KioskMainActivity"
        private const val REQUEST_CODE_ENABLE_ADMIN = 1
    }
    
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var adminComponent: ComponentName
    private var methodChannel: MethodChannel? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        initializeKioskComponents()
        handleBootLaunch()
    }
    
    private fun initializeKioskComponents() {
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        adminComponent = ComponentName(this, KioskDeviceAdminReceiver::class.java)
        
        // Configure for kiosk mode
        configureKioskDisplay()
    }
    
    private fun configureKioskDisplay() {
        // Hide system UI for kiosk mode
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
            or View.SYSTEM_UI_FLAG_FULLSCREEN
            or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
        )
        
        // Keep screen on
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD)
        window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
    }
    
    private fun handleBootLaunch() {
        val launchedFromBoot = intent.getBooleanExtra("launched_from_boot", false)
        if (launchedFromBoot) {
            Log.d(TAG, "App launched from boot - enabling kiosk mode")
            // Auto-enable kiosk mode when launched from boot
            enableKioskMode()
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "enableKioskMode" -> {
                    enableKioskMode()
                    result.success(true)
                }
                "disableKioskMode" -> {
                    disableKioskMode()
                    result.success(true)
                }
                "checkDeviceAdmin" -> {
                    result.success(isDeviceAdminActive())
                }
                "requestDeviceAdmin" -> {
                    requestDeviceAdminPermission()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun enableKioskMode() {
        if (isDeviceAdminActive()) {
            try {
                startLockTask()
                Log.d(TAG, "Kiosk mode enabled successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to enable kiosk mode", e)
            }
        } else {
            Log.w(TAG, "Device admin not active - requesting permission")
            requestDeviceAdminPermission()
        }
    }
    
    private fun disableKioskMode() {
        try {
            stopLockTask()
            Log.d(TAG, "Kiosk mode disabled")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to disable kiosk mode", e)
        }
    }
    
    private fun isDeviceAdminActive(): Boolean {
        return devicePolicyManager.isAdminActive(adminComponent)
    }
    
    private fun requestDeviceAdminPermission() {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
            putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, 
                "Enable device admin to use kiosk mode features")
        }
        startActivityForResult(intent, REQUEST_CODE_ENABLE_ADMIN)
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_CODE_ENABLE_ADMIN) {
            if (resultCode == RESULT_OK) {
                Log.d(TAG, "Device admin permission granted")
                enableKioskMode()
            } else {
                Log.w(TAG, "Device admin permission denied")
            }
        }
    }


    
    override fun onBackPressed() {
        // Disable back button in kiosk mode
        if (isDeviceAdminActive()) {
            Log.d(TAG, "Back button disabled in kiosk mode")
            return
        }
        super.onBackPressed()
    }
}