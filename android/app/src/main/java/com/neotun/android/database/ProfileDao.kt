package com.neotun.android.database

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface ProfileDao {
    
    @Query("SELECT * FROM profiles ORDER BY createdAt DESC")
    fun getAllProfiles(): Flow<List<ProfileEntity>>
    
    @Query("SELECT * FROM profiles WHERE id = :id")
    suspend fun getProfileById(id: String): ProfileEntity?
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertProfile(profile: ProfileEntity)
    
    @Update
    suspend fun updateProfile(profile: ProfileEntity)
    
    @Delete
    suspend fun deleteProfile(profile: ProfileEntity)
    
    @Query("DELETE FROM profiles")
    suspend fun deleteAllProfiles()
}