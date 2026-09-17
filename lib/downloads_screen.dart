import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'download_service.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<Map<String, String>> _downloadedVideos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloadedVideos();
  }

  Future<void> _loadDownloadedVideos() async {
    // ገጹ ሲከፈት ያለፉበትን በራሱ ያጸዳል
    await OfflineDownloadService().checkAndCleanExpiredDownloads();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> downloadedIds = prefs.getStringList('downloaded_video_ids') ?? [];
    List<Map<String, String>> tempVideos = [];

    for (String id in downloadedIds) {
      String? title = prefs.getString('video_title_$id');
      String? path = prefs.getString('video_path_$id');
      String? expiry = prefs.getString('video_expiry_$id');

      if (title != null && path != null && expiry != null) {
        DateTime expiryDate = DateTime.parse(expiry);
        int daysLeft = expiryDate.difference(DateTime.now()).inDays;

        tempVideos.add({
          'id': id,
          'title': title,
          'path': path,
          'daysLeft': daysLeft.toString(),
        });
      }
    }

    setState(() {
      _downloadedVideos = tempVideos;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Text('Offline Downloads', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF2B55)))
          : _downloadedVideos.isEmpty
              ? const Center(
                  child: Text(
                    'No downloaded videos yet.\nDownloaded videos expire in 5 days.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _downloadedVideos.length,
                  itemBuilder: (context, index) {
                    final video = _downloadedVideos[index];
                    return ListTile(
                      leading: const Icon(Icons.offline_pin, color: Color(0xFFFF2B55), size: 32),
                      title: Text(
                        video['title'] ?? 'Untitled Video',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Expires in ${video['daysLeft']} days',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.play_circle_fill, color: Colors.white, size: 28),
                      onTap: () {
                        // የወረደውን ቪዲዮ ለማጫወት የሚሆን logic
                      },
                    );
                  },
                ),
    );
  }
}
