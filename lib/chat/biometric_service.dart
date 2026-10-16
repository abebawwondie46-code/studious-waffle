import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// መሳሪያው ባዮሜትሪክ/አሻራ መደገፉን ማረጋገጥ
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      return false;
    }
  }

  /// አሻራ በመጠየቅ ማረጋገጥ (Authenticate)
  static Future<bool> authenticateWithFingerprint() async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) return true; // መሳሪያው ባዮሜትሪክ ከሌለው ቀጥታ ይክፈት

      return await _auth.authenticate(
        localizedReason: 'የሚስጥር መልእክቶችን ለመክፈት አሻራዎን ያንኩ',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Biometric Error: $e');
      return false;
    }
  }
}
