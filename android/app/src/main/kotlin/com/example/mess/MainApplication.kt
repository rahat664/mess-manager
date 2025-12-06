package com.example.mess

import android.os.Build
import android.util.Log
import io.flutter.app.FlutterApplication
import org.conscrypt.Conscrypt
import java.security.Security

class MainApplication : FlutterApplication() {

    override fun onCreate() {
        super.onCreate()
        // Run off the main thread to avoid jank if Play Services needs work.
        Thread { installSecurityProvider() }.start()
    }

    private fun installSecurityProvider() {
        // Android 10+ ships a modern security provider; skip any extra work.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            Log.i(TAG, "Skipping provider install on API ${Build.VERSION.SDK_INT}; system provider is already modern")
            return
        }

        // For older devices, skip Play Services and install Conscrypt directly to avoid
        // Dynamite/GoogleApiManager noise on devices without certified GMS.
        installConscryptFallback()
    }

    private fun installConscryptFallback() {
        val provider = Conscrypt.newProvider()
        val existing = Security.getProvider(provider.name)
        if (existing == null) {
            Security.insertProviderAt(provider, 1)
            Log.i(TAG, "Conscrypt security provider installed as fallback")
        } else {
            Log.i(TAG, "Conscrypt security provider already present; leaving existing instance")
        }
    }

    companion object {
        private const val TAG = "MainApplication"
    }
}
