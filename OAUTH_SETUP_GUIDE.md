# OAuth Client ID Setup Guide

This guide will walk you through creating an OAuth client ID for your Android application and integrating it into your project.

## Prerequisites

- Google account
- Android project (already set up)
- Google Services JSON file (you already have this)

## Step 1: Access Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Sign in with your Google account
3. Select your existing project or create a new one
   - If creating new: Click "New Project" → Enter project name → Click "Create"

## Step 2: Enable Required APIs

1. In the Google Cloud Console, navigate to **APIs & Services** → **Library**
2. Search for and enable the following APIs:
   - **Google+ API** (if using Google Sign-In)
   - **Gmail API** (if accessing Gmail)
   - **Google Drive API** (if accessing Drive)
   - **YouTube Data API** (if accessing YouTube)
   - Enable any other APIs your app will use

## Step 3: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Choose **External** (unless you're part of a Google Workspace organization)
3. Fill in the required information:
   - **App name**: Your app name (e.g., "MuteApp")
   - **User support email**: Your email address
   - **App logo**: Upload your app icon (optional)
   - **App domain**: Your website domain (if applicable)
   - **Developer contact information**: Your email address
4. Click **Save and Continue**
5. **Scopes**: Add the scopes your app needs:
   - `../auth/userinfo.email` - for email access
   - `../auth/userinfo.profile` - for profile access
   - Add other scopes as needed
6. Click **Save and Continue**
7. **Test users**: Add test user emails (for testing phase)
8. Click **Save and Continue**

## Step 4: Create OAuth 2.0 Client ID

1. Go to **APIs & Services** → **Credentials**
2. Click **+ Create Credentials** → **OAuth client ID**
3. Select **Android** as the application type
4. Fill in the details:
   - **Name**: Give it a descriptive name (e.g., "MuteApp Android Client")
   - **Package name**: `com.muteapp.muteapp` (from your AndroidManifest.xml)
   - **SHA-1 certificate fingerprint**: You need to get this

### Getting SHA-1 Certificate Fingerprint

#### For Debug Certificate (Development):
```bash
# Navigate to your project directory
cd /Users/vinoth/muteapp/muteapp

# Get debug SHA-1 (macOS/Linux)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Look for the SHA1 fingerprint in the output
```

#### For Release Certificate (Production):
```bash
# If you have a release keystore
keytool -list -v -keystore /path/to/your/release-keystore.jks -alias your-key-alias

# You'll be prompted for the keystore password
```

5. Enter the SHA-1 fingerprint you obtained
6. Click **Create**
7. **Important**: Copy and save the **Client ID** that's generated

## Step 5: Download Updated Configuration

1. In **APIs & Services** → **Credentials**
2. Find your OAuth 2.0 Client ID
3. Download the updated `google-services.json` file
4. Replace the existing `google-services.json` in your `app/` directory

## Step 6: Update Android Project Configuration

### Add Dependencies (if not already present)

Add to your `app/build.gradle`:

```gradle
dependencies {
    // Google Sign-In
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
    
    // Google API Client (if needed for other Google services)
    implementation 'com.google.api-client:google-api-client-android:1.23.0'
    implementation 'com.google.apis:google-api-services-oauth2:v2-rev20200213-1.30.10'
}
```

### Update AndroidManifest.xml

Add internet permission (if not already present):

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

## Step 7: Implementation Example

### Basic Google Sign-In Implementation

```kotlin
// In your Activity or Fragment
class MainActivity : AppCompatActivity() {
    
    private lateinit var googleSignInClient: GoogleSignInClient
    private val RC_SIGN_IN = 9001
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        // Configure Google Sign-In
        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestEmail()
            .requestIdToken(getString(R.string.default_web_client_id)) // This comes from google-services.json
            .build()
            
        googleSignInClient = GoogleSignIn.getClient(this, gso)
    }
    
    private fun signIn() {
        val signInIntent = googleSignInClient.signInIntent
        startActivityForResult(signInIntent, RC_SIGN_IN)
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == RC_SIGN_IN) {
            val task = GoogleSignIn.getSignedInAccountFromIntent(data)
            handleSignInResult(task)
        }
    }
    
    private fun handleSignInResult(completedTask: Task<GoogleSignInAccount>) {
        try {
            val account = completedTask.getResult(ApiException::class.java)
            // Signed in successfully
            updateUI(account)
        } catch (e: ApiException) {
            // Sign in failed
            Log.w("SignIn", "signInResult:failed code=" + e.statusCode)
            updateUI(null)
        }
    }
    
    private fun updateUI(account: GoogleSignInAccount?) {
        if (account != null) {
            // User is signed in
            val email = account.email
            val name = account.displayName
            // Update your UI accordingly
        } else {
            // User is signed out
        }
    }
}
```

## Step 8: Testing

1. Build and run your app
2. Test the OAuth flow with the test users you added in Step 3
3. Verify that authentication works correctly

## Step 9: Publishing (When Ready)

1. Generate a release SHA-1 certificate fingerprint
2. Add the release SHA-1 to your OAuth client ID in Google Cloud Console
3. Update your OAuth consent screen to "In production" status
4. Remove test user restrictions

## Important Notes

- **Client ID**: The OAuth client ID will be automatically included in your `google-services.json` file
- **Security**: Never commit your release keystore to version control
- **Testing**: Use debug certificates for development and testing
- **Scopes**: Only request the minimum scopes your app actually needs
- **Verification**: Google may require app verification for certain sensitive scopes

## Troubleshooting

### Common Issues:

1. **SHA-1 Mismatch**: Ensure you're using the correct SHA-1 for your signing certificate
2. **Package Name Mismatch**: Verify package name matches exactly
3. **API Not Enabled**: Make sure required APIs are enabled in Google Cloud Console
4. **Consent Screen**: Ensure OAuth consent screen is properly configured

### Debug Commands:

```bash
# Check your app's package name
grep "package" app/src/main/AndroidManifest.xml

# Verify google-services.json is in the right location
ls -la app/google-services.json

# Check SHA-1 fingerprint
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

## Next Steps

After completing this setup:
1. Test OAuth authentication in your app
2. Implement proper error handling
3. Add sign-out functionality
4. Consider implementing token refresh logic
5. Test with different user accounts

Your OAuth client ID will now be ready for use in your MuteApp project!
