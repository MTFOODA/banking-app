package eg.faisalbank.faisal_app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private var biometricGuard: BankBiometricGuard? = null
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        biometricGuard = BankBiometricGuard(this, flutterEngine.dartExecutor.binaryMessenger)
    }
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        biometricGuard?.dispose()
        biometricGuard = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
