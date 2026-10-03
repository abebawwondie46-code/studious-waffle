import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart'; // ሼር ለማድረግ የሚያስችል ፓኬጅ
import 'comments_bottom_sheet.dart';

class AdVideoItem extends StatefulWidget {
  final String title;
  final String videoUrl;
  final Map<String, dynamic> templateJson;
  final String? videoId;

  const AdVideoItem({
    super.key,
    required this.title,
    required this.videoUrl,
    required this.templateJson,
    this.videoId,
  });

  @override
  State<AdVideoItem> createState() => _AdVideoItemState();
}

class _AdVideoItemState extends State<AdVideoItem> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _showPlayIcon = false;
  late AnimationController _discController;
  
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  int _likeCount = 440;
  bool _isLiked = false;
  int _commentCount = 745;
  int _shareCount = 112;
  bool _isFollowing = false; // የፕሮፋይል ፕላስ ቁልፍ ሁኔታ

  @override
  void initState() {
    super.initState();
    _discController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _initializeVideo();
    _fetchEngagementData();
  }

  Future<void> _fetchEngagementData() async {
    if (widget.videoId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('videos')
          .select('likes_count, comments_count, shares_count')
          .eq('id', widget.videoId!)
          .single();

      if (mounted) {
        setState(() {
          _likeCount = response['likes_count'] ?? _likeCount;
          _commentCount = response['comments_count'] ?? _commentCount;
          _shareCount = response['shares_count'] ?? _shareCount;
        });
      }
    } catch (e) {
      debugPrint('ዳታ በማምጣት ላይ ስህተት ተፈጥሯል: $e');
    }
  }

  Future<void> _handleLikePressed() async {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });

    if (widget.videoId != null) {
      try {
        await Supabase.instance.client
            .from('videos')
            .update({'likes_count': _likeCount})
            .eq('id', widget.videoId!);
      } catch (e) {
        debugPrint('ላይክን ወደ ሰርቨር መላክ አልተቻለም: $e');
      }
    }
  }

  // 1. የሼር ተግባር (Share to apps)
  Future<void> _handleSharePressed() async {
    try {
      await Share.share('ይህንን አስደሳች ቪዲዮ ይመልከቱ: ${widget.videoUrl}');
      setState(() {
        _shareCount += 1;
      });

      if (widget.videoId != null) {
        await Supabase.instance.client
            .from('videos')
            .update({'shares_count': _shareCount})
            .eq('id', widget.videoId!);
      }
    } catch (e) {
      debugPrint('ሼር ማድረግ ላይ ስህተት ተፈጥሯል: $e');
    }
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

  // 2. የኮሜንት መስኮት መክፈቻ (Comments with videoId support)
  void _openComments() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.grey[900],
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => CommentsBottomSheet(
      videoId: widget.videoUrl,
      onCommentCountUpdated: (newCount) {
        setState(() {
          _commentCount = newCount; // ከታች አዲስ ኮሜንት ሲጨመር የውጪው ቁጥር እንዲቀየር ያደርጋል
        });
      },
    ),
  );
}

  void _openSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('ቪዲዮዎችን በኢንተርኔት ይፈልጉ', style: TextStyle(color: Colors.white, fontSize: 18)),
          content: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ርዕስ ወይም ቁልፍ ቃል ያስገቡ...',
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.black54,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
            ),
            onSubmitted: (value) async {
              Navigator.pop(context);
              await _performSearch(value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ሰርዝ', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                final query = _searchController.text.trim();
                Navigator.pop(context);
                await _performSearch(query);
              },
              child: const Text('ፈልግ', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    try {
      final results = await Supabase.instance.client
          .from('videos')
          .select()
          .ilike('title', '%$query%');

      setState(() {
        _searchQuery = query;
        _isSearching = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${results.length} ቪዲዮዎች ተገኝተዋል!')),
        );
      }
    } catch (e) {
      debugPrint('የፍለጋ ስህተት: $e');
    }
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

          Positioned(
            top: 45,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 28),
              onPressed: _openSearchDialog,
            ),
          ),

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
                  Text(
                    _isSearching ? '${widget.title} (ፍለጋ: $_searchQuery)' : widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
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

          Positioned(
            right: 12,
            bottom: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 3. የፕሮፋይል ፕላስ ቁልፍ (+) ተግባር
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isFollowing = !_isFollowing;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isFollowing ? 'ተጠቃሚውን ተከተሉ (Following)!' : 'ማስተከተል ሰርዟል'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Stack(
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
                          decoration: BoxDecoration(
                            color: _isFollowing ? Colors.green : Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isFollowing ? Icons.check : Icons.add,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ላይክ (Like)
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.redAccent : Colors.white,
                        size: 32,
                      ),
                      onPressed: _handleLikePressed,
                    ),
                    Text(
                      '$_likeCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ኮሜንት (Comment)
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 28),
                      onPressed: _openComments,
                    ),
                    Text(
                      '$_commentCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ሼር (Share)
                Column(
                  children: [
                    IconButton(
                      icon: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(3.14159),
                        child: const Icon(Icons.reply, color: Colors.white, size: 30),
                      ),
                      onPressed: _handleSharePressed,
                    ),
                    Text(
                      '$_shareCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

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
