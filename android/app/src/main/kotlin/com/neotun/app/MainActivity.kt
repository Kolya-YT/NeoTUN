package com.neotun.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

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
                "isRunning" -> {
                    // Проверяем запущен ли VPN сервис
                    val isRunning = isServiceRunning(VpnService::class.java) || 
                                   isServiceRunning(TunVpnService::class.java)
                    result.success(isRunning)
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
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        installApk(filePath)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing filePath", null)
                    }
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

    private fun installApk(filePath: String) {
        val file = File(filePath)
        if (!file.exists()) {
            return
        }

        val intent = Intent(Intent.ACTION_VIEW)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val uri = FileProvider.getUriForFile(
                this,
                "${applicationContext.packageName}.fileprovider",
                file
            )
            intent.setDataAndType(uri, "application/vnd.android.package-archive")
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        } else {
            intent.setDataAndType(Uri.fromFile(file), "application/vnd.android.package-archive")
        }
        
        startActivity(intent)
    }

    private fun isServiceRunning(serviceClass: Class<*>): Boolean {
        val manager = getSystemService(ACTIVITY_SERVICE) as android.app.ActivityManager
        @Suppress("DEPRECATION")
        for (service in manager.getRunningServices(Integer.MAX_VALUE)) {
            if (serviceClass.name == service.service.className) {
                return true
            }
        }
        return false
    }

    companion object {
        private const val VPN_REQUEST_CODE = 100
    }
}
