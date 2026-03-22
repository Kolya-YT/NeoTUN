package com.neotun.dpi

import android.animation.ArgbEvaluator
import android.animation.ValueAnimator
import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.view.View
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
    private lateinit var vGlow: View

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
        vGlow     = findViewById(R.id.vGlow)

        btnToggle.setOnClickListener {
            if (DpiVpnService.isRunning) stopBypass() else requestVpnPermission()
        }

        updateUi(DpiVpnService.isRunning)
    }

    override fun onResume() {
        super.onResume()
        val filter = IntentFilter("com.neotun.dpi.STATUS")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(statusReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(statusReceiver, filter)
        }
        updateUi(DpiVpnService.isRunning)
    }

    override fun onPause() {
        super.onPause()
        try { unregisterReceiver(statusReceiver) } catch (_: Exception) {}
    }

    private fun requestVpnPermission() {
        val intent = VpnService.prepare(this)
        if (intent != null) startActivityForResult(intent, VPN_REQUEST_CODE)
        else startBypass()
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE && resultCode == Activity.RESULT_OK) startBypass()
    }

    private fun startBypass() {
        val i = Intent(this, DpiVpnService::class.java).setAction(DpiVpnService.ACTION_START)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(i)
        else startService(i)
    }

    private fun stopBypass() {
        startService(Intent(this, DpiVpnService::class.java).setAction(DpiVpnService.ACTION_STOP))
    }

    private fun updateUi(running: Boolean) {
        if (running) {
            btnToggle.setBackgroundResource(R.drawable.bg_button_active)
            vGlow.setBackgroundResource(R.drawable.bg_glow_active)
            animateAlpha(ivShield, ivShield.alpha, 1.0f)
            tvStatus.text = "Подключено"
            animateTextColor(tvStatus, tvStatus.currentTextColor, 0xFF00D26A.toInt())
            val pulse = AnimationUtils.loadAnimation(this, R.anim.anim_pulse)
            btnToggle.startAnimation(pulse)
        } else {
            btnToggle.setBackgroundResource(R.drawable.bg_button_idle)
            vGlow.setBackgroundResource(R.drawable.bg_glow)
            animateAlpha(ivShield, ivShield.alpha, 0.5f)
            tvStatus.text = "Нажмите для подключения"
            animateTextColor(tvStatus, tvStatus.currentTextColor, 0xFF2E2E50.toInt())
            btnToggle.clearAnimation()
        }
    }

    private fun animateAlpha(view: ImageView, from: Float, to: Float) {
        ValueAnimator.ofFloat(from, to).apply {
            duration = 400
            addUpdateListener { view.alpha = it.animatedValue as Float }
            start()
        }
    }

    private fun animateTextColor(view: TextView, from: Int, to: Int) {
        ValueAnimator.ofObject(ArgbEvaluator(), from, to).apply {
            duration = 400
            addUpdateListener { view.setTextColor(it.animatedValue as Int) }
            start()
        }
    }
}
