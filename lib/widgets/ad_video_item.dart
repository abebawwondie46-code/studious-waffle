import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'comments_bottom_sheet.dart';
import 'package:kuanyngne/Chat/secret_chat_screen.dart';

class AdVideoItem extends StatefulWidget {
  final String caption;
  final String videoUrl;
  final Map<String, dynamic> templateJson;
  final String? videoId;
  final VoidCallback? onVideoDeleted;
  final String? userAvatar; 
  final String? userName;    
  final String? creatorId;

  const AdVideoItem({
    super.key,
    required this.caption,
    required this.videoUrl,
    required this.templateJson,
    this.videoId,
    this.onVideoDeleted,
    this.userAvatar,
    this.userName,
    this.creatorId,
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
  
  bool _hidePlusSignPermanently = false;
  bool _buttonsVisible = true;
  Timer? _visibilityTimer;
  bool _isUserInteracting = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _discController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    _loadVideoSpecificData();
    _startSmartTimer();
  }

  void _startSmartTimer() {
    _visibilityTimer?.cancel();
    _visibilityTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isUserInteracting) {
        setState(() {
          _buttonsVisible = false;
        });
        _startHiddenTimer();
      }
    });
  }

  void _startHiddenTimer() {
    _visibilityTimer?.cancel();
    _visibilityTimer = Timer(const Duration(seconds: 19), () {
      if (mounted && !_isUserInteracting) {
        setState(() {
          _buttonsVisible = true;
        });
        _startSmartTimer();
      }
    });
  }

  void _keepButtonsVisibleTemporarily() {
    _visibilityTimer?.cancel();
    setState(() {
      _isUserInteracting = true;
      _buttonsVisible = true;
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isUserInteracting = false;
        });
        _startSmartTimer();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AdVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId || oldWidget.videoUrl != widget.videoUrl) {
      _loadVideoSpecificData();
    }
  }

  // 🛑 ሰርቨር ዳታ እንዳይጠይቅ ሙሉ በሙሉ ታግዷል (ዳታ ዜሮ ነው)
  Future<void> _loadVideoSpecificData() async {
    setState(() {
      _isFollowing = false;
      _hidePlusSignPermanently = false;
    });

    final prefs = await SharedPreferences.getInstance();
    final creatorKey = widget.userName ?? widget.userAvatar ?? 'creator_unknown';
    final uniqueKey = 'followed_creator_$creatorKey';
    final isLocallyFollowed = prefs.getBool(uniqueKey) ?? false;

    if (isLocallyFollowed && mounted) {
      setState(() {
        _isFollowing = true;
        _hidePlusSignPermanently = true;
      });
    }

    // ከሰርቨር የሚደረግ ዳታ ጥያቄ ጠፍቷል: await _fetchEngagementData();
  }

  // 🌟 (+) ወይም የፕሮፋይል አዝራሩ ሲነካ ወደ ቻት የሚወስድበት ትክክለኛ ኮድ
  Future<void> _handleFollowPressed() async {
    _keepButtonsVisibleTemporarily();

    String resolvedName = widget.userName ?? 'ተጠቃሚ';
    String? resolvedAvatar = widget.userAvatar;
    String resolvedId = widget.creatorId ?? '';

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SecretChatScreen(
            receiverId: resolvedId,
            receiverName: resolvedName,
            receiverAvatarUrl: resolvedAvatar,
          ),
        ),
      );
    }
    
    final newFollowState = !_isFollowing;
    final newFollowersCount = newFollowState ? _followersCount + 1 : _followersCount - 1;

    setState(() {
      _isFollowing = newFollowState;
      _followersCount = newFollowersCount;
      _hidePlusSignPermanently = newFollowState; 
    });
    
    final prefs = await SharedPreferences.getInstance();
    final creatorKey = widget.userName ?? widget.userAvatar ?? 'creator_unknown';
    final uniqueKey = 'followed_creator_$creatorKey';
    await prefs.setBool(uniqueKey, newFollowState);
  }

  Future<void> _handleLikePressed() async {
    _keepButtonsVisibleTemporarily();
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });
  }

  Future<void> _handleSharePressed() async {
    _keepButtonsVisibleTemporarily();
    try {
      await Share.share('Check out this amazing chat app: ${widget.videoUrl}');
      setState(() {
        _shareCount = _shareCount + 1;
      });
    } catch (e) {
      debugPrint('Error sharing: $e');
    }
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  void dispose() {
    _visibilityTimer?.cancel();
    _discController.dispose();
    super.dispose();
  }

  void _openComments() {
    _keepButtonsVisibleTemporarily();
    setState(() {
      _isUserInteracting = true;
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
          _isUserInteracting = false;
          _startSmartTimer();
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
          // 🛑 ቪዲዮው ሲዘጋ ገጹ ልሙጥ ሆኖ ዳራው ብቻ እንዲቀመጥ ተደርጓል (ሰርቨር 100% ነፃ ነው)
          Container(
            color: Colors.black,
            child: const Center(
              child: Text(
                "",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),
      
          // 🔒 የቪዲዮ መግለጫ (Caption) እና ከግራ በኩል ከታች የተተከለው በአሻራ የሚከፈት የቻት አዝራር
          Positioned(
            left: 0,
            right: 70,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
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
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SecretChatScreen(
                            receiverId: widget.creatorId ?? 'unknown_id',
                            receiverName: widget.userName ?? 'ተጠቃሚ',
                            receiverAvatarUrl: widget.userAvatar,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blueAccent, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.fingerprint,
                        color: Colors.blueAccent,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 👤 የቀኝ በኩል የፕሮፋይል ፎቶ እና ሌሎች አዝራሮች
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
                  const SizedBox(height: 8),

                  IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      color: _isLiked ? Colors.redAccent : Colors.white,
                      size: 32,
                    ),
                    onPressed: _handleLikePressed,
                  ),
                  Text(
                    _formatCount(_likeCount),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: _openComments,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.pinkAccent, Colors.purpleAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.forum_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCount(_commentCount),
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  IconButton(
                    icon: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(3.14159),
                      child: const Icon(Icons.reply, color: Colors.white, size: 30),
                    ),
                    onPressed: _handleSharePressed,
                  ),
                  Text(
                    _formatCount(_shareCount),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
