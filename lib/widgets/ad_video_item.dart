import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_actions_widget.dart'; // የላይክ፣ ሼር እና ኮሜንት መክፈቻ የያዘው ፋይል
import 'comments_bottom_sheet.dart'; // የኮሜንት ማስቀመጫ ሺት

class AdVideoItem extends StatefulWidget {
  final String title;
  final String videoUrl;
  final Map<String, dynamic> templateJson;

  const AdVideoItem({
    super.key,
    required this.title,
    required this.videoUrl,
    required this.templateJson,
  });

  @override
  State<AdVideoItem> createState() => _AdVideoItemState();
}

class _AdVideoItemState extends State<AdVideoItem> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    if (widget.videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
            _videoController?.play();
            _videoController?.setLooping(true);
          }
        });

      // የቪዲዮውን ወቅታዊ ቦታ ለመከታተል Listener መጨመር
      _videoController?.addListener(_videoListener);
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const CommentsBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. የቪዲዮ ማጫወቻ ገጽ
          Center(
            child: _isInitialized && _videoController != null
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_videoController!.value.isPlaying) {
                          _videoController!.pause();
                        } else {
                          _videoController!.play();
                        }
                      });
                    },
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  )
                : const CircularProgressIndicator(color: Colors.redAccent),
          ),

          // 2. ከቀኝ በኩል የሚታዩ መስተጋብራዊ ቁልፎች (ላይክ፣ ሼር፣ ወዘተ)
          Positioned(
            right: 16,
            bottom: 100,
            child: VideoActionsWidget(
              initialLikeCount: 54,
              shareCount: 1809,
              onCommentPressed: _openComments,
              onSharePressed: () {
                // የሼር ማድረጊያ ኮድ እዚህ ይገባል
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ሊንኩ ተገልብጧል!')),
                );
              },
            ),
          ),

          // 3. ከታች በኩል የቪዲዮ ርዕስ እና የጊዜ መስመር (Timeline Slider)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (_isInitialized && _videoController != null) ...[
                  Row(
                    children: [
                      Text(
                        _formatDuration(_videoController!.value.position),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Expanded(
                        child: Slider(
                          value: _videoController!.value.position.inMilliseconds.toDouble(),
                          min: 0.0,
                          max: _videoController!.value.duration.inMilliseconds > 0
                              ? _videoController!.value.duration.inMilliseconds.toDouble()
                              : 1.0,
                          activeColor: Colors.redAccent,
                          inactiveColor: Colors.grey.withOpacity(0.5),
                          onChanged: (value) {
                            _videoController!.seekTo(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),
                      Text(
                        _formatDuration(_videoController!.value.duration),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
