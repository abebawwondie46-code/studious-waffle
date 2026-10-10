import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'comments_bottom_sheet.dart';

class AdVideoItem extends StatefulWidget {
  final String caption;
  final String videoUrl;
  final Map<String, dynamic> templateJson;
  final String? videoId;
  final VoidCallback? onVideoDeleted;
  final String? userAvatar; 
  final String? userName;   

  const AdVideoItem({
    super.key,
    required this.caption,
    required this.videoUrl,
    required this.templateJson,
    this.videoId,
    this.onVideoDeleted,
    this.userAvatar,
    this.userName,
  });

  @override
  State<AdVideoItem> createState() => _AdVideoItemState();
}

class _AdVideoItemState extends State<AdVideoItem> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _showPlayIcon = false;
  late AnimationController _discController;
  
  int _likeCount = 440;
  bool _isLiked = false;
  int _commentCount = 745;
  int _shareCount = 112;
  bool _isFollowing = false;
  int _followersCount = 0;

  // 🛑 የ (+) ወይም የራይት አዶውን እስከመጨረሻው ለመደብቅ የሚረዳ ቬርያብል
  bool _hidePlusSignPermanently = false;

  // አዝራሮቹን በየ 5 ሰከንዱ ለመደብቅ እና ለማሳየት የሚያገለግሉ ተለዋዋጮች
  bool _buttonsVisible = true;
  Timer? _visibilityTimer;
  bool _isUserInteracting = false; // ተጠቃሚው እየተጠቀመባቸው መሆኑን ለመቆጣጠር

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _discController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _initializeVideo();
    _fetchEngagementData();
    _startBlinkingTimer(); // የ 5 ሰከንድ ታይመርን ማስጀመር
  }

  // አዝራሮቹ በየ 5 ሰከንዱ ብቅ እያሉ የሚጠፉበት ታይመር ሎጂክ
  void _startBlinkingTimer() {
    _visibilityTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && !_isUserInteracting) {
        setState(() {
          _buttonsVisible = !_buttonsVisible;
        });
      }
    });
  }

  Future<void> _fetchEngagementData() async {
    try {
      final query = Supabase.instance.client
          .from('videos')
          .select('likes_count, comments_count, shares_count, followers_count, is_following');

      final response = widget.videoId != null
          ? await query.eq('id', widget.videoId!).maybeSingle()
          : await query.eq('video_url', widget.videoUrl).maybeSingle();

      if (response != null && mounted) {
        final bool serverIsFollowing = response['is_following'] ?? false;

        setState(() {
          _likeCount = response['likes_count'] ?? _likeCount;
          _commentCount = response['comments_count'] ?? _commentCount;
          _shareCount = response['shares_count'] ?? _shareCount;
          _followersCount = response['followers_count'] ?? 0;
          _isFollowing = serverIsFollowing;

          // 🛑 አፑ ሲከፈት ሰርቨር ላይ ፎሎ ተደርጎ ከነበረ ፕላሷ ፈጽሞ እንዳይታይ ይደረጋል
          if (serverIsFollowing) {
            _hidePlusSignPermanently = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching engagement data: $e');
    }
  }

  Future<void> _handleFollowPressed() async {
    _keepButtonsVisibleTemporarily();
    final newFollowState = !_isFollowing;
    final newFollowersCount = newFollowState ? _followersCount + 1 : _followersCount - 1;

    setState(() {
      _isFollowing = newFollowState;
      _followersCount = newFollowersCount;
    });

    // 🛑 ፎሎ ሲደረግ ራይት ይሆናል፣ ከ 2 ሰከንድ በኋላ የ (+) ወይም የራይት አዶው በቋሚነት ይጠፋል
    if (newFollowState) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _hidePlusSignPermanently = true;
          });
        }
      });
    }

    try {
      final query = Supabase.instance.client.from('videos');
      if (widget.videoId != null) {
        await query.update({
          'followers_count': newFollowersCount,
          'is_following': newFollowState,
        }).eq('id', widget.videoId!);
      } else {
        await query.update({
          'followers_count': newFollowersCount,
          'is_following': newFollowState,
        }).eq('video_url', widget.videoUrl);
      }
    } catch (e) {
      debugPrint('Failed to update follow status on server: $e');
    }
  }

  Future<void> _handleLikePressed() async {
    _keepButtonsVisibleTemporarily();
    final newLikeState = !_isLiked;
    final newLikeCount = newLikeState ? _likeCount + 1 : _likeCount - 1;

    setState(() {
      _isLiked = newLikeState;
      _likeCount = newLikeCount;
    });

    try {
      final query = Supabase.instance.client.from('videos');
      if (widget.videoId != null) {
        await query.update({'likes_count': newLikeCount}).eq('id', widget.videoId!);
      } else {
        await query.update({'likes_count': newLikeCount}).eq('video_url', widget.videoUrl);
      }
    } catch (e) {
      debugPrint('Failed to update like on server: $e');
    }
  }

  Future<void> _handleSharePressed() async {
    _keepButtonsVisibleTemporarily();
    try {
      await Share.share('Check out this amazing video on kuanyngne: ${widget.videoUrl}');
      final newShareCount = _shareCount + 1;
      
      setState(() {
        _shareCount = newShareCount;
      });

      final query = Supabase.instance.client.from('videos');
      if (widget.videoId != null) {
        await query.update({'shares_count': newShareCount}).eq('id', widget.videoId!);
      } else {
        await query.update({'shares_count': newShareCount}).eq('video_url', widget.videoUrl);
      }
    } catch (e) {
      debugPrint('Error sharing video: $e');
    }
  }

  // ተጠቃሚው አዝራሮቹን ሲነካ እንዲታዩ ማድረግ እና ስራውን እስኪጨርስ እንዳይጠፉ ማቆየት
  void _keepButtonsVisibleTemporarily() {
    setState(() {
      _isUserInteracting = true;
      _buttonsVisible = true;
    });
    // ከጥቂት ሰከንዶች በኋላ ታይመሩ እንደገና እንዲቀጥል ማድረግ
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _isUserInteracting = false;
        });
      }
    });
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
            _discController.repeat();
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
    _visibilityTimer?.cancel(); // ታይመሩን ማቆም
    _discController.dispose();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  void _openComments() {
    _keepButtonsVisibleTemporarily();
    setState(() {
      _isUserInteracting = true; // ኮሜንት ክፍት እያለ አዝራሮቹ እንዳይጠፉ
    });

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
            _commentCount = newCount;
          });
        },
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _isUserInteracting = false; // ኮሜንቱ ሲዘጋ ታይመሩ መደበኛ ስራውን ይቀጥላል
        });
      }
    });
  }

  Future<void> _deleteVideoFromServer() async {
    try {
      final query = Supabase.instance.client.from('videos');
      if (widget.videoId != null) {
        await query.delete().eq('id', widget.videoId!);
      } else {
        await query.delete().eq('video_url', widget.videoUrl);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video deleted successfully')),
        );

        if (widget.onVideoDeleted != null) {
          widget.onVideoDeleted!();
        }
      }
    } catch (e) {
      debugPrint('Error deleting video: $e');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete video.')),
        );
      }
    }
  }

  void _showVideoOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Remove this video from your feed', style: TextStyle(color: Colors.grey)),
                onTap: () {
                  _deleteVideoFromServer();
                },
              ),
            ],
          ),
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
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _isInitialized && _videoController != null
              ? GestureDetector(
                  onTap: () {
                    _togglePlayPause();
                    _keepButtonsVisibleTemporarily(); // ስክሪኑ ሲነካ አዝራሮቹ ብቅ እንዲሉ
                  },
                  onLongPress: _showVideoOptionsBottomSheet,
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
                                  ? Icons.pause
                                  : Icons.play_arrow,
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
                    widget.caption,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // የቀኝ በኩል አዝራሮች (በየ 5 ሰከንዱ ብቅ እያሉ የሚጠፉ እና ተጠቃሚው ሲነካቸው ጸንተው የሚቆዩ)
          Positioned(
            right: 12,
            bottom: 80,
            child: AnimatedOpacity(
              opacity: _buttonsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _handleFollowPressed,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // የፕሮፋይል ክብ (ሁልጊዜ ይታያል)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey,
                            backgroundImage: (widget.userAvatar != null && widget.userAvatar!.isNotEmpty)
                                ? NetworkImage(widget.userAvatar!)
                                : null,
                            child: (widget.userAvatar == null || widget.userAvatar!.isEmpty)
                                ? const Icon(Icons.person, color: Colors.white, size: 26)
                                : null,
                          ),
                        ),
                        // ፕላሷ ወይም ራይቷ (_hidePlusSignPermanently 'true' ከሆነ እስከመጨረሻው ትጠፋለች)
                        if (!_hidePlusSignPermanently)
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

                  Column(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                        onPressed: _openComments,
                      ),
                      Text(
                        '$_commentCount',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  
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
          ),
        ],
      ),
    );
  }
}
