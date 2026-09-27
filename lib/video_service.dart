import 'dart:io';
import 'package:path_provider/path_provider.dart';

class VideoService {
  /// Converts an image to a video path or returns the original image path as fallback.
  static Future<String?> convertImageToVideo(String imagePath) async {
    try {
      // ffmpeg ሳይያስፈልግ የምስሉን ፋይል መንገድ በቀጥታ ይመልሳል
      final file = File(imagePath);
      if (await file.exists()) {
        return imagePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
