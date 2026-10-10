import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VideoActionsWidget extends StatefulWidget {
  final String? videoId;
  final String videoUrl;
  final int initialLikeCount;
  final int shareCount;
  final int initialFollowersCount;
  final bool initialIsFollowing;
  final String? userAvatar;
  final VoidCallback onCommentPressed;
  final VoidCallback onSharePressed;

  const VideoActionsWidget({
    super.key,
    this.videoId,
    required this.videoUrl,
    required this.initialLikeCount,
    required this.shareCount,
    required this.initialFollowersCount,
    required this.initialIsFollowing,
    this.userAvatar,
    required this.onCommentPressed,
    required this.onSharePressed,
  });

  @override
  State<VideoActionsWidget> createState() => _VideoActionsWidgetState();
}

class _VideoActionsWidgetState extends State<VideoActionsWidget> {
  late bool _isLiked;
  late int _likeCount;
  late bool _isFollowing;
  late int _followersCount;

  @override
  void initState() {
    super.initState();
    _isLiked = false;
    _likeCount = widget.initialLikeCount;
    _isFollowing = widget.initialIsFollowing;
    _followersCount = widget.initialFollowersCount;
  }

  // ፎሎ ሲደረግ (+) ጠፍቶ ራይት (Check) እንዲሆን እና ሰርቨር ላይ እንዲመዘገብ
  Future<void> _handleFollowPressed() async {
    final newFollowState = !_isFollowing;
    final newFollowersCount = newFollowState ? _followersCount + 1 : _followersCount - 1;

    setState(() {
      _isFollowing = newFollowState;
      _followersCount = newFollowersCount;
    });

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
      debugPrint('Failed to update follow status: $e');
    }
  }

  Future<void> _toggleLike() async {
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
      debugPrint('Failed to update like: $e');
    }
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ፎሎው አዝራር (የ (+) ምልክት እና ራይት መቆጣጠሪያ)
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

        // ላይክ አዝራር
        IconButton(
          icon: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: _isLiked ? Colors.redAccent : Colors.white,
            size: 32,
          ),
          onPressed: _toggleLike,
        ),
        Text(
          _formatCount(_likeCount),
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // ኮሜንት አዝራር
        IconButton(
          icon: const Icon(
            Icons.mode_comment_outlined,
            color: Colors.white,
            size: 30,
          ),
          onPressed: widget.onCommentPressed,
        ),
        const Text(
          'ኮሜንት',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 16),

        // ሼር አዝራር
        IconButton(
          icon: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(3.14159),
            child: const Icon(Icons.share, color: Colors.white, size: 30),
          ),
          onPressed: widget.onSharePressed,
        ),
        Text(
          _formatCount(widget.shareCount),
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
