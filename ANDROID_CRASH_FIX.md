# Android App Crash Fix

## 🚨 Problem
App crashes during profile import and won't start afterwards.

## ✅ Fixes Applied

### 1. Enhanced Error Handling
- Added comprehensive try-catch blocks in UriParser
- Safe Base64 decoding with validation
- Null/empty string checks before processing
- Proper logging for debugging crashes

### 2. Input Validation
- Validate URI format before parsing
- Check for required fields (server, port, userId)
- Sanitize input data (trim whitespace)
- Handle malformed JSON gracefully

### 3. Safe Profile Creation
- Validate profile data before saving
- Handle serialization errors
- Prevent database corruption from invalid data

## 🔧 Recovery Steps

### If App Won't Start:
1. **Clear App Data**:
   ```
   Settings > Apps > NeoTUN > Storage > Clear Data
   ```

2. **Or Uninstall/Reinstall**:
   - Uninstall the app completely
   - Install the new fixed version

### Testing Import:
1. Start with simple URIs first
2. Check error messages in import status
3. Don't save profiles with empty fields

## 🛡️ Prevention Measures

### Safe Import Practices:
- Always test URI in import preview first
- Don't import multiple profiles rapidly
- Check that server/port fields are populated
- Use the "Clear" button to reset if errors occur

### Error Indicators:
- Red error messages show what went wrong
- Green messages confirm successful import
- Empty fields will be highlighted

## 🔍 Debug Information

If crashes still occur, check Android logs:
```bash
adb logcat | grep -E "(UriParser|AddProfileScreen|NeoTUN)"
```

Look for error messages starting with:
- "Failed to parse URI"
- "Failed to save profile" 
- "Import error"

## 📱 New Build Available

The fixed version includes:
- ✅ Crash-proof URI parsing
- ✅ Input validation
- ✅ Better error messages
- ✅ Safe profile storage
- ✅ Recovery from import errors

Download the latest APK from GitHub Actions after the build completes.