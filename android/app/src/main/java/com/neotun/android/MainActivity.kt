package com.neotun.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.neotun.android.database.AppDatabase
import com.neotun.android.models.VpnProfile
import com.neotun.android.repository.ProfileRepository
import com.neotun.android.ui.screens.AddProfileScreen
import com.neotun.android.ui.screens.LogsScreen
import com.neotun.android.ui.screens.MainScreen
import com.neotun.android.ui.screens.ProfilesScreen
import com.neotun.android.ui.theme.NeoTUNTheme
import com.neotun.android.viewmodels.MainViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        val database = AppDatabase.getDatabase(this)
        val repository = ProfileRepository(database.profileDao())
        
        setContent {
            NeoTUNTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    val navController = rememberNavController()
                    val viewModel: MainViewModel = viewModel {
                        MainViewModel(repository)
                    }
                    
                    val connectionState by viewModel.connectionState.collectAsState()
                    val profiles by viewModel.profiles.collectAsState()
                    val activeProfile by viewModel.activeProfile.collectAsState()
                    val logs by viewModel.logs.collectAsState()
                    
                    NavHost(
                        navController = navController,
                        startDestination = "main"
                    ) {
                        composable("main") {
                            MainScreen(
                                connectionState = connectionState,
                                activeProfile = activeProfile,
                                onConnectClick = { viewModel.connect() },
                                onDisconnectClick = { viewModel.disconnect() },
                                onProfilesClick = { navController.navigate("profiles") },
                                onSettingsClick = { /* TODO: Navigate to settings */ },
                                onLogsClick = { navController.navigate("logs") }
                            )
                        }
                        
                        composable("profiles") {
                            ProfilesScreen(
                                profiles = profiles,
                                activeProfile = activeProfile,
                                onProfileSelect = { profile ->
                                    viewModel.selectProfile(profile)
                                    navController.popBackStack()
                                },
                                onProfileEdit = { /* TODO: Navigate to edit */ },
                                onProfileDelete = { profile ->
                                    viewModel.deleteProfile(profile)
                                },
                                onAddProfile = { navController.navigate("add_profile") },
                                onBackClick = { navController.popBackStack() }
                            )
                        }
                        
                        composable("add_profile") {
                            AddProfileScreen(
                                onSaveProfile = { profile: VpnProfile ->
                                    viewModel.addProfile(profile)
                                    navController.popBackStack()
                                },
                                onBackClick = { navController.popBackStack() }
                            )
                        }
                        
                        composable("logs") {
                            LogsScreen(
                                logs = logs,
                                onBackClick = { navController.popBackStack() },
                                onClearLogs = { viewModel.clearLogs() }
                            )
                        }
                    }
                }
            }
        }
    }
}