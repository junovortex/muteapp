# MuteApp Manual Testing Guide

## 🚀 Quick Start Testing

### Prerequisites
1. **ADB Installed**: ✅ Confirmed (version 1.0.41)
2. **APK Built**: ✅ Available at `app/build/outputs/apk/debug/app-debug.apk` (7.6MB)
3. **Android Device**: Connect with USB debugging enabled

### Automated Testing Script
```bash
# Run the comprehensive test script
./adb_test_script.sh
```

## 📱 Device Setup Instructions

### Step 1: Enable Developer Options
1. Go to **Settings > About Phone**
2. Tap **"Build Number"** 7 times until you see "You are now a developer!"
3. Go back to **Settings > Developer Options**
4. Enable **"USB Debugging"**

### Step 2: Connect Device
1. Connect your Android device via USB cable
2. When prompted on your device, tap **"Allow"** for USB debugging
3. Verify connection: `adb devices`

## 🧪 Manual Test Cases

### Test Case 1: App Installation and Launch
**Objective**: Verify the app installs and launches correctly

**Steps**:
1. Install the app: `adb install app/build/outputs/apk/debug/app-debug.apk`
2. Launch the app: `adb shell am start -n com.muteapp.muteapp/.MainActivity`
3. Verify app appears on device screen

**Expected Results**:
- App installs without errors
- App launches and displays main interface
- Google Sign-In button is visible

**ADB Commands**:
```bash
# Install app
adb install -r app/build/outputs/apk/debug/app-debug.apk

# Launch app
adb shell am start -n com.muteapp.muteapp/.MainActivity

# Check if app is running
adb shell ps | grep muteapp

# View app logs
adb logcat | grep MuteApp
```

### Test Case 2: Google Sign-In Authentication
**Objective**: Test Google authentication flow

**Prerequisites**: Device must have Google Play Services

**Steps**:
1. Launch the app
2. Tap "Sign In with Google"
3. Complete Google authentication in the popup
4. Verify user information is displayed
5. Test sign-out functionality

**Expected Results**:
- Google Sign-In dialog appears
- Authentication completes successfully
- User name and email are displayed
- Sign-out works correctly

**ADB Verification**:
```bash
# Check Google Play Services
adb shell pm list packages | grep "com.google.android.gms"

# Monitor authentication logs
adb logcat | grep -E "(Auth|Google|Firebase)"

# Check app's stored preferences
adb shell run-as com.muteapp.muteapp ls shared_prefs/
```

### Test Case 3: Floating Button Service
**Objective**: Test the floating button overlay functionality

**Steps**:
1. Sign in to the app
2. Tap "Start Floating Button"
3. Grant overlay permission when prompted
4. Verify floating button appears on screen
5. Test dragging the button around
6. Test mute/unmute functionality
7. Navigate to other apps and verify button persists

**Expected Results**:
- Permission dialog appears for overlay access
- Floating button appears after permission granted
- Button can be dragged around the screen
- Button persists across different apps
- Mute/unmute functionality works

**ADB Commands**:
```bash
# Check overlay permission
adb shell appops get com.muteapp.muteapp SYSTEM_ALERT_WINDOW

# Grant overlay permission (if needed)
adb shell appops set com.muteapp.muteapp SYSTEM_ALERT_WINDOW allow

# Check if service is running
adb shell dumpsys activity services | grep FloatingButtonService

# Monitor service logs
adb logcat | grep FloatingButtonService
```

### Test Case 4: Audio Controls
**Objective**: Test mute/unmute functionality

**Steps**:
1. Start floating button service
2. Play some audio on the device
3. Tap the floating button to mute
4. Verify audio is muted
5. Tap again to unmute
6. Verify audio is restored

**Expected Results**:
- Audio mutes when button is tapped
- Audio unmutes when button is tapped again
- Visual feedback shows mute state

**ADB Commands**:
```bash
# Check current audio settings
adb shell dumpsys audio | grep -A 5 "Stream volumes"

# Test volume controls
adb shell input keyevent KEYCODE_VOLUME_MUTE
adb shell input keyevent KEYCODE_VOLUME_DOWN
adb shell input keyevent KEYCODE_VOLUME_UP

# Monitor audio changes
adb shell dumpsys audio | grep "STREAM_MUSIC"
```

### Test Case 5: Offline Functionality
**Objective**: Test app behavior without internet connection

**Steps**:
1. Sign in with Google while connected to internet
2. Close the app
3. Disconnect from internet (turn off WiFi/mobile data)
4. Reopen the app
5. Verify user data is still displayed
6. Test floating button functionality offline

**Expected Results**:
- User remains "signed in" when offline
- Cached user name and email are displayed
- Floating button works without internet
- App doesn't crash when offline

**ADB Commands**:
```bash
# Disable WiFi
adb shell svc wifi disable

# Disable mobile data
adb shell svc data disable

# Check network state
adb shell dumpsys connectivity

# Re-enable connectivity
adb shell svc wifi enable
adb shell svc data enable
```

