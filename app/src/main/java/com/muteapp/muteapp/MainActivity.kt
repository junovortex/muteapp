package com.muteapp.muteapp

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.view.View
import android.widget.Toast
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import com.muteapp.muteapp.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityMainBinding
    private lateinit var googleSignInClient: GoogleSignInClient
    private lateinit var auth: FirebaseAuth
    
    private val signInLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        val task = GoogleSignIn.getSignedInAccountFromIntent(result.data)
        try {
            val account = task.getResult(ApiException::class.java)!!
            Log.d(TAG, "firebaseAuthWithGoogle:" + account.id)
            firebaseAuthWithGoogle(account.idToken!!)
        } catch (e: ApiException) {
            Log.w(TAG, "Google sign in failed with code: ${e.statusCode}", e)
            val errorMessage = when (e.statusCode) {
                12501 -> "Sign in cancelled by user"
                12502 -> "Sign in currently in progress"
                12500 -> "Sign in failed - please try again"
                else -> "Google sign in failed: ${e.message}"
            }
            Toast.makeText(this, errorMessage, Toast.LENGTH_LONG).show()
        }
    }
    
    private val overlayPermissionLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { _ ->
        if (canDrawOverlays()) {
            startFloatingButtonService()
        } else {
            Toast.makeText(this, getString(R.string.permission_denied), Toast.LENGTH_LONG).show()
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        // Configure Google Sign In
        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken(getString(R.string.default_web_client_id))
            .requestEmail()
            .build()
        
        googleSignInClient = GoogleSignIn.getClient(this, gso)
        auth = FirebaseAuth.getInstance()
        
        setupClickListeners()
        updateUI(auth.currentUser != null)
    }
    
    private fun setupClickListeners() {
        binding.signInButton.setOnClickListener {
            signIn()
        }
        
        binding.signOutButton.setOnClickListener {
            signOut()
        }
        
        binding.startFloatingButton.setOnClickListener {
            checkOverlayPermission()
        }
    }
    
    private fun signIn() {
        val signInIntent = googleSignInClient.signInIntent
        signInLauncher.launch(signInIntent)
    }
    
    private fun firebaseAuthWithGoogle(idToken: String) {
        val credential = GoogleAuthProvider.getCredential(idToken, null)
        auth.signInWithCredential(credential)
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    Log.d(TAG, "signInWithCredential:success")
                    val user = auth.currentUser
                    updateUI(true)
                    
                    // Save login state for offline support
                    val sharedPref = getSharedPreferences("MuteAppPrefs", MODE_PRIVATE)
                    with(sharedPref.edit()) {
                        putBoolean("is_logged_in", true)
                        putString("user_name", user?.displayName)
                        putString("user_email", user?.email)
                        apply()
                    }
                } else {
                    Log.w(TAG, "signInWithCredential:failure", task.exception)
                    Toast.makeText(this, "Authentication Failed.", Toast.LENGTH_SHORT).show()
                    updateUI(false)
                }
            }
    }
    
    private fun signOut() {
        auth.signOut()
        googleSignInClient.signOut().addOnCompleteListener(this) {
            updateUI(false)
            
            // Clear offline login state
            val sharedPref = getSharedPreferences("MuteAppPrefs", MODE_PRIVATE)
            with(sharedPref.edit()) {
                clear()
                apply()
            }
        }
    }
    
    private fun updateUI(isSignedIn: Boolean) {
        if (isSignedIn) {
            val user = auth.currentUser
            val sharedPref = getSharedPreferences("MuteAppPrefs", MODE_PRIVATE)
            
            binding.signInButton.visibility = View.GONE
            binding.signedInLayout.visibility = View.VISIBLE
            
            // Use Firebase user data if available, otherwise use cached data
            binding.userName.text = user?.displayName ?: sharedPref.getString("user_name", "User")
            binding.userEmail.text = user?.email ?: sharedPref.getString("user_email", "")
        } else {
            binding.signInButton.visibility = View.VISIBLE
            binding.signedInLayout.visibility = View.GONE
        }
    }
    
    private fun checkOverlayPermission() {
        if (canDrawOverlays()) {
            startFloatingButtonService()
        } else {
            Toast.makeText(this, getString(R.string.overlay_permission_required), Toast.LENGTH_LONG).show()
            val intent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:$packageName"))
            overlayPermissionLauncher.launch(intent)
        }
    }
    
    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true // Permission not required for API < 23
        }
    }
    
    private fun startFloatingButtonService() {
        val serviceIntent = Intent(this, FloatingButtonService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
        Toast.makeText(this, "Floating button started", Toast.LENGTH_SHORT).show()
        finish() // Close the main activity
    }
    
    override fun onStart() {
        super.onStart()
        // Check if user was previously logged in (offline support)
        val sharedPref = getSharedPreferences("MuteAppPrefs", MODE_PRIVATE)
        val wasLoggedIn = sharedPref.getBoolean("is_logged_in", false)
        
        if (wasLoggedIn && auth.currentUser == null) {
            // User was logged in before but Firebase auth is null (offline scenario)
            updateUI(true)
        } else {
            updateUI(auth.currentUser != null)
        }
    }
    
    companion object {
        private const val TAG = "MainActivity"
    }
}
