package com.neotun.dpi

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.VpnService
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private val VPN_REQUEST_CODE = 100

    private lateinit var btnToggle: Button
    private lateinit var tvStatus: TextView

    private val statusReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val running = intent.getBooleanExtra("running", false)
            updateUi(running)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        btnToggle = findViewById(R.id.btnToggle)
        tvStatus  = findViewById(R.id.tvStatus)

        btnToggle.setOnClickListener {
            if (DpiVpnService.isRunning) stopBypass()
            else requestVpnPermission()
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
        if (intent != null)
            startActivityForResult(intent, VPN_REQUEST_CODE)
        else
            startBypass()
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_REQUEST_CODE && resultCode == Activity.RESULT_OK)
            startBypass()
    }

    private fun startBypass() {
        val intent = Intent(this, DpiVpnService::class.java)
            .setAction(DpiVpnService.ACTION_START)
        startForegroundService(intent)
    }

    private fun stopBypass() {
        val intent = Intent(this, DpiVpnService::class.java)
            .setAction(DpiVpnService.ACTION_STOP)
        startService(intent)
    }

    private fun updateUi(running: Boolean) {
        if (running) {
            tvStatus.text = "● Работает"
            tvStatus.setTextColor(0xFF27AE60.toInt())
            btnToggle.text = "Остановить"
        } else {
            tvStatus.text = "● Остановлен"
            tvStatus.setTextColor(0xFFAAAAAA.toInt())
            btnToggle.text = "Запустить"
        }
    }
}
