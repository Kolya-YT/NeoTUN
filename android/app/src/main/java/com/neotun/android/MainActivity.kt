package com.neotun.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import com.neotun.android.ui.screens.MainScreen
import com.neotun.android.ui.theme.NeoTUNTheme
import com.neotun.android.models.ConnectionState

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        setContent {
            NeoTUNTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    var connectionState by remember { mutableStateOf(ConnectionState.DISCONNECTED) }
                    
                    MainScreen(
                        connectionState = connectionState,
                        activeProfile = null,
                        onConnectClick = { 
                            connectionState = ConnectionState.CONNECTING
                            // TODO: Implement connection logic
                        },
                        onDisconnectClick = { 
                            connectionState = ConnectionState.DISCONNECTING
                            // TODO: Implement disconnection logic
                        },
                        onProfilesClick = { 
                            // TODO: Navigate to profiles screen
                        },
                        onSettingsClick = { 
                            // TODO: Navigate to settings screen
                        },
                        onLogsClick = { 
                            // TODO: Navigate to logs screen
                        }
                    )
                }
            }
        }
    }
}