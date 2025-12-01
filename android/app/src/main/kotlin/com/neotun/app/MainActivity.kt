package com.neotun.app

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.neotun.app/vpn"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startCore" -> {
                    val corePath = call.argument<String>("corePath")
                    val configPath = call.argument<String>("configPath")
                    val args = call.argument<List<String>>("args")
                    
                    if (corePath != null && configPath != null) {
                        startVpnService(corePath, configPath, args ?: emptyList())
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing corePath or configPath", null)
                    }
                }
                "stopCore" -> {
                    stopVpnService()
                    result.success(true)
                }
                "startTun" -> {
                    val coreType = call.argument<String>("coreType")
                    val configPath = call.argument<String>("configPath")
                    
                    if (coreType != null && configPath != null) {
                        startTunVpnService(coreType, configPath)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing coreType or configPath", null)
                    }
                }
                "stopTun" -> {
                    stopTunVpnService()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startVpnService(corePath: String, configPath: String, args: List<String>) {
        val intent = Intent(this, VpnService::class.java).apply {
            action = VpnService.ACTION_START
            putExtra(VpnService.EXTRA_CORE_PATH, corePath)
            putExtra(VpnService.EXTRA_CONFIG_PATH, configPath)
            putExtra(VpnService.EXTRA_ARGS, args.toTypedArray())
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopVpnService() {
        val intent = Intent(this, VpnService::class.java).apply {
            action = VpnService.ACTION_STOP
        }
        startService(intent)
    }

    private fun startTunVpnService(coreType: String, configPath: String) {
        // Запрашиваем разрешение VPN
        val vpnIntent = android.net.VpnService.prepare(this)
        if (vpnIntent != null) {
            startActivityForResult(vpnIntent, VPN_REQUEST_CODE)
            // Сохраняем параметры для запуска после получения разрешения
            pendingTunStart = Pair(coreType, configPath)
        } else {
            // Разрешение уже есть
            val intent = Intent(this, TunVpnService::class.java).apply {
                action = TunVpnService.ACTION_START
                putExtra(TunVpnService.EXTRA_CORE_TYPE, coreType)
                putExtra(TunVpnService.EXTRA_CONFIG_PATH, configPath)
            }
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        }
    }

    private fun stopTunVpnService() {
        val intent = Intent(this, TunVpnService::class.java).apply {
            action = TunVpnService.ACTION_STOP
        }
        startService(intent)
    }

    private var pendingTunStart: Pair<String, String>? = null

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == VPN_REQUEST_CODE && resultCode == RESULT_OK) {
            pendingTunStart?.let { (coreType, configPath) ->
                startTunVpnService(coreType, configPath)
                pendingTunStart = null
            }
        }
    }

    companion object {
        private const val VPN_REQUEST_CODE = 100
    }
}
