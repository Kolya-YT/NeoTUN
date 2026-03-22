package com.neotun.dpi

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.VpnService
import android.os.Bundle
import android.view.animation.AnimationUtils
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private val VPN_REQUEST_CODE = 100

    private lateinit var btnToggle: FrameLayout
    private lateinit var ivShield: ImageView
    private lateinit var tvStatus: TextView

    private val statusReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            updateUi(intent.getBooleanExtra("running", false))
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        btnToggle = findViewById(R.id.btnToggle)
        ivShield  = findViewById(R.id.ivShield)
        tvStatus  = findViewById(R.id.tvStatus)

        btnToggle.setOnClickListener {
            if (DpiVpnService.isRunning) stopBypass() else requestVpnPermission()
        }

        updateUi(DpiVpnService.isRunning)
    }

    override fun onResume() {
        super.onResume()
        registerReceiver(statusReceiver,
            IntentFilter("com.neotun.dpi.STATUS"),
            RECEIVER_NOT_EXPORTED)
        updateUi(DpiVpnService.isRunning)
    }

    override fun onPause() {
        super.onPause()
        unregisterReceiver(statusReceiver)
    }

    private fun requestVpnPermission() {
        val intent = VpnService.prepare(this)
        if (intent != null) startActivityForResult(intent, VPN_REQUEST_CODE)
        else startBypass()
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE && resultCode == Activity.RESULT_OK)
            startBypass()
    }

    private fun startBypass() {
        startForegroundService(
            Intent(this, DpiVpnService::class.java).setAction(DpiVpnService.ACTION_START)
        )
    }

    private fun stopBypass() {
        startService(
            Intent(this, DpiVpnService::class.java).setAction(DpiVpnService.ACTION_STOP)
        )
    }

    private fun updateUi(running: Boolean) {
        if (running) {
            btnToggle.setBackgroundResource(R.drawable.bg_button_active)
            ivShield.alpha = 1.0f
            tvStatus.text = "● Защита активна"
            tvStatus.setTextColor(0xFF27AE60.toInt())
            val pulse = AnimationUtils.loadAnimation(this, R.anim.anim_pulse)
            btnToggle.startAnimation(pulse)
        } else {
            btnToggle.setBackgroundResource(R.drawable.bg_button_idle)
            ivShield.alpha = 0.4f
            tvStatus.text = "Нажмите для включения"
            tvStatus.setTextColor(0xFF666688.toInt())
            btnToggle.clearAnimation()
        }
    }
}
