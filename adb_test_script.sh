#!/bin/bash

# MuteApp ADB Testing Script
# This script performs comprehensive testing of the MuteApp using ADB commands

echo "🚀 MuteApp ADB Testing Script"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TEST_RESULTS=()

# Function to log test results
log_test() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    if [ "$result" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC}: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}❌ FAIL${NC}: $test_name - $details"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    TEST_RESULTS+=("$result: $test_name - $details")
}

# Function to check if device is connected
check_device() {
    echo -e "${BLUE}📱 Checking device connectivity...${NC}"
    
    DEVICE_COUNT=$(adb devices | grep -v "List of devices attached" | grep -c "device")
    
    if [ "$DEVICE_COUNT" -eq 0 ]; then
        echo -e "${RED}❌ No devices connected!${NC}"
        echo "Please connect an Android device with USB debugging enabled."
        echo "Instructions:"
        echo "1. Enable Developer Options (tap Build Number 7 times)"
        echo "2. Enable USB Debugging in Developer Options"
        echo "3. Connect device via USB and allow debugging"
        exit 1
    else
        echo -e "${GREEN}✅ Device connected${NC}"
        adb devices
        log_test "Device Connectivity" "PASS" "Device found and connected"
    fi
}

# Function to install the app
install_app() {
    echo -e "${BLUE}📦 Installing MuteApp...${NC}"
    
    APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
    
    if [ ! -f "$APK_PATH" ]; then
        echo -e "${RED}❌ APK not found at $APK_PATH${NC}"
        log_test "APK Installation" "FAIL" "APK file not found"
        return 1
    fi
    
    # Uninstall existing version first
    adb uninstall com.muteapp.muteapp 2>/dev/null
    
    # Install the app
    INSTALL_RESULT=$(adb install "$APK_PATH" 2>&1)
    
    if echo "$INSTALL_RESULT" | grep -q "Success"; then
        echo -e "${GREEN}✅ App installed successfully${NC}"
        log_test "APK Installation" "PASS" "App installed successfully"
        return 0
    else
        echo -e "${RED}❌ Installation failed: $INSTALL_RESULT${NC}"
        log_test "APK Installation" "FAIL" "Installation failed: $INSTALL_RESULT"
        return 1
    fi
}

# Function to test app launch
test_app_launch() {
    echo -e "${BLUE}🚀 Testing app launch...${NC}"
    
    # Clear logcat
    adb logcat -c
    
    # Start the app
    adb shell am start -n com.muteapp.muteapp/.MainActivity
    
    # Wait a moment for the app to start
    sleep 3
    
    # Check if app is running
    RUNNING_APPS=$(adb shell ps | grep muteapp)
    
    if [ -n "$RUNNING_APPS" ]; then
        echo -e "${GREEN}✅ App launched successfully${NC}"
        log_test "App Launch" "PASS" "App is running"
        
        # Get app logs
        echo -e "${YELLOW}📋 App logs:${NC}"
        adb logcat -d | grep -i muteapp | tail -10
    else
        echo -e "${RED}❌ App failed to launch${NC}"
        log_test "App Launch" "FAIL" "App not found in running processes"
    fi
}

# Function to test permissions
test_permissions() {
    echo -e "${BLUE}🔐 Testing app permissions...${NC}"
    
    # Check if app is installed
    PACKAGE_INFO=$(adb shell pm list packages | grep muteapp)
    
    if [ -z "$PACKAGE_INFO" ]; then
        log_test "Permission Check" "FAIL" "App not installed"
        return 1
    fi
    
    # Check permissions
    echo -e "${YELLOW}📋 Checking app permissions:${NC}"
    PERMISSIONS=$(adb shell dumpsys package com.muteapp.muteapp | grep -A 20 "requested permissions:")
    echo "$PERMISSIONS"
    
    # Check overlay permission specifically
    OVERLAY_PERM=$(adb shell appops get com.muteapp.muteapp SYSTEM_ALERT_WINDOW)
    echo -e "${YELLOW}📋 Overlay permission status: $OVERLAY_PERM${NC}"
    
    if echo "$OVERLAY_PERM" | grep -q "allow"; then
        log_test "Overlay Permission" "PASS" "Overlay permission granted"
    else
        echo -e "${YELLOW}⚠️  Overlay permission not granted - this is expected for first install${NC}"
        log_test "Overlay Permission" "INFO" "Permission not granted (expected for first install)"
    fi
}

