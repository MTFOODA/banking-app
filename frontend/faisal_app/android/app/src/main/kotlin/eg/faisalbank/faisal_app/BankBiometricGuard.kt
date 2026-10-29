package eg.faisalbank.faisal_app

import android.app.Activity
import android.hardware.biometrics.BiometricManager
import android.hardware.biometrics.BiometricPrompt
import android.os.Build
import android.os.CancellationSignal
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey

/** Enrollment-bound presence proof only. Banking tokens remain in SessionStore.
 * A new CryptoObject is required for EVERY invocation, including after enabling;
 * no decrypted storage cipher or biometric success is cached in process memory.
 */
class BankBiometricGuard(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "banking/biometric_guard_v2")
    private var pending: MethodChannel.Result? = null
    private var cancellation: CancellationSignal? = null

    init {
        channel.setMethodCallHandler { call, result ->
            if (call.method == "supported") {
                result.success(Build.VERSION.SDK_INT >= 28)
            } else if (Build.VERSION.SDK_INT < 28) {
                result.success(false)
            } else {
                val identity = call.argument<String>("identity")
                if (identity == null || !Regex("^[a-zA-Z0-9-]{1,80}$").matches(identity)) {
                    result.success(false)
                } else if (call.method == "disable") {
                    try { keyStore().deleteEntry(alias(identity)); result.success(true) }
                    catch (_: Exception) { result.success(false) }
                } else if (call.method == "enable" || call.method == "unlock") {
                    authenticate(identity, call.argument<String>("reason") ?: "Verify your identity",
                        call.method == "enable", result)
                } else { result.notImplemented() }
            }
        }
    }

    private fun keyStore() = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
    private fun alias(identity: String) = "banking.biometric.v2." +
        MessageDigest.getInstance("SHA-256").digest(identity.toByteArray()).joinToString("") { "%02x".format(it) }

    @android.annotation.TargetApi(28)
    @Suppress("DEPRECATION")
    private fun authenticate(identity: String, reason: String, enable: Boolean, result: MethodChannel.Result) {
        if (pending != null) { result.success(false); return }
        try {
            val name = alias(identity)
            if (enable) {
                val specification = KeyGenParameterSpec.Builder(name, KeyProperties.PURPOSE_ENCRYPT)
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setKeySize(256)
                    .setUserAuthenticationRequired(true)
                    .setInvalidatedByBiometricEnrollment(true)
                if (Build.VERSION.SDK_INT >= 30) {
                    specification.setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
                } else { specification.setUserAuthenticationValidityDurationSeconds(-1) }
                KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore").apply {
                    init(specification.build()); generateKey()
                }
            }
            // Never recreate an absent or invalidated key during unlock.
            val key = keyStore().getKey(name, null) as? SecretKey
            if (key == null) { result.success(false); return }
            val cipher = Cipher.getInstance("AES/GCM/NoPadding").apply { init(Cipher.ENCRYPT_MODE, key) }
            val builder = BiometricPrompt.Builder(activity).setTitle(reason)
                .setNegativeButton(activity.getString(android.R.string.cancel), activity.mainExecutor) { _, _ -> finish(false) }
            if (Build.VERSION.SDK_INT >= 30) { builder.setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG) }
            pending = result
            cancellation = CancellationSignal()
            builder.build().authenticate(BiometricPrompt.CryptoObject(cipher), cancellation!!,
                activity.mainExecutor, object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(authentication: BiometricPrompt.AuthenticationResult) {
                        try {
                            if (authentication.cryptoObject?.cipher !== cipher) { finish(false); return }
                            cipher.doFinal(ByteArray(32).also { SecureRandom().nextBytes(it) })
                            finish(true)
                        } catch (_: Exception) { finish(false) }
                    }
                    override fun onAuthenticationError(errorCode: Int, message: CharSequence) { finish(false) }
                    // A failed scan remains inside this same OS prompt for retry.
                })
        } catch (_: Exception) { if (pending == null) result.success(false) else finish(false) }
    }

    private fun finish(verified: Boolean) {
        val result = pending ?: return
        pending = null
        cancellation = null
        result.success(verified)
    }

    fun dispose() {
        cancellation?.cancel()
        finish(false)
        channel.setMethodCallHandler(null)
    }
}
