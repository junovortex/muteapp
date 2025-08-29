# MuteApp - Local Testing Guide

## App Overview
MuteApp is an Android application that provides:
- Google Sign-In authentication with Firebase
- A floating button overlay service for muting/unmuting audio
- Offline support with cached user data
- System overlay permissions for floating UI elements

## Prerequisites

### 1. Install Android Studio
- Download and install [Android Studio](https://developer.android.com/studio)
- During installation, make sure to install:
  - Android SDK
  - Android SDK Platform-Tools
  - Android Virtual Device (AVD)

### 2. Install Java Development Kit (JDK)
- The app requires JDK 8 or higher
- Android Studio usually includes this, but you can verify by running:
  ```bash
  java -version
  ```

### 3. Set up Android SDK
- Open Android Studio
- Go to Tools → SDK Manager
- Install Android SDK API Level 34 (compileSdk)
- Install Android SDK API Level 21 (minSdk) for backward compatibility

## Setup Instructions

### Step 1: Clone and Open Project
1. The project is already cloned in your current directory
2. Open Android Studio
3. Click "Open an existing project"
4. Navigate to `/Users/vinoth/muteapp/muteapp`
5. Click "OK"

### Step 2: Sync Project
1. Android Studio will automatically start syncing
2. If prompted, click "Sync Now" in the notification bar
3. Wait for the sync to complete (this may take a few minutes)

### Step 3: Configure Firebase (Important!)
The app uses Firebase for Google Sign-In. You need to:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Add an Android app with package name: `com.muteapp.muteapp`
4. Download the `google-services.json` file
5. Replace the existing `app/google-services.json` with your downloaded file
6. Enable Google Sign-In in Firebase Authentication

### Step 4: Set up Android Device/Emulator

#### Option A: Physical Android Device
1. Enable Developer Options on your device:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
2. Enable USB Debugging:
   - Go to Settings → Developer Options
   - Turn on "USB Debugging"
3. Connect device via USB
4. Allow USB debugging when prompted

#### Option B: Android Emulator
1. In Android Studio, go to Tools → AVD Manager
2. Click "Create Virtual Device"
3. Choose a device (e.g., Pixel 4)
4. Select API Level 34 (Android 14) or higher
5. Click "Finish" and start the emulator

## Testing the App

### Step 1: Fix Gradle Wrapper (If Needed)
The gradle wrapper jar file might be missing. If you get an error like "Could not find or load main class org.gradle.wrapper.GradleWrapperMain", run:

```bash
# Navigate to project directory
cd /Users/vinoth/muteapp/muteapp

# Download and set up gradle wrapper
gradle wrapper --gradle-version 7.5
```

If you don't have gradle installed globally, you can:
1. Open the project in Android Studio first
2. Android Studio will automatically fix the gradle wrapper
3. Or download gradle wrapper jar manually from the project's GitHub repository

### Step 2: Build the Project
```bash
# Clean and build the project
./gradlew clean build
```

### Step 2: Install and Run
#### From Android Studio:
1. Click the "Run" button (green triangle) or press Ctrl+R
2. Select your device/emulator
3. Wait for installation and launch

#### From Command Line:
```bash
# Install debug APK
./gradlew installDebug

# Or build and install in one command
./gradlew assembleDebug
adb install app/build/outputs/apk/debug/app-debug.apk
```

## Testing Features

### 1. Google Sign-In
- Launch the app
- Tap "Sign In with Google"
- Complete the Google authentication flow
- Verify user information is displayed

### 2. Floating Button Service
- After signing in, tap "Start Floating Button"
- Grant overlay permission when prompted
- The floating button should appear on screen
- Test mute/unmute functionality

### 3. Offline Support
- Sign in with Google
- Close the app
- Turn off internet/WiFi
- Reopen the app
- Verify cached user data is displayed

## Troubleshooting

### Common Issues:

1. **Build Errors:**
   ```bash
   # Clean and rebuild
   ./gradlew clean
   ./gradlew build
   ```

2. **Google Sign-In Fails:**
   - Verify `google-services.json` is properly configured
   - Check Firebase project settings
   - Ensure SHA-1 fingerprint is added to Firebase

3. **Overlay Permission Issues:**
   - Manually grant overlay permission in device settings
   - Go to Settings → Apps → MuteApp → Display over other apps

4. **Gradle Sync Issues:**
   - Check internet connection
   - Try File → Invalidate Caches and Restart in Android Studio

### Debug Commands:
```bash
# View connected devices
adb devices

# View app logs
adb logcat | grep MuteApp

# Uninstall app
adb uninstall com.muteapp.muteapp

# Check app permissions
adb shell dumpsys package com.muteapp.muteapp
```

## App Permissions Required
- `SYSTEM_ALERT_WINDOW` - For floating overlay
- `MODIFY_AUDIO_SETTINGS` - For mute/unmute functionality
- `INTERNET` - For Google Sign-In
- `ACCESS_NETWORK_STATE` - For network status
- `FOREGROUND_SERVICE` - For persistent floating button

## Next Steps
Once the app is running successfully:
1. Test all authentication flows
2. Verify floating button functionality
3. Test offline capabilities
4. Check audio mute/unmute features
5. Test app behavior across different Android versions
