package com.neotun.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.neotun.android.models.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddProfileScreen(
    onSaveProfile: (VpnProfile) -> Unit,
    onBackClick: () -> Unit
) {
    var name by remember { mutableStateOf("") }
    var server by remember { mutableStateOf("") }
    var port by remember { mutableStateOf("443") }
    
    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        TopAppBar(
            title = { Text("Add Profile") },
            navigationIcon = {
                IconButton(onClick = onBackClick) {
                    Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                }
            }
        )
        
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            OutlinedTextField(
                value = name,
                onValueChange = { name = it },
                label = { Text("Profile Name") },
                modifier = Modifier.fillMaxWidth()
            )
            
            OutlinedTextField(
                value = server,
                onValueChange = { server = it },
                label = { Text("Server Address") },
                modifier = Modifier.fillMaxWidth()
            )
            
            OutlinedTextField(
                value = port,
                onValueChange = { port = it },
                label = { Text("Port") },
                modifier = Modifier.fillMaxWidth()
            )
            
            Button(
                onClick = {
                    val profile = VpnProfile(
                        name = name,
                        protocol = VpnProtocol.VMESS,
                        server = server,
                        port = port.toIntOrNull() ?: 443,
                        credentials = VpnCredentials.VMess(userId = "test-uuid")
                    )
                    onSaveProfile(profile)
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = name.isNotBlank() && server.isNotBlank()
            ) {
                Text("Save Profile")
            }
        }
    }
}