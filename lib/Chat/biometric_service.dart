import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticateWithFingerprint() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        return true; 
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'እባክዎ ሚስጥራዊ ቻቱን ለመክፈት አሻራዎን ይጠቀሙ',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric error: $e');
      return true;
    } catch (e) {
      print('General error: $e');
      return true;
    }
  }
}