### Test Case 6: Permissions and Security
**Objective**: Verify all permissions work correctly

**Steps**:
1. Check all requested permissions
2. Test overlay permission specifically
3. Verify foreground service permission
4. Test permission revocation and re-granting

**Expected Results**:
- All permissions are properly requested
- App handles permission denials gracefully
- Overlay permission works correctly
- Foreground service runs properly

**ADB Commands**:
```bash
# List all app permissions
adb shell dumpsys package com.muteapp.muteapp | grep permission

# Check specific permissions
adb shell appops get com.muteapp.muteapp SYSTEM_ALERT_WINDOW
adb shell appops get com.muteapp.muteapp MODIFY_AUDIO_SETTINGS

# Revoke and grant permissions
adb shell appops set com.muteapp.muteapp SYSTEM_ALERT_WINDOW deny
adb shell appops set com.muteapp.muteapp SYSTEM_ALERT_WINDOW allow
```

## 🔍 Debugging and Troubleshooting

### Common Issues and Solutions

#### Issue 1: App Won't Install
**Symptoms**: Installation fails with error
**Solutions**:
```bash
# Uninstall existing version
adb uninstall com.muteapp.muteapp

# Clear app data
adb shell pm clear com.muteapp.muteapp

# Install with force flag
adb install -r -d app/build/outputs/apk/debug/app-debug.apk
```

#### Issue 2: Google Sign-In Not Working
**Symptoms**: Sign-in dialog doesn't appear or fails
**Checks**:
```bash
# Verify Google Play Services
adb shell pm list packages | grep gms

# Check internet connectivity
adb shell ping -c 3 google.com

# Check Firebase configuration
adb logcat | grep Firebase
```

#### Issue 3: Floating Button Not Appearing
**Symptoms**: Button doesn't show after permission granted
**Solutions**:
```bash
# Check overlay permission
adb shell appops get com.muteapp.muteapp SYSTEM_ALERT_WINDOW

# Force grant permission
adb shell appops set com.muteapp.muteapp SYSTEM_ALERT_WINDOW allow

# Restart the service
adb shell am force-stop com.muteapp.muteapp
adb shell am start -n com.muteapp.muteapp/.MainActivity
```

#### Issue 4: Audio Controls Not Working
**Symptoms**: Mute/unmute doesn't affect audio
**Checks**:
```bash
# Check audio permission
adb shell dumpsys package com.muteapp.muteapp | grep MODIFY_AUDIO_SETTINGS

# Test system audio controls
adb shell input keyevent KEYCODE_VOLUME_MUTE

# Check audio manager logs
adb logcat | grep AudioManager
```

## 📊 Test Results Template

### Test Execution Checklist
- [ ] **Device Connected**: ADB recognizes device
- [ ] **App Installation**: APK installs successfully
- [ ] **App Launch**: App starts without crashes
- [ ] **Google Sign-In**: Authentication works
- [ ] **Floating Button**: Overlay appears and functions
- [ ] **Audio Controls**: Mute/unmute works
- [ ] **Offline Mode**: App works without internet
- [ ] **Permissions**: All permissions granted and working
- [ ] **Cross-App**: Floating button persists across apps
- [ ] **Performance**: No memory leaks or crashes

### Device Information
- **Model**: _____________
- **Android Version**: _____________
- **API Level**: _____________
- **Google Play Services**: _____________

### Test Results
- **Tests Passed**: ___/10
- **Tests Failed**: ___/10
- **Critical Issues**: _____________
- **Minor Issues**: _____________

## 🚀 Quick Test Commands

### Essential ADB Commands for Testing
```bash
# Device and app status
adb devices
adb shell pm list packages | grep muteapp
adb shell ps | grep muteapp

# Install and launch
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.muteapp.muteapp/.MainActivity

# Permissions
adb shell appops get com.muteapp.muteapp SYSTEM_ALERT_WINDOW
adb shell appops set com.muteapp.muteapp SYSTEM_ALERT_WINDOW allow

# Logging
adb logcat -c  # Clear logs
adb logcat | grep MuteApp  # View app logs
adb logcat | grep -E "(FloatingButtonService|Audio|Permission)"

# Cleanup
adb shell am force-stop com.muteapp.muteapp
adb uninstall com.muteapp.muteapp
```

## 📱 Testing on Different Android Versions

### API Level Compatibility
- **Minimum SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Tested Versions**: _____________

### Version-Specific Tests
- **API 21-22**: Basic functionality
- **API 23+**: Runtime permissions
- **API 26+**: Foreground services
- **API 29+**: Scoped storage
- **API 30+**: Package visibility

---

**Note**: This guide provides comprehensive testing procedures for the MuteApp. The automated script (`./adb_test_script.sh`) will handle most of these tests automatically, but manual verification is recommended for user interface interactions.
