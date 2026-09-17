import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'download_service.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<Map<String, dynamic>> videos = [];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final list = await OfflineDownloadService().getDownloadedVideos();
    setState(() {
      videos = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121217),
      appBar: AppBar(
        title: const Text("Offline Downloads"),
        backgroundColor: const Color(0xFF121217),
      ),
      body: videos.isEmpty
          ? const Center(
              child: Text("No offline downloads found.", style: TextStyle(color: Colors.white70)),
            )
          : ListView.builder(
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final item = videos[index];
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.pinkAccent),
                  title: Text(item['title'] ?? 'Video', style: const TextStyle(color: Colors.white)),
                  subtitle: const Text("Expires in 5 days", style: TextStyle(color: Colors.grey)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 32),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OfflinePlayerScreen(
                                filePath: item['localPath'],
                                title: item['title'],
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          await OfflineDownloadService().deleteVideo(item['id']);
                          _loadVideos();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class OfflinePlayerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const OfflinePlayerScreen({super.key, required this.filePath, required this.title});

  @override
  State<OfflinePlayerScreen> meState() => _OfflinePlayerScreenState();
}

class _OfflinePlayerScreenState extends State<OfflinePlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.filePath))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.black),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
