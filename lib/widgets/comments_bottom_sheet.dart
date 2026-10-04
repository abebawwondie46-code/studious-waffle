import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

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
  bool _isSending = false; // ለሚላከው ኮሜንት ሎዲንግ ማሳያ
  String? _replyingToUser;

  // ተጠቃሚው የነካቸውን የላይክ እና ዲስላይክ IDs ለመያዝ (Local State)
  final Set<String> _likedCommentIds = {};
  final Set<String> _dislikedCommentIds = {};

  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchCommentsFromSupabase();
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
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error fetching comments: $e');
    }
  }

  String _formatTimeAgo(String? createdAt) {
    if (createdAt == null) return 'አሁን';
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
      return 'አሁን';
    }
  }

  Future<void> _sendCommentToSupabase({String? text, String? imageUrl}) async {
    if ((text == null || text.trim().isEmpty) && imageUrl == null) return;

    setState(() => _isSending = true); // ሎዲንግ ማሳየት መጀመር

    String finalCommentText = text ?? '';
    if (_replyingToUser != null && text != null) {
      finalCommentText = '$_replyingToUser $text';
    }

    try {
      final newRow = {
        'video_id': widget.videoId,
        'user_name': 'እርስዎ',
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

      final int totalComments = 741 + _comments.length;
      if (widget.onCommentCountUpdated != null) {
        widget.onCommentCountUpdated!(totalComments);
      }

      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint('Error inserting comment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ማስገባት አልተቻለም: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSending = false); // ሎዲንግ ማጥፋት
    }
  }

  // የልብ እና የዲስላይክ ሲጫኑ የሚቀየርበት ዋናሎጂ
  Future<void> _handleLikeDislike(String commentId, int currentLikes, int currentDislikes, bool isLike) async {
    setState(() {
      if (isLike) {
        if (_likedCommentIds.contains(commentId)) {
          _likedCommentIds.remove(commentId);
          currentLikes = currentLikes > 0 ? currentLikes - 1 : 0;
        } else {
          _likedCommentIds.add(commentId);
          currentLikes += 1;
          // ዲስላይክ ተደርጎ ከሆነ ከዚህ በፊት እናነሳዋለን
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
          // ላይክ ተደርጎ ከሆነ ከዚህ በፊት እናነሳዋለን
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
    } catch (e) {
      debugPrint('Error updating like/dislike: $e');
    }
  }

  Future<void> _deleteComment(String commentId, int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('አስተያየትን ሰርዝ', style: TextStyle(color: Colors.white)),
          content: const Text('እርግጠኛ ነዎት ይህን አስተያየት መሰረዝ ይፈልጋሉ?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: const Text('አይ', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('አዎ፣ ሰርዝ', style: TextStyle(color: Colors.redAccent)),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await supabase.from('comments').delete().eq('id', commentId);
                  await _fetchCommentsFromSupabase();

                  final int totalComments = 741 + _comments.length;
                  if (widget.onCommentCountUpdated != null) {
                    widget.onCommentCountUpdated!(totalComments);
                  }
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 160,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.greenAccent),
                title: const Text('ከስልክ ጋለሪ ፎቶ ምረጥ', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.search, color: Colors.greenAccent),
                title: const Text('ከኢንተርኔት ፎቶ ፈልግ (Search Web)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showWebImageSearchDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _sendCommentToSupabase(imageUrl: image.path);
    }
  }

  void _showWebImageSearchDialog() {
    TextEditingController searchController = TextEditingController();
    List<String> searchResults = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> searchImages(String query) async {
              if (query.trim().isEmpty) return;
              setDialogState(() => isSearching = true);
              try {
                final url = Uri.parse('https://unsplash.com/napi/search/photos?query=${Uri.encodeComponent(query)}&per_page=12');
                final response = await http.get(url);
                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);
                  final results = data['results'] as List;
                  setDialogState(() {
                    searchResults = results.map((e) => e['urls']['small'].toString()).toList();
                    isSearching = false;
                  });
                } else {
                  setDialogState(() => isSearching = false);
                }
              } catch (e) {
                setDialogState(() => isSearching = false);
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              title: const Text('ከኢንተርኔት ፎቶ ፈልግ', style: TextStyle(color: Colors.white, fontSize: 16)),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'ምሳሌ፦ heart, nature, tech...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[800],
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: Colors.greenAccent),
                          onPressed: () => searchImages(searchController.text),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (val) => searchImages(val),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: isSearching
                          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                          : searchResults.isEmpty
                              ? const Center(child: Text('ፎቶዎችን ለማግኘት ፈልግ የሚለውን ይጫኑ', style: TextStyle(color: Colors.grey, fontSize: 12)))
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: searchResults.length,
                                  itemBuilder: (context, index) {
                                    return GestureDetector(
                                      onTap: () async {
                                        String selectedUrl = searchResults[index];
                                        Navigator.pop(context);
                                        await _sendCommentToSupabase(imageUrl: selectedUrl);
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(searchResults[index], fit: BoxFit.cover),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onEmojiPressed() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      builder: (context) {
        final List<String> emojis = ['😊', '😂', '❤️', '🔥', '👍', '👏', '😍', '🙏', '✨', '😢', '💡', '🚀'];
        return Container(
          padding: const EdgeInsets.all(16),
          height: 220,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
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
                  child: Text(emojis[index], style: const TextStyle(fontSize: 26)),
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

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int totalCommentCount = 741 + _comments.length;

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
                // የላይኛው መጎተቻ ምልክት (Drag Handle)
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
                  'አስተያየቶች ($totalCommentCount)',
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
                            'ገና ምንም አስተያየት የለም',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final item = _comments[index];
                            final String commentId = item['id'].toString();
                            final String userName = item['user_name'] ?? 'እርስዎ';
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
                                onLongPress: () => _deleteComment(commentId, index),
                                child: Container(
                                  color: Colors.transparent,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.green[800],
                                        child: Text(
                                          userName.isNotEmpty ? userName[0] : 'አ',
                                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
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
                                                      ? Image.network(imageUrl, width: 140, height: 140, fit: BoxFit.cover)
                                                      : Image.file(File(imageUrl), width: 140, height: 140, fit: BoxFit.cover),
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
                                      // የልብ እና ዲስላይክ አዝራሮች ከቁጥር ጋር
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
                // የታችኛው የ ግቤት (Input) ቦታ
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
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.green[800],
                            child: const Text('አ', style: TextStyle(color: Colors.white, fontSize: 10)),
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
                          // የመላኪያ ቁልፍ ከ ሎዲንግ (Spinning) ጋር
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
                            onPressed: _isSending ? null : () => _sendCommentTo_isSending: () => _sendCommentToSupabase(text: _commentController.text),
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
