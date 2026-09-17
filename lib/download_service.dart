import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineDownloadService {
  final Dio _dio = Dio();

  // 1. ቪዲዮ ማውረድ እና የ5 ቀን ገደብ መመዝገብ
  Future<bool> downloadVideo(String videoId, String videoTitle, String videoUrl) async {
    try {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String savePath = "${appDocDir.path}/offline_videos/$videoId.mp4";

      // ፎልደሩ ከሌለ መፍጠር
      Directory videoDir = Directory("${appDocDir.path}/offline_videos");
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      // ቪዲዮውን ማውረድ
      await _dio.download(videoUrl, savePath);

      // የወረደበትንና የሚያበቃበትን ቀን መመዝገብ (የዛሬ ቀን + 5 ቀን)
      SharedPreferences prefs = await SharedPreferences.getInstance();
      DateTime expiryDate = DateTime.now().add(const Duration(days: 5));

      await prefs.setString('video_path_$videoId', savePath);
      await prefs.setString('video_title_$videoId', videoTitle);
      await prefs.setString('video_expiry_$videoId', expiryDate.toIso8601String());

      // የወረዱ ቪዲዮዎችን ID ዝርዝር ማዘመን
      List<String> downloadedIds = prefs.getStringList('downloaded_video_ids') ?? [];
      if (!downloadedIds.contains(videoId)) {
        downloadedIds.add(videoId);
        await prefs.setStringList('downloaded_video_ids', downloadedIds);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // 2. ከ5 ቀን በኋላ ማለፉን አረጋግጦ በራሱ ማጥፋት (Auto-Delete)
  Future<void> checkAndCleanExpiredDownloads() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> downloadedIds = prefs.getStringList('downloaded_video_ids') ?? [];
    List<String> remainingIds = List.from(downloadedIds);

    DateTime now = DateTime.now();

    for (String videoId in downloadedIds) {
      String? expiryString = prefs.getString('video_expiry_$videoId');
      if (expiryString != null) {
        DateTime expiryDate = DateTime.parse(expiryString);

        // 5 ቀኑ ካለፈ ፋይሉን ከስልክ ማጥፋት
        if (now.isAfter(expiryDate)) {
          String? path = prefs.getString('video_path_$videoId');
          if (path != null) {
            File file = File(path);
            if (await file.exists()) {
              await file.delete();
            }
          }
          await prefs.remove('video_path_$videoId');
          await prefs.remove('video_title_$videoId');
          await prefs.remove('video_expiry_$videoId');
          remainingIds.remove(videoId);
        }
      }
    }
    await prefs.setStringList('downloaded_video_ids', remainingIds);
  }
}
