package com.neotun.android.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.neotun.android.models.*
import com.neotun.android.config.UriParser

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddProfileScreen(
    onSaveProfile: (VpnProfile) -> Unit,
    onBackClick: () -> Unit
) {
    var name by remember { mutableStateOf("") }
    var server by remember { mutableStateOf("") }
    var port by remember { mutableStateOf("443") }
    var uriText by remember { mutableStateOf("") }
    var showUriImport by remember { mutableStateOf(false) }
    var importStatus by remember { mutableStateOf("") }
    
    val uriParser = remember { UriParser() }
    
    Column(
        modifier = Modifier.fillMaxSize()
    ) {
        TopAppBar(
            title = { Text("Add Profile") },
            navigationIcon = {
                IconButton(onClick = onBackClick) {
                    Icon(Icons.Default.ArrowBack, contentDescription = "Back")
                }
            },
            actions = {
                IconButton(onClick = { showUriImport = !showUriImport }) {
                    Icon(Icons.Default.Link, contentDescription = "Import from URI")
                }
            }
        )
        
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            if (showUriImport) {
                Card(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Text(
                            text = "Import from URI",
                            style = MaterialTheme.typography.titleMedium
                        )
                        
                        OutlinedTextField(
                            value = uriText,
                            onValueChange = { uriText = it },
                            label = { Text("Paste URI (vmess://, vless://, trojan://, ss://)") },
                            modifier = Modifier.fillMaxWidth(),
                            minLines = 3
                        )
                        
                        if (importStatus.isNotEmpty()) {
                            Text(
                                text = importStatus,
                                color = if (importStatus.startsWith("Error")) 
                                    MaterialTheme.colorScheme.error 
                                else MaterialTheme.colorScheme.primary,
                                style = MaterialTheme.typography.bodySmall
                            )
                        }
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            Button(
                                onClick = {
                                    try {
                                        if (uriText.isBlank()) {
                                            importStatus = "Error: Please enter a URI"
                                            return@Button
                                        }
                                        
                                        val profile = uriParser.parseUri(uriText.trim())
                                        if (profile != null) {
                                            name = profile.name
                                            server = profile.server
                                            port = profile.port.toString()
                                            importStatus = "Successfully imported profile"
                                        } else {
                                            importStatus = "Error: Invalid URI format or unsupported protocol"
                                        }
                                    } catch (e: Exception) {
                                        importStatus = "Error: ${e.message ?: "Unknown error occurred"}"
                                        android.util.Log.e("AddProfileScreen", "Import error", e)
                                    }
                                },
                                enabled = uriText.isNotBlank(),
                                modifier = Modifier.weight(1f)
                            ) {
                                Text("Import")
                            }
                            
                            OutlinedButton(
                                onClick = {
                                    uriText = ""
                                    importStatus = ""
                                },
                                modifier = Modifier.weight(1f)
                            ) {
                                Text("Clear")
                            }
                        }
                    }
                }
            }
            
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
                    try {
                        if (name.isBlank() || server.isBlank()) {
                            return@Button
                        }
                        
                        val profile = VpnProfile(
                            name = name.trim(),
                            protocol = VpnProtocol.VMESS,
                            server = server.trim(),
                            port = port.toIntOrNull() ?: 443,
                            credentials = VpnCredentials.VMess(userId = "test-uuid")
                        )
                        onSaveProfile(profile)
                    } catch (e: Exception) {
                        android.util.Log.e("AddProfileScreen", "Failed to save profile", e)
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                enabled = name.isNotBlank() && server.isNotBlank()
            ) {
                Text("Save Profile")
            }
        }
    }
}