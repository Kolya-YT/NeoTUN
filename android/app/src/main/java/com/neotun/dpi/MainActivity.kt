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
import android.widget.CheckBox
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.Spinner
import android.widget.ArrayAdapter
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private val VPN_REQUEST_CODE = 100

    private lateinit var btnToggle: FrameLayout
    private lateinit var ivShield: ImageView
    private lateinit var tvStatus: TextView
    private lateinit var tvMode: TextView
    private lateinit var vGlow: View
    private lateinit var spProfile: Spinner
    private lateinit var cbHttpSplit: CheckBox
    private lateinit var cbTlsSplit: CheckBox
    private lateinit var cbDisorder: CheckBox
    private lateinit var cbOob: CheckBox

    private val prefs by lazy { getSharedPreferences("neotun_prefs", Context.MODE_PRIVATE) }

    private data class BypassProfile(
        val title: String,
        val splitPos: Int,
        val disorder: Int,
        val tlsSplit: Int,
        val oob: Int,
        val httpSplit: Int
    )

    private val profiles = listOf(
        BypassProfile("Сбалансированный", 0, 0, 1, 0, 1),
        BypassProfile("Агрессивный", 0, 1, 1, 1, 1),
        BypassProfile("Совместимый", 0, 0, 1, 0, 0)
    )

    private val statusReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val running = intent.getBooleanExtra("running", false)
            val error   = intent.getStringExtra("error") ?: ""
            if (error.isNotEmpty()) {
                Toast.makeText(this@MainActivity, "Ошибка: $error", Toast.LENGTH_LONG).show()
            }
            updateUi(running)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        btnToggle = findViewById(R.id.btnToggle)
        ivShield  = findViewById(R.id.ivShield)
        tvStatus  = findViewById(R.id.tvStatus)
        tvMode    = findViewById(R.id.tvMode)
        vGlow     = findViewById(R.id.vGlow)
        spProfile = findViewById(R.id.spProfile)
        cbHttpSplit = findViewById(R.id.cbHttpSplit)
        cbTlsSplit = findViewById(R.id.cbTlsSplit)
        cbDisorder = findViewById(R.id.cbDisorder)
        cbOob = findViewById(R.id.cbOob)

        val adapter = ArrayAdapter(this, android.R.layout.simple_spinner_item, profiles.map { it.title })
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        spProfile.adapter = adapter
        restoreSettings()

        spProfile.setSelection(prefs.getInt("profile_idx", 0), false)
        spProfile.onItemSelectedListener = object : android.widget.AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: android.widget.AdapterView<*>?, view: View?, position: Int, id: Long) {
                applyProfile(position)
            }
            override fun onNothingSelected(parent: android.widget.AdapterView<*>?) = Unit
        }

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
        // Show last error if any
        if (DpiVpnService.lastError.isNotEmpty()) {
            Toast.makeText(this, "Последняя ошибка: ${DpiVpnService.lastError}", Toast.LENGTH_LONG).show()
        }
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
        else if (requestCode == VPN_REQUEST_CODE) {
            Toast.makeText(this, "VPN разрешение отклонено", Toast.LENGTH_SHORT).show()
        }
    }

    private fun startBypass() {
        val i = Intent(this, DpiVpnService::class.java)
            .setAction(DpiVpnService.ACTION_START)
            .putExtra(DpiVpnService.EXTRA_SPLIT_POS, 0)
            .putExtra(DpiVpnService.EXTRA_DISORDER, if (cbDisorder.isChecked) 1 else 0)
            .putExtra(DpiVpnService.EXTRA_TLSREC_SPLIT, if (cbTlsSplit.isChecked) 1 else 0)
            .putExtra(DpiVpnService.EXTRA_OOB, if (cbOob.isChecked) 1 else 0)
            .putExtra(DpiVpnService.EXTRA_HTTP_SPLIT, if (cbHttpSplit.isChecked) 1 else 0)
        saveSettings()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(i)
        else startService(i)
    }

    private fun stopBypass() {
        startService(Intent(this, DpiVpnService::class.java).setAction(DpiVpnService.ACTION_STOP))
    }

    private fun updateUi(running: Boolean) {
        tvMode.text = buildModeLabel()
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
            tvStatus.text = if (DpiVpnService.lastError.isEmpty()) "Нажмите для подключения"
                            else "Ошибка — нажмите для повтора"
            animateTextColor(tvStatus, tvStatus.currentTextColor, 0xFF2E2E50.toInt())
            btnToggle.clearAnimation()
        }
    }

    private fun applyProfile(index: Int) {
        val p = profiles.getOrNull(index) ?: profiles.first()
        cbHttpSplit.isChecked = p.httpSplit == 1
        cbTlsSplit.isChecked = p.tlsSplit == 1
        cbDisorder.isChecked = p.disorder == 1
        cbOob.isChecked = p.oob == 1
        tvMode.text = buildModeLabel()
        saveSettings()
    }

    private fun buildModeLabel(): String {
        val parts = mutableListOf<String>()
        if (cbTlsSplit.isChecked) parts += "TLS split"
        if (cbHttpSplit.isChecked) parts += "HTTP host split"
        if (cbDisorder.isChecked) parts += "Disorder"
        if (cbOob.isChecked) parts += "OOB"
        return if (parts.isEmpty()) "Базовый" else parts.joinToString(" + ")
    }

    private fun saveSettings() {
        prefs.edit()
            .putInt("profile_idx", spProfile.selectedItemPosition.coerceAtLeast(0))
            .putBoolean("http_split", cbHttpSplit.isChecked)
            .putBoolean("tls_split", cbTlsSplit.isChecked)
            .putBoolean("disorder", cbDisorder.isChecked)
            .putBoolean("oob", cbOob.isChecked)
            .apply()
    }

    private fun restoreSettings() {
        cbHttpSplit.isChecked = prefs.getBoolean("http_split", true)
        cbTlsSplit.isChecked = prefs.getBoolean("tls_split", true)
        cbDisorder.isChecked = prefs.getBoolean("disorder", false)
        cbOob.isChecked = prefs.getBoolean("oob", false)
        tvMode.text = buildModeLabel()
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
