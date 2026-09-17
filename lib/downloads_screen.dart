import 'dart0:io' if (dart.library.html) 'dart:html';
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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    final list = await OfflineDownloadService().getDownloadedVideos();
    setState(() {
      videos = list;
      isLoading = false;
    });
  }

  void _confirmDelete(String videoId, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text("Delete Video", style: TextStyle(color: Colors.white)),
          content: Text("Are you sure you want to delete '$title'?",
              style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await OfflineDownloadService().deleteVideo(videoId);
                _loadVideos();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video deleted successfully')),
                  );
                }
              },
              child: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121217),
      appBar: AppBar(
        title: const Text("Offline Downloads", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF121217),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          : videos.isEmpty
              ? const Center(
                  child: Text(
                    "No offline downloads found.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final item = videos[index];
                    int daysLeft = item['daysLeft'] ?? 5;

                    return GestureDetector(
                      onLongPress: () => _confirmDelete(item['id'], item['title'] ?? 'Video'),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.pinkAccent),
                          title: Text(
                            item['title'] ?? 'Video',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            "Expires in $daysLeft day${daysLeft > 1 ? 's' : ''}",
                            style: TextStyle(
                              color: daysLeft <= 1 ? Colors.redAccent : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 36),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OfflinePlayerScreen(
                                    filePath: item['localPath'],
                                    title: item['title'] ?? 'Offline Video',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
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
  State<OfflinePlayerScreen> createState() => _OfflinePlayerScreenState();
}

class _OfflinePlayerScreenState extends State<OfflinePlayerScreen> {
  late VideoPlayerController _controller;
  bool _isError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    final file = File(widget.filePath);
    if (file.existsSync()) {
      _controller = VideoPlayerController.file(file)
        ..initialize().then((_) {
          setState(() {});
          _controller.play();
        }).catchError((e) {
          setState(() {
            _isError = true;
          });
        });

      _controller.addListener(() {
        if (mounted) setState(() {});
      });
    } else {
      _isError = true;
    }
  }

  @override
  void dispose() {
    if (!_isError) {
      _controller.dispose();
    }
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _isError
            ? const Text("Video file not found or expired.", style: TextStyle(color: Colors.white))
            : _controller.value.isInitialized
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        _showControls = !_showControls;
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),

                        // Play/Pause button on screen overlay
                        if (_showControls)
                          IconButton(
                            iconSize: 64,
                            icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              color: Colors.white.withOpacity(0.8),
                            ),
                            onPressed: () {
                              setState(() {
                                if (_controller.value.isPlaying) {
                                  _controller.pause();
                                } else {
                                  _controller.play();
                                }
                              });
                            },
                          ),

                        // Bottom Video Progress Bar (የጊዜ መስመር)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                VideoProgressIndicator(
                                  _controller,
                                  allowScrubbing: true, // በጣት ጎትቶ ጊዜውን ለማቀያየር
                                  colors: const VideoProgressColors(
                                    playedColor: Colors.pinkAccent,
                                    bufferedColor: Colors.white30,
                                    backgroundColor: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_controller.value.position),
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                    Text(
                                      _formatDuration(_controller.value.duration),
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.pinkAccent),
      ),
    );
  }
}
