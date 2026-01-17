package com.neotun.android.repository

import com.neotun.android.database.ProfileDao
import com.neotun.android.database.ProfileEntity
import com.neotun.android.models.VpnProfile
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class ProfileRepository(private val profileDao: ProfileDao) {
    
    fun getAllProfiles(): Flow<List<VpnProfile>> {
        return profileDao.getAllProfiles().map { entities ->
            entities.map { it.toVpnProfile() }
        }
    }
    
    suspend fun insertProfile(profile: VpnProfile) {
        profileDao.insertProfile(ProfileEntity.fromVpnProfile(profile))
    }
    
    suspend fun updateProfile(profile: VpnProfile) {
        profileDao.updateProfile(ProfileEntity.fromVpnProfile(profile))
    }
    
    suspend fun deleteProfile(profile: VpnProfile) {
        profileDao.deleteProfile(ProfileEntity.fromVpnProfile(profile))
    }
    
    suspend fun getProfileById(id: String): VpnProfile? {
        return profileDao.getProfileById(id)?.toVpnProfile()
    }
}