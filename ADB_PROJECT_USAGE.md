# Using ADB with MuteApp Project

Now that ADB is installed, here's how to use it specifically with your MuteApp Android project.

## Current ADB Installation Status
✅ **ADB Successfully Installed**
- Version: 1.0.41 (36.0.0-13206524)
- Location: `/opt/homebrew/bin/adb`
- ADB daemon is running on port 5037

## Setting Up Your Android Device

### 1. Enable Developer Options
1. Go to `Settings > About Phone`
2. Tap "Build Number" 7 times until you see "You are now a developer!"
3. Go back to `Settings > Developer Options`
4. Enable "USB Debugging"

### 2. Connect Your Device
1. Connect your Android device via USB cable
2. When prompted on your device, tap "Allow" for USB debugging
3. Check if device is detected: `adb devices`

## Building and Installing Your MuteApp

### 1. Build the APK
```bash
# Build debug APK
./gradlew assembleDebug

# Build release APK (if configured)
./gradlew assembleRelease
```

### 2. Install the App via ADB
```bash
# Install debug version
adb install app/build/outputs/apk/debug/app-debug.apk

# Install release version
adb install app/build/outputs/apk/release/app-release.apk

# Install and replace existing app
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

## Debugging Your MuteApp

### 1. View App Logs
```bash
# View all logs filtered by your app
adb logcat | grep MuteApp

# View logs with specific tag
adb logcat -s "FloatingButtonService"

# Clear logs and start fresh
adb logcat -c && adb logcat | grep MuteApp
```

### 2. Monitor Your Floating Button Service
```bash
# Monitor service-specific logs
adb logcat | grep -E "(FloatingButtonService|MuteApp)"

# View system logs related to services
adb logcat | grep -E "(ActivityManager|WindowManager)" | grep MuteApp
```

### 3. Check App Installation and Permissions
```bash
# List installed packages
adb shell pm list packages | grep muteapp

# Check app permissions
adb shell dumpsys package com.muteapp.muteapp | grep permission

# Check if app is running
adb shell ps | grep muteapp
```

## Testing Your App Features

### 1. Test Floating Button Service
```bash
# Start your app
adb shell am start -n com.muteapp.muteapp/.MainActivity

# Check if floating service is running
adb shell dumpsys activity services | grep FloatingButtonService

# Force stop the app
adb shell am force-stop com.muteapp.muteapp
```

### 2. Simulate Device Actions
```bash
# Simulate volume button press
adb shell input keyevent KEYCODE_VOLUME_DOWN
adb shell input keyevent KEYCODE_VOLUME_UP

# Simulate mute toggle
adb shell input keyevent KEYCODE_VOLUME_MUTE

# Check current volume levels
adb shell dumpsys audio | grep -A 5 "Stream volumes"
```

### 3. Test Permissions
```bash
# Grant overlay permission (if needed)
adb shell appops set com.muteapp.muteapp SYSTEM_ALERT_WINDOW allow

# Check overlay permission status
adb shell appops get com.muteapp.muteapp SYSTEM_ALERT_WINDOW
```

## File Management

### 1. Push Files to Device
```bash
# Push test files
adb push test_file.txt /sdcard/

# Push to app's private directory (requires root)
adb push config.json /data/data/com.muteapp.muteapp/files/
```

### 2. Pull Files from Device
```bash
# Pull app logs
adb pull /sdcard/Android/data/com.muteapp.muteapp/files/logs/ ./logs/

# Pull crash dumps
adb pull /data/tombstones/ ./crash_logs/
```

## Troubleshooting Common Issues

### Device Not Detected
```bash
# Restart ADB server
adb kill-server
adb start-server

# Check USB connection
adb devices -l
```

### App Installation Failed
```bash
# Uninstall existing version first
adb uninstall com.muteapp.muteapp

# Clear app data
adb shell pm clear com.muteapp.muteapp

# Install with specific flags
adb install -r -d app/build/outputs/apk/debug/app-debug.apk
```

### Floating Button Not Appearing
```bash
# Check overlay permission
adb shell appops get com.muteapp.muteapp SYSTEM_ALERT_WINDOW

# Grant overlay permission
adb shell appops set com.muteapp.muteapp SYSTEM_ALERT_WINDOW allow

# Check service status
adb shell dumpsys activity services | grep FloatingButtonService
```

## Quick Development Workflow

1. **Make code changes**
2. **Build and install**: `./gradlew assembleDebug && adb install -r app/build/outputs/apk/debug/app-debug.apk`
3. **Start app**: `adb shell am start -n com.muteapp.muteapp/.MainActivity`
4. **Monitor logs**: `adb logcat | grep MuteApp`
5. **Test functionality**
6. **Repeat**

## Useful ADB Commands for Your Project

```bash
# Complete development cycle
alias build-install="./gradlew assembleDebug && adb install -r app/build/outputs/apk/debug/app-debug.apk"
alias start-muteapp="adb shell am start -n com.muteapp.muteapp/.MainActivity"
alias logs-muteapp="adb logcat | grep -E '(MuteApp|FloatingButtonService)'"
alias stop-muteapp="adb shell am force-stop com.muteapp.muteapp"

# Use these aliases in your terminal for faster development
```

Your ADB installation is complete and ready for Android development with your MuteApp project!
