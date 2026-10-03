import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_actions_widget.dart';
import 'comments_bottom_sheet.dart';

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
  bool _showPlayIcon = false; // የፕሌይ/ፓውስ ምልክቱን ለማሳየት እና ለመደብዘዝ

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

  // ቪዲዮውን ሲነኩት ፕሌይ/ፓውስ እንዲያደርግ እና ምልክቱ ለአጭር ጊዜ ታይቶ እንዲጠፋ
  void _togglePlayPause() {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      _showPlayIcon = true;
    });

    // ከ 800 ሚሊሰከንድ በኋላ ምልክቱን መደበቅ
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showPlayIcon = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. የቪዲዮ ማጫወቻ እና የመሃል ንክኪ (Tap to Play/Pause with Icon Animation)
          Center(
            child: _isInitialized && _videoController != null
                ? GestureDetector(
                    onTap: _togglePlayPause,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        // መሃል ላይ የሚታየው የ Play ወይም Pause አዶ
                        AnimatedOpacity(
                          opacity: _showPlayIcon ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.play_arrow
                                  : Icons.pause,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ],
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
            bottom: 75,
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

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'video_actions_widget.dart';
import 'comments_bottom_sheet.dart';

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
  bool _showPlayIcon = false; // የፕሌይ/ፓውስ ምልክቱን ለማሳየት እና ለመደብዘዝ

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

  // ቪዲዮውን ሲነኩት ፕሌይ/ፓውስ እንዲያደርግ እና ምልክቱ ለአጭር ጊዜ ታይቶ እንዲጠፋ
  void _togglePlayPause() {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      _showPlayIcon = true;
    });

    // ከ 800 ሚሊሰከንድ በኋላ ምልክቱን መደበቅ
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showPlayIcon = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. የቪዲዮ ማጫወቻ እና የመሃል ንክኪ (Tap to Play/Pause with Icon Animation)
          Center(
            child: _isInitialized && _videoController != null
                ? GestureDetector(
                    onTap: _togglePlayPause,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        // መሃል ላይ የሚታየው የ Play ወይም Pause አዶ
                        AnimatedOpacity(
                          opacity: _showPlayIcon ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.play_arrow
                                  : Icons.pause,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ],
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
            bottom: 75,
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
