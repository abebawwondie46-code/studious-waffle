import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticateWithFingerprint() async {
    try {
      // መሣሪያው ባዮሜትሪክ ወይም ፕን ኮድ መደገፉን ማረጋገጥ
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        return true; // መሣሪያው የማይደግፍ ከሆነ በቀጥታ ያስገባል
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedAuthenticatedReason: 'እባክዎ ሚስጥራዊ ቻቱን ለመክፈት አሻራዎን ይጠቀሙ',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // አሻራ ካልሰራ በስልኩ ፒን/ፓተርን እንዲከፈት ይፈቅዳል (እንዲጣበቅ አያደርግም)
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Biometric error: $e');
      return false;
    }
  }
}
