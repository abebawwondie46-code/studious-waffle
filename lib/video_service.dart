import 'dart:io';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';

class VideoService {
  /// Converts a static image (poster) into a short video clip (MP4).
  static Future<String?> convertImageToVideo(String imagePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final outputPath =
          '${directory.path}/output_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // FFmpeg command to loop the image for 5 seconds and encode as H.264 video
      final ffmpegCommand =
          '-loop 1 -i "$imagePath" -c:v libx264 -t 5 -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" "$outputPath"';

      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
