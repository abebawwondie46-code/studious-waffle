import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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

class _AdVideoItemState extends State<AdVideoItem> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _showPlayIcon = false;
  late AnimationController _discController;
  
  // የሰርች (Search) መቆጣጠሪያዎች
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _discController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
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
    if (mounted && _videoController != null && _videoController!.value.isInitialized) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discController.dispose();
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

  // የሰርች ማዘዣ ሳጥን (Search Dialog) ማሳያ
  void _openSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('ቪዲዮዎችን ይፈልጉ', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ቁልፍ ቃል ያስገቡ...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.black54,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
            ),
            onSubmitted: (value) {
              setState(() {
                _searchQuery = value.trim();
                _isSearching = _searchQuery.isNotEmpty;
              });
              Navigator.pop(context);
              if (_isSearching) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('የተፈለገው: "$_searchQuery"')),
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ሰርዝ', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                setState(() {
                  _searchQuery = _searchController.text.trim();
                  _isSearching = _searchQuery.isNotEmpty;
                });
                Navigator.pop(context);
                if (_isSearching) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('የተፈለገው: "$_searchQuery"')),
                  );
                }
              },
              child: const Text('ፈልግ', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _discController.stop();
      } else {
        _videoController!.play();
        _discController.repeat();
      }
      _showPlayIcon = true;
    });

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
    final Duration duration = (_isInitialized && _videoController != null)
        ? _videoController!.value.duration
        : Duration.zero;
        
    final Duration position = (_isInitialized && _videoController != null)
        ? _videoController!.value.position
        : Duration.zero;

    final double maxDurationMs = duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final double currentPositionMs = position.inMilliseconds.toDouble().clamp(0.0, maxDurationMs);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. ቪዲዮው ሙሉ ስክሪኑን እንዲሸፍን (Full Screen Cover)
          _isInitialized && _videoController != null
              ? GestureDetector(
                  onTap: _togglePlayPause,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                      // ጫን/አቁም (Play/Pause) ምልክት በመሃል ላይ
                      Center(
                        child: AnimatedOpacity(
                          opacity: _showPlayIcon ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
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
                      ),
                    ],
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.redAccent),
                ),

          // 2. ከላይ በስተቀኝ በኩል የሰርች (Search) ቁልፍ - የተካተተበት ቦታ
          Positioned(
            top: 45,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 28),
              onPressed: _openSearchDialog,
            ),
          ),

          // 3. ከስክሪኑ በታች ከጨለማ ዳራ ጋር የሚታዩ ጽሁፎች፣ የልዩ ቅንንት ምልክት እና የጊዜ መስመር (Slider)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 40, 70, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // የልዩ ቅናሽ ባጅ (Badge)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber[700],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔥 🔥', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Text(
                          'ልዩ ቅናሽ!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // የቪዲዮ ባለቤቱ ስም ወይም ርዕስ (እንዲሁም ሰርች የተደረገ ቃል ካለ ማሳየት ይቻላል)
                  Text(
                    _isSearching ? '${widget.title} (ፍለጋ: $_searchQuery)' : widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // የጊዜ መስመር (Slider) እና ሰዓቶች
                  if (_isInitialized && _videoController != null) ...[
                    Row(
                      children: [
                        Text(
                          _formatDuration(position),
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                            ),
                            child: Slider(
                              value: currentPositionMs,
                              min: 0.0,
                              max: maxDurationMs,
                              activeColor: Colors.redAccent,
                              inactiveColor: Colors.white38,
                              onChanged: (value) {
                                _videoController!.seekTo(Duration(milliseconds: value.toInt()));
                              },
                            ),
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 4. የጎን አዝራሮች (Profile, Like 44.0K, Comment 745, Share 1.8K እና የሚሽከረከር የሙዚቃ ዲስክ)
          Positioned(
            right: 12,
            bottom: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // የፕሮፋይል አዶ (+ ምልክት ያለው)
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white, size: 26),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),

                // ላይክ (Like - 440)
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border, color: Colors.white, size: 32),
                      onPressed: () {},
                    ),
                    const Text(
                      '440',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ኮሜንት (Comment - 745)
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 30),
                      onPressed: _openComments,
                    ),
                    const Text(
                      '745',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ሼር (Share - 112)
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.white, size: 30),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ሊንኩ ተገልብጧል!')),
                        );
                      },
                    ),
                    const Text(
                      '112',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // የሚሽከረከር የሙዚቃ ዲስክ አዶ (Rotating Audio Disc)
                RotationTransition(
                  turns: _discController,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 6),
                    ),
                    child: const Center(
                      child: Icon(Icons.music_note, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
