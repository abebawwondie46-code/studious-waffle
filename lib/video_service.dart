import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path_provider/path_provider.dart';

class VideoService {
  // ምስልን ወደ MP4 ቪዲዮ የመቀየር ተግባር
  static Future<String?> convertImageToVideo(String imagePath) async {
    try {
      final directory = await getTemporaryDirectory();
      final outputPath =
          '${directory.path}/ad_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // ምስሉን ለ 5 ሰከንድ አቆይቶ ከZoom ኤፌክት ጋር ወደ MP4 መቀየሪያ የFFmpeg ትእዛዝ
      String ffmpegCommand =
          "-loop 1 -i $imagePath -vf \"scale=800:800,zoompan=z='min(zoom+0.0015,1.1)':d=125:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)'\" -c:v libx264 -t 5 -pix_fmt yuv420p $outputPath";

      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return outputPath; // የተሰራው ቪዲዮ ፋይል አድራሻ
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
