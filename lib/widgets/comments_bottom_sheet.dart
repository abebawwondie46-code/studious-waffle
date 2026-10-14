import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String videoId;
  final Function(int)? onCommentCountUpdated;

  const CommentsBottomSheet({
    super.key,
    required this.videoId,
    this.onCommentCountUpdated,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _replyingToUser;
  String? _currentUserAvatar; // የተጠቃሚውን የፕሮፋይል ፎቶ ከ SharedPreferences ለመያዝ

  final Set<String> _likedCommentIds = {};
  final Set<String> _dislikedCommentIds = {};

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _fetchCommentsFromSupabase();
  }

  // ከ SharedPreferences የፕሮፋይል ፎቶን ማንበብ
  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserAvatar = prefs.getString('current_user_avatar');
    });
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.grey[800],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _fetchCommentsFromSupabase() async {
    try {
      final response = await supabase
          .from('comments')
          .select()
          .eq('video_id', widget.videoId)
          .order('created_at', ascending: false);

      setState(() {
        _comments = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      if (widget.onCommentCountUpdated != null) {
        widget.onCommentCountUpdated!(_comments.length);
      }
    } on SocketException {
      setState(() => _isLoading = false);
      _showToast('No internet connection!', isError: true);
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching comments: $e');
    }
  }

  String _formatTimeAgo(String? createdAt) {
    if (createdAt == null) return 'just now';
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      final difference = DateTime.now().difference(dateTime);

      if (difference.inSeconds < 60) {
        return '${difference.inSeconds}s';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    } catch (e) {
      return 'just now';
    }
  }

  Future<void> _sendCommentToSupabase({String? text, String? imageUrl}) async {
    if ((text == null || text.trim().isEmpty) && imageUrl == null) return;

    setState(() => _isSending = true);

    String finalCommentText = text ?? '';
    if (_replyingToUser != null && text != null) {
      finalCommentText = '$_replyingToUser $text';
    }

    try {
      final newRow = {
        'video_id': widget.videoId,
        'user_name': 'You',
        'comment_text': finalCommentText,
        'image_url': imageUrl,
        'likes_count': 0,
        'dislikes_count': 0,
      };

      await supabase.from('comments').insert(newRow);

      _commentController.clear();
      setState(() {
        _replyingToUser = null;
      });

      await _fetchCommentsFromSupabase();
      FocusScope.of(context).unfocus();
    } on SocketException {
      _showToast('No internet connection! Failed to send.', isError: true);
    } catch (e) {
      debugPrint('Error inserting comment: $e');
      _showToast('Failed to insert comment: $e', isError: true);
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _handleLikeDislike(String commentId, int currentLikes, int currentDislikes, bool isLike) async {
    setState(() {
      if (isLike) {
        if (_likedCommentIds.contains(commentId)) {
          _likedCommentIds.remove(commentId);
          currentLikes = currentLikes > 0 ? currentLikes - 1 : 0;
        } else {
          _likedCommentIds.add(commentId);
          currentLikes += 1;
          if (_dislikedCommentIds.contains(commentId)) {
            _dislikedCommentIds.remove(commentId);
            currentDislikes = currentDislikes > 0 ? currentDislikes - 1 : 0;
          }
        }
      } else {
        if (_dislikedCommentIds.contains(commentId)) {
          _dislikedCommentIds.remove(commentId);
          currentDislikes = currentDislikes > 0 ? currentDislikes - 1 : 0;
        } else {
          _dislikedCommentIds.add(commentId);
          currentDislikes += 1;
          if (_likedCommentIds.contains(commentId)) {
            _likedCommentIds.remove(commentId);
            currentLikes = currentLikes > 0 ? currentLikes - 1 : 0;
          }
        }
      }
    });

    try {
      await supabase.from('comments').update({
        'likes_count': currentLikes,
        'dislikes_count': currentDislikes,
      }).eq('id', commentId);
    } on SocketException {
      _showToast('No internet connection!', isError: true);
    } catch (e) {
      debugPrint('Error updating like/dislike: $e');
    }
  }

  Future<void> _deleteComment(String commentId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('Delete Comment', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to delete this comment?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await supabase.from('comments').delete().eq('id', commentId);
                  await _fetchCommentsFromSupabase();
                } on SocketException {
                  _showToast('No internet connection!', isError: true);
                } catch (e) {
                  debugPrint('Error deleting comment: $e');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _onImagePickPressed() {
    _pickAndUploadFromGallery();
  }

  Future<void> _pickAndUploadFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _sendCommentToSupabase(imageUrl: image.path);
    }
  }

  void _onEmojiPressed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      builder: (context) {
        final List<String> emojis = ['😊', '😂', '❤️', '🔥', '👍', '👏', '😍', '🙏', '✨', '😢', '💡', '🚀', '😎', '🥳', '💯'];
        return Container(
          padding: const EdgeInsets.all(16),
          height: 220,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: emojis.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _commentController.text += emojis[index];
                  });
                  Navigator.pop(context);
                },
                child: Center(
                  child: Text(emojis[index], style: const TextStyle(fontSize: 28)),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _onMentionPressed() {
    setState(() {
      _commentController.text += '@';
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
    FocusScope.of(context).requestFocus(_commentFocusNode);
  }

  void _onReplyPressed(String userName) {
    setState(() {
      _replyingToUser = '@$userName';
    });
    FocusScope.of(context).requestFocus(_commentFocusNode);
  }

  // ፕሮፋይል ፎቶዎችን ከኔትወርክ ወይም ከስልክ ፋይል በአግባቡ አጣርቶ የሚያሳይ ዊጅት
  Widget _buildAvatar(String? avatarUrl, String fallbackLetter, {double radius = 16}) {
    ImageProvider? imageProvider;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
        imageProvider = NetworkImage(avatarUrl);
      } else if (File(avatarUrl).existsSync()) {
        imageProvider = FileImage(File(avatarUrl));
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.green[800],
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              fallbackLetter,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.75,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Comments (${_comments.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(color: Colors.white12, height: 16),
                Expanded(
                  child: _comments.isEmpty
                      ? const Center(
                          child: Text(
                            'No comments yet',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final item = _comments[index];
                            final String commentId = item['id'].toString();
                            final String userName = item['user_name'] ?? 'You';
                            final String commentText = item['comment_text'] ?? '';
                            final String? imageUrl = item['image_url'];
                            final int likesCount = item['likes_count'] ?? 0;
                            final int dislikesCount = item['dislikes_count'] ?? 0;
                            final String timeAgo = _formatTimeAgo(item['created_at']);

                            final bool isLiked = _likedCommentIds.contains(commentId);
                            final bool isDisliked = _dislikedCommentIds.contains(commentId);

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: GestureDetector(
                                onLongPress: () => _deleteComment(commentId),
                                child: Container(
                                  color: Colors.transparent,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // የጻፈው ሰው ፕሮፋይል ፎቶ (እርስዎ ከሆኑ _currentUserAvatar ያሳያል)
                                      _buildAvatar(
                                        userName == 'You' ? _currentUserAvatar : null,
                                        userName.isNotEmpty ? userName[0] : 'U',
                                        radius: 16,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              userName,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            if (imageUrl != null && imageUrl.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4, bottom: 4),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: imageUrl.startsWith('http')
                                                      ? Image.network(imageUrl, width: 150, height: 150, fit: BoxFit.cover)
                                                      : Image.file(File(imageUrl), width: 150, height: 150, fit: BoxFit.cover),
                                                ),
                                              )
                                            else
                                              Text(
                                                commentText,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                                const SizedBox(width: 12),
                                                GestureDetector(
                                                  onTap: () => _onReplyPressed(userName),
                                                  child: const Text(
                                                    'Reply',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => _handleLikeDislike(commentId, likesCount, dislikesCount, true),
                                            child: Padding(
                                              padding: const EdgeInsets.all(2.0),
                                              child: Icon(
                                                isLiked ? Icons.favorite : Icons.favorite_border,
                                                color: isLiked ? Colors.redAccent : Colors.grey,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                          Text('$likesCount', style: TextStyle(color: isLiked ? Colors.redAccent : Colors.grey, fontSize: 10)),
                                          const SizedBox(height: 6),
                                          InkWell(
                                            onTap: () => _handleLikeDislike(commentId, likesCount, dislikesCount, false),
                                            child: Padding(
                                              padding: const EdgeInsets.all(2.0),
                                              child: Icon(
                                                isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                                                color: isDisliked ? Colors.redAccent : Colors.grey,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                          Text('$dislikesCount', style: TextStyle(color: isDisliked ? Colors.redAccent : Colors.grey, fontSize: 10)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 6,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 6,
                  ),
                  color: const Color(0xFF101010),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_replyingToUser != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Replying to $_replyingToUser',
                                style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _replyingToUser = null),
                                child: const Icon(Icons.close, color: Colors.grey, size: 14),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          // የኮሜንት መጻፊያው አጠገብ ያለው የእርስዎ ፕሮፋይል ፎቶ (የቀድሞው U ቦታ)
                          _buildAvatar(
                            _currentUserAvatar,
                            'U',
                            radius: 14,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              focusNode: _commentFocusNode,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: _replyingToUser != null ? 'Add reply...' : 'Add comment...',
                                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                                filled: true,
                                fillColor: Colors.grey[850],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (val) => _sendCommentToSupabase(text: val),
                            ),
                          ),
                          const SizedBox(width: 2),
                          IconButton(
                            icon: const Icon(Icons.image_outlined, color: Colors.grey, size: 20),
                            onPressed: _onImagePickPressed,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                          IconButton(
                            icon: const Icon(Icons.sentiment_satisfied_outlined, color: Colors.grey, size: 20),
                            onPressed: _onEmojiPressed,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                          IconButton(
                            icon: const Icon(Icons.alternate_email, color: Colors.grey, size: 20),
                            onPressed: _onMentionPressed,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                          IconButton(
                            icon: _isSending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.greenAccent,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.send, color: Colors.greenAccent, size: 20),
                            onPressed: _isSending ? null : () => _sendCommentToSupabase(text: _commentController.text),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
