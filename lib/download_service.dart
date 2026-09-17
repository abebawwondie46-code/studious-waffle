import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineDownloadService {
  static const String _keyDownloads = 'offline_downloads_list';

  // Download video with progress
  Future<bool> downloadVideo(
    String videoId,
    String title,
    String videoUrl, {
    Function(int count, int total)? onProgress,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/vid_$videoId.mp4';

      Dio dio = Dio();
      await dio.download(
        videoUrl,
        savePath,
        onReceiveProgress: onProgress,
      );

      final prefs = await SharedPreferences.getInstance();
      List<String> list = prefs.getStringList(_keyDownloads) ?? [];

      Map<String, dynamic> newItem = {
        'id': videoId,
        'title': title,
        'localPath': savePath,
        'downloadedAt': DateTime.now().toIso8601String(),
        'expiryDays': 5,
      };

      // Remove existing duplicate if any
      list.removeWhere((item) {
        final parsed = jsonDecode(item);
        return parsed['id'] == videoId;
      });

      list.add(jsonEncode(newItem));
      await prefs.setStringList(_keyDownloads, list);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get valid videos (Deletes expired ones automatically)
  Future<List<Map<String, dynamic>>> getDownloadedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_keyDownloads) ?? [];
    List<Map<String, dynamic>> activeVideos = [];
    List<String> updatedList = [];

    for (String str in list) {
      Map<String, dynamic> item = jsonDecode(str);
      DateTime downloadedAt = DateTime.parse(item['downloadedAt']);
      int expiryDays = item['expiryDays'] ?? 5;

      // Check if 5 days have passed
      bool isExpired = DateTime.now().difference(downloadedAt).inDays >= expiryDays;

      if (!isExpired) {
        // Calculate remaining days
        int daysLeft = expiryDays - DateTime.now().difference(downloadedAt).inDays;
        item['daysLeft'] = daysLeft <= 0 ? 1 : daysLeft;
        activeVideos.add(item);
        updatedList.add(str);
      } else {
        // Automatically delete local file after 5 days
        final file = File(item['localPath']);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }

    // Save cleaned list (expired items removed)
    await prefs.setStringList(_keyDownloads, updatedList);
    return activeVideos;
  }

  // Delete Video manually
  Future<void> deleteVideo(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> list = prefs.getStringList(_keyDownloads) ?? [];
    List<String> updated = [];

    for (String item in list) {
      Map<String, dynamic> data = jsonDecode(item);
      if (data['id'] == videoId) {
        final file = File(data['localPath']);
        if (await file.exists()) {
          await file.delete();
        }
      } else {
        updated.add(item);
      }
    }
    await prefs.setStringList(_keyDownloads, updated);
  }
}
