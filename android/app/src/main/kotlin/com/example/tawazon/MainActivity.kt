package com.example.tawazon

import android.Manifest
import android.app.AppOpsManager
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Bundle
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import java.util.concurrent.atomic.AtomicBoolean
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.example.tawazon/usage_alerts"
        private const val REQUEST_NOTIFICATIONS = 6401
        private const val REQUEST_LOCATION = 6402
    }

    private var pendingNotificationResult: MethodChannel.Result? = null
    private var pendingLocationResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> result.success(true)
                    "hasNotificationPermission" ->
                        result.success(hasNotificationPermission())
                    "requestNotificationPermission" ->
                        requestNotificationPermission(result)
                    "openNotificationSettings" -> openNotificationSettings(result)
                    "hasUsageAccess" -> result.success(hasUsageAccess())
                    "openUsageAccessSettings" -> openUsageAccessSettings(result)
                    "isUsageAlertEnabled" ->
                        result.success(UsageAlertScheduler.isEnabled(this))
                    "enableUsageAlert" -> {
                        val minutes = call.argument<Int>("thresholdMinutes") ?: 240
                        result.success(
                            UsageAlertScheduler.enable(this, minutes),
                        )
                    }
                    "disableUsageAlert" -> {
                        UsageAlertScheduler.disable(this)
                        result.success(true)
                    }
                    "getUsageWeek" ->
                        result.success(UsageAlertScheduler.getUsageWeek(this))
                    "getCurrentLocation" -> requestCurrentLocation(result)
                    "openLocationAppSettings" -> openLocationAppSettings(result)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        UsageAlertScheduler.ensureScheduled(this)
    }

    private fun hasNotificationPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (hasNotificationPermission()) {
            result.success(true)
            return
        }
        if (pendingNotificationResult != null) {
            result.error("REQUEST_IN_PROGRESS", "Permission request is pending.", null)
            return
        }
        pendingNotificationResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_NOTIFICATIONS,
        )
    }

    @Suppress("DEPRECATION")
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        when (requestCode) {
            REQUEST_NOTIFICATIONS -> {
                val granted =
                    grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
                pendingNotificationResult?.success(granted)
                pendingNotificationResult = null
                UsageAlertScheduler.ensureScheduled(this)
            }
            REQUEST_LOCATION -> {
                val pending = pendingLocationResult
                pendingLocationResult = null
                if (pending != null) {
                    if (hasLocationPermission()) {
                        resolveCurrentLocation(pending)
                    } else {
                        pending.success(null)
                    }
                }
            }
        }
    }

    private fun hasLocationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        return checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED ||
            checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun requestCurrentLocation(result: MethodChannel.Result) {
        if (hasLocationPermission()) {
            resolveCurrentLocation(result)
            return
        }
        if (pendingLocationResult != null) {
            result.error("REQUEST_IN_PROGRESS", "Location request is pending.", null)
            return
        }
        pendingLocationResult = result
        requestPermissions(
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            ),
            REQUEST_LOCATION,
        )
    }

    @Suppress("DEPRECATION")
    private fun resolveCurrentLocation(result: MethodChannel.Result) {
        val manager = getSystemService(LOCATION_SERVICE) as LocationManager
        val hasFineLocation =
            Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
                PackageManager.PERMISSION_GRANTED
        val candidateProviders = buildList {
            if (hasFineLocation) add(LocationManager.GPS_PROVIDER)
            add(LocationManager.NETWORK_PROVIDER)
        }
        val enabledProviders = candidateProviders.filter { provider ->
            try {
                manager.isProviderEnabled(provider)
            } catch (_: Exception) {
                false
            }
        }
        val recentLocation = enabledProviders
            .mapNotNull { provider ->
                try {
                    manager.getLastKnownLocation(provider)
                } catch (_: SecurityException) {
                    null
                }
            }
            .filter { System.currentTimeMillis() - it.time <= 6 * 60 * 60 * 1000L }
            .maxByOrNull { it.time }

        if (enabledProviders.isEmpty()) {
            result.success(recentLocation?.toChannelValue())
            return
        }

        val completed = AtomicBoolean(false)
        val handler = Handler(Looper.getMainLooper())
        val listeners = mutableListOf<LocationListener>()
        var timeout: Runnable? = null
        fun finish(location: Location?) {
            if (!completed.compareAndSet(false, true)) return
            timeout?.let { handler.removeCallbacks(it) }
            listeners.forEach { listener ->
                try {
                    manager.removeUpdates(listener)
                } catch (_: SecurityException) {
                    // Permission may have changed while the request was active.
                }
            }
            result.success(location?.toChannelValue())
        }
        val timeoutRunnable = Runnable { finish(recentLocation) }
        timeout = timeoutRunnable

        var started = false
        for (provider in enabledProviders) {
            val listener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    finish(location)
                }

                override fun onProviderEnabled(provider: String) = Unit
                override fun onProviderDisabled(provider: String) = Unit
                override fun onStatusChanged(
                    provider: String?,
                    status: Int,
                    extras: Bundle?,
                ) = Unit
            }
            listeners.add(listener)
            try {
                manager.requestSingleUpdate(provider, listener, Looper.getMainLooper())
                started = true
            } catch (_: SecurityException) {
                // Coarse-only users may not be allowed to query GPS.
            } catch (_: IllegalArgumentException) {
                // A manufacturer may omit a provider.
            }
        }
        if (started) {
            handler.postDelayed(timeoutRunnable, 12_000)
        } else {
            finish(recentLocation)
        }
    }

    private fun Location.toChannelValue(): Map<String, Double> =
        mapOf("latitude" to latitude, "longitude" to longitude)

    @Suppress("DEPRECATION")
    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(APP_OPS_SERVICE) as AppOpsManager
        return try {
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName,
            ) == AppOpsManager.MODE_ALLOWED
        } catch (_: SecurityException) {
            false
        }
    }

    private fun openUsageAccessSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
            }
            startActivity(intent)
            result.success(true)
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                result.success(true)
            } catch (error: Exception) {
                result.error("SETTINGS_UNAVAILABLE", error.message, null)
            }
        }
    }

    private fun openNotificationSettings(result: MethodChannel.Result) {
        try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(
                    Settings.EXTRA_APP_PACKAGE,
                    packageName,
                )
            } else {
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                }
            }
            startActivity(intent)
            result.success(true)
        } catch (error: Exception) {
            result.error("SETTINGS_UNAVAILABLE", error.message, null)
        }
    }

    private fun openLocationAppSettings(result: MethodChannel.Result) {
        try {
            startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                },
            )
            result.success(true)
        } catch (error: Exception) {
            result.error("SETTINGS_UNAVAILABLE", error.message, null)
        }
    }
}
