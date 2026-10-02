import 'package:flutter/material.dart';

class VideoActionsWidget extends StatefulWidget {
  final int initialLikeCount;
  final int shareCount;
  final VoidCallback onCommentPressed;
  final VoidCallback onSharePressed;

  const VideoActionsWidget({
    super.key,
    required this.initialLikeCount,
    required this.shareCount,
    required this.onCommentPressed,
    required this.onSharePressed,
  });

  @override
  State<VideoActionsWidget> createState() => _VideoActionsWidgetState();
}

class _VideoActionsWidgetState extends State<VideoActionsWidget> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = false;
    _likeCount = widget.initialLikeCount;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
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
        // ላይክ (Like) አዝራር
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
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        const SizedBox(height: 16),

        // ኮሜንት (Comment) ማሳያ አዝራር (የተለየውን የኮሜንት ፋይል እንዲጠራ የሚያደርግ)
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

        // ሼር (Share) አዝራር
        IconButton(
          icon: const Icon(
            Icons.share,
            color: Colors.white,
            size: 30,
          ),
          onPressed: widget.onSharePressed,
        ),
        Text(
          _formatCount(widget.shareCount),
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}
