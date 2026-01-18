package com.neotun.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.neotun.android.models.ConnectionState
import com.neotun.android.models.VpnProfile

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    connectionState: ConnectionState,
    activeProfile: VpnProfile?,
    onConnectClick: () -> Unit,
    onDisconnectClick: () -> Unit,
    onProfilesClick: () -> Unit,
    onSettingsClick: () -> Unit,
    onLogsClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Top App Bar
        TopAppBar(
            title = { Text("NeoTUN") },
            actions = {
                IconButton(onClick = onSettingsClick) {
                    Icon(Icons.Default.Settings, contentDescription = "Settings")
                }
                IconButton(onClick = onLogsClick) {
                    Icon(Icons.Default.List, contentDescription = "Logs")
                }
            }
        )
        
        Spacer(modifier = Modifier.height(32.dp))
        
        // Connection Status
        ConnectionStatusCard(
            connectionState = connectionState,
            activeProfile = activeProfile
        )
        
        Spacer(modifier = Modifier.height(48.dp))
        
        // Power Button
        PowerButton(
            connectionState = connectionState,
            onConnectClick = onConnectClick,
            onDisconnectClick = onDisconnectClick
        )
        
        Spacer(modifier = Modifier.height(48.dp))
        
        // Quick Actions
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceEvenly
        ) {
            QuickActionButton(
                icon = Icons.Default.List,
                label = "Profiles",
                onClick = onProfilesClick
            )
            
            QuickActionButton(
                icon = Icons.Default.Add,
                label = "Add Profile",
                onClick = { /* Navigate to add profile */ }
            )
        }
        
        Spacer(modifier = Modifier.weight(1f))
        
        // Connection Stats (if connected)
        if (connectionState == ConnectionState.CONNECTED) {
            ConnectionStatsCard()
        }
    }
}

@Composable
private fun ConnectionStatusCard(
    connectionState: ConnectionState,
    activeProfile: VpnProfile?
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = when (connectionState) {
                ConnectionState.CONNECTED -> Color(0xFF4CAF50).copy(alpha = 0.1f)
                ConnectionState.ERROR -> Color(0xFFF44336).copy(alpha = 0.1f)
                else -> MaterialTheme.colorScheme.surfaceVariant
            }
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = when (connectionState) {
                    ConnectionState.DISCONNECTED -> "Disconnected"
                    ConnectionState.CONNECTING -> "Connecting..."
                    ConnectionState.CONNECTED -> "Connected"
                    ConnectionState.DISCONNECTING -> "Disconnecting..."
                    ConnectionState.ERROR -> "Connection Error"
                },
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Bold,
                color = when (connectionState) {
                    ConnectionState.CONNECTED -> Color(0xFF4CAF50)
                    ConnectionState.ERROR -> Color(0xFFF44336)
                    else -> MaterialTheme.colorScheme.onSurface
                }
            )
            
            if (activeProfile != null) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = activeProfile.name,
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Text(
                    text = "${activeProfile.server}:${activeProfile.port}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun PowerButton(
    connectionState: ConnectionState,
    onConnectClick: () -> Unit,
    onDisconnectClick: () -> Unit
) {
    val isConnected = connectionState == ConnectionState.CONNECTED
    val isLoading = connectionState == ConnectionState.CONNECTING || 
                   connectionState == ConnectionState.DISCONNECTING
    
    FloatingActionButton(
        onClick = {
            if (isConnected) onDisconnectClick() else onConnectClick()
        },
        modifier = Modifier.size(80.dp),
        shape = CircleShape,
        containerColor = if (isConnected) Color(0xFFF44336) else Color(0xFF4CAF50)
    ) {
        if (isLoading) {
            CircularProgressIndicator(
                modifier = Modifier.size(32.dp),
                color = Color.White,
                strokeWidth = 3.dp
            )
        } else {
            Icon(
                imageVector = if (isConnected) Icons.Default.Stop else Icons.Default.PlayArrow,
                contentDescription = if (isConnected) "Disconnect" else "Connect",
                modifier = Modifier.size(32.dp),
                tint = Color.White
            )
        }
    }
}

@Composable
private fun QuickActionButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        FilledTonalIconButton(
            onClick = onClick,
            modifier = Modifier.size(56.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                modifier = Modifier.size(24.dp)
            )
        }
        
        Spacer(modifier = Modifier.height(8.dp))
        
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun ConnectionStatsCard() {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Connection Stats",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "(DEMO)",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFFFF9800),
                    fontWeight = FontWeight.Bold
                )
            }
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                StatItem(label = "Upload", value = "0 MB")
                StatItem(label = "Download", value = "0 MB")
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                StatItem(label = "Duration", value = "00:00:00")
                StatItem(label = "Status", value = "Simulation")
            }
        }
    }
}

@Composable
private fun StatItem(label: String, value: String) {
    Column {
        Text(
            text = value,
            style = MaterialTheme.typography.bodyLarge,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}