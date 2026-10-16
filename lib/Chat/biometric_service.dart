import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticateWithFingerprint() async {
    try {
      // መሣሪያው አሻራ ማንበብ መቻሉን ማረጋገጥ
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        return true; 
      }

      // 🔒 አሻራ ብቻ (Biometric Only) እንዲጠይቅ የተደረገበት ውቅር
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'እባክዎ ሚስጥራዊ ቻቱን ለመክፈት አሻራዎን ይጠቀሙ',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true, // <--- የፒን ወይም የናሙና አማራጭን በማጥፋት አሻራ ብቻ እንዲጠይቅ አደረገው
          useErrorDialogs: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric error: $e');
      return false;
    }
  }
}