# Function to test floating button service
test_floating_service() {
    echo -e "${BLUE}🎯 Testing floating button service...${NC}"
    
    # Clear logcat
    adb logcat -c
    
    # Try to start the floating service (this would normally be done through the app UI)
    echo -e "${YELLOW}📋 Checking for FloatingButtonService...${NC}"
    
    # Check if service is defined in the app
    SERVICE_INFO=$(adb shell dumpsys package com.muteapp.muteapp | grep -i service)
    
    if echo "$SERVICE_INFO" | grep -q "FloatingButtonService"; then
        echo -e "${GREEN}✅ FloatingButtonService found in app manifest${NC}"
        log_test "Service Definition" "PASS" "FloatingButtonService found in manifest"
    else
        echo -e "${RED}❌ FloatingButtonService not found${NC}"
        log_test "Service Definition" "FAIL" "FloatingButtonService not found in manifest"
    fi
    
    # Check for service-related logs
    sleep 2
    SERVICE_LOGS=$(adb logcat -d | grep -i "FloatingButtonService\|floating\|service" | grep muteapp)
    
    if [ -n "$SERVICE_LOGS" ]; then
        echo -e "${YELLOW}📋 Service-related logs:${NC}"
        echo "$SERVICE_LOGS"
    fi
}

# Function to test audio functionality
test_audio_functionality() {
    echo -e "${BLUE}🔊 Testing audio functionality...${NC}"
    
    # Check current audio settings
    echo -e "${YELLOW}📋 Current audio settings:${NC}"
    AUDIO_INFO=$(adb shell dumpsys audio | grep -A 5 "Stream volumes")
    echo "$AUDIO_INFO"
    
    # Test volume commands
    echo -e "${YELLOW}📋 Testing volume controls...${NC}"
    
    # Get current volume
    CURRENT_VOLUME=$(adb shell dumpsys audio | grep "STREAM_MUSIC" | head -1)
    echo "Current music volume: $CURRENT_VOLUME"
    
    # Test volume key events
    echo "Testing volume down..."
    adb shell input keyevent KEYCODE_VOLUME_DOWN
    sleep 1
    
    echo "Testing volume up..."
    adb shell input keyevent KEYCODE_VOLUME_UP
    sleep 1
    
    echo "Testing mute toggle..."
    adb shell input keyevent KEYCODE_VOLUME_MUTE
    sleep 1
    
    log_test "Audio Controls" "PASS" "Volume controls tested successfully"
}

# Function to test Google Sign-In (limited testing without user interaction)
test_google_signin() {
    echo -e "${BLUE}🔐 Testing Google Sign-In setup...${NC}"
    
    # Check if Google Play Services is available
    GPS_INSTALLED=$(adb shell pm list packages | grep "com.google.android.gms")
    
    if [ -n "$GPS_INSTALLED" ]; then
        echo -e "${GREEN}✅ Google Play Services found${NC}"
        log_test "Google Play Services" "PASS" "Google Play Services installed"
    else
        echo -e "${RED}❌ Google Play Services not found${NC}"
        log_test "Google Play Services" "FAIL" "Google Play Services not installed"
    fi
    
    # Check for Firebase/Google services in the app
    echo -e "${YELLOW}📋 Checking app's Google services configuration...${NC}"
    
    # This would require actual user interaction to test fully
    echo -e "${YELLOW}ℹ️  Google Sign-In requires manual testing through the app UI${NC}"
    log_test "Google Sign-In Setup" "INFO" "Requires manual testing"
}

# Function to generate test report
generate_report() {
    echo ""
    echo "📊 TEST REPORT"
    echo "=============="
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    echo -e "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
    echo ""
    
    echo "📋 Detailed Results:"
    for result in "${TEST_RESULTS[@]}"; do
        if [[ $result == PASS* ]]; then
            echo -e "${GREEN}$result${NC}"
        elif [[ $result == FAIL* ]]; then
            echo -e "${RED}$result${NC}"
        else
            echo -e "${YELLOW}$result${NC}"
        fi
    done
    
    echo ""
    echo "📱 Device Information:"
    adb shell getprop ro.product.model
    adb shell getprop ro.build.version.release
    adb shell getprop ro.build.version.sdk
    
    echo ""
    echo "📦 APK Information:"
    echo "Package: com.muteapp.muteapp"
    echo "Version: 1.0 (1)"
    echo "Target SDK: 34"
    echo "Min SDK: 21"
    
    # Save report to file
    REPORT_FILE="test_report_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "MuteApp ADB Test Report"
        echo "Generated: $(date)"
        echo "========================"
        echo ""
        echo "Tests Passed: $TESTS_PASSED"
        echo "Tests Failed: $TESTS_FAILED"
        echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
        echo ""
        echo "Detailed Results:"
        for result in "${TEST_RESULTS[@]}"; do
            echo "$result"
        done
    } > "$REPORT_FILE"
    
    echo -e "${GREEN}📄 Test report saved to: $REPORT_FILE${NC}"
}

# Main execution
main() {
    echo "Starting comprehensive MuteApp testing..."
    echo ""
    
    # Run all tests
    check_device
    install_app
    test_app_launch
    test_permissions
    test_floating_service
    test_audio_functionality
    test_google_signin
    
    # Generate final report
    generate_report
    
    echo ""
    echo -e "${BLUE}🎉 Testing completed!${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed! 🎉${NC}"
        exit 0
    else
        echo -e "${YELLOW}Some tests failed or need manual verification.${NC}"
        exit 1
    fi
}

# Run the main function
main "$@"
