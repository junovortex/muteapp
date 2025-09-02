# ADB Installation Guide for macOS

Android Debug Bridge (ADB) is a command-line tool that allows you to communicate with Android devices. Here are multiple methods to install ADB on macOS.

## Method 1: Install via Homebrew (Recommended - Easiest)

### Prerequisites
- Homebrew must be installed on your Mac

### Steps
1. **Install Homebrew** (if not already installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. **Install ADB using Homebrew**:
   ```bash
   brew install android-platform-tools
   ```

3. **Verify installation**:
   ```bash
   adb --version
   ```

## Method 2: Install via Android Studio (Full SDK)

### Steps
1. **Download Android Studio** from https://developer.android.com/studio
2. **Install Android Studio** by dragging it to Applications folder
3. **Open Android Studio** and complete the setup wizard
4. **Install SDK Platform Tools**:
   - Go to `Android Studio > Preferences > Appearance & Behavior > System Settings > Android SDK`
   - Click on "SDK Tools" tab
   - Check "Android SDK Platform-Tools"
   - Click "Apply" and "OK"

5. **Add ADB to PATH**:
   ```bash
   echo 'export PATH=$PATH:~/Library/Android/sdk/platform-tools' >> ~/.zshrc
   source ~/.zshrc
   ```

6. **Verify installation**:
   ```bash
   adb --version
   ```

## Method 3: Manual Installation (Standalone)

### Steps
1. **Download Platform Tools** from https://developer.android.com/studio/releases/platform-tools
2. **Extract the downloaded file** to a folder (e.g., `~/android-sdk/platform-tools`)
3. **Add to PATH**:
   ```bash
   echo 'export PATH=$PATH:~/android-sdk/platform-tools' >> ~/.zshrc
   source ~/.zshrc
   ```
4. **Verify installation**:
   ```bash
   adb --version
   ```

## Post-Installation Setup

### Enable Developer Options on Android Device
1. Go to `Settings > About Phone`
2. Tap "Build Number" 7 times
3. Go back to `Settings > Developer Options`
4. Enable "USB Debugging"

### Test ADB Connection
1. **Connect your Android device** via USB
2. **Check if device is detected**:
   ```bash
   adb devices
   ```
3. **If prompted on device**, allow USB debugging

## Common ADB Commands

```bash
# List connected devices
adb devices

# Install an APK
adb install app.apk

# Uninstall an app
adb uninstall com.package.name

# Access device shell
adb shell

# Copy files to device
adb push local_file /sdcard/

# Copy files from device
adb pull /sdcard/file local_destination

# View device logs
adb logcat

# Restart ADB server
adb kill-server
adb start-server
```

## Troubleshooting

### ADB not found
- Make sure ADB is in your PATH
- Restart terminal after adding to PATH
- Use `which adb` to verify location

### Device not detected
- Enable USB debugging on device
- Try different USB cable
- Check if device drivers are installed
- Run `adb kill-server && adb start-server`

### Permission denied
- On some systems, you might need to run with sudo
- Check USB cable connection
- Ensure device is unlocked when connecting

## For Your Android Project

Since you have an Android project in this directory, you can use ADB to:
- Install your app: `adb install app/build/outputs/apk/debug/app-debug.apk`
- View logs: `adb logcat | grep MuteApp`
- Debug your floating button service
- Test on real devices

Choose Method 1 (Homebrew) for the quickest installation, or Method 2 if you plan to do extensive Android development.
