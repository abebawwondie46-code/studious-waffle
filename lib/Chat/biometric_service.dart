import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> authenticateWithFingerprint() async {
    try {
      // የስልኩ ባዮሜትሪክ ወይም ሴኩሪቲ ዝግጁ መሆኑን ማረጋገጥ
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;

      if (!isDeviceSupported && !canCheckBiometrics) {
        // ስልኩ አሻራ የማያነብ ከሆነ ወይም ከተሰናከለ ቀጥታ ይክፈት
        return true; 
      }

      // የአሻራ ማረጋገጫ ሳጥኑን በቀጥታ መጥራት
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'እባክዎ ሚስጥራዊ ቻቱን ለመክፈት አሻራዎን ይጠቀሙ',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true, // ቀጥታ የስልኩን አሻራ ሴንሰር እንዲቀሰቅስ
          useErrorDialogs: true, // ስህተት ካለ የስልኩን ማስጠንቀቂያ እንዲያሳይ
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      print("Biometric Exception: ${e.message}");
      // ማንኛውም የሲስተም ስህተት ካጋጠመ ተጠቃሚው እንዳይቆለፍበት መክፈት
      return true;
    } catch (e) {
      print("General Biometric Error: $e");
      return true;
    }
  }
}
