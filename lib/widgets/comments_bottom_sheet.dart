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
  String? _replyingToUser;

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
        return '${difference.inSeconds}s ago';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'አሁን';
    }
  }

  Future<void> _sendCommentToSupabase({String? text, String? imageUrl}) async {
    if ((text == null || text.trim().isEmpty) && imageUrl == null) return;

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
    }
  }

  Future<void> _updateLikeDislike(String commentId, int currentLikes, int currentDislikes, bool isLike) async {
    try {
      final updatedData = isLike
          ? {'likes_count': currentLikes + 1}
          : {'dislikes_count': currentDislikes + 1};

      await supabase.from('comments').update(updatedData).eq('id', commentId);
      await _fetchCommentsFromSupabase();
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
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 150,
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
                        hintText: 'ምሳሌ፦ heart, head, hand...',
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
        final List<String> emojis = ['😊', '😂', '❤️', '🔥', '👍', '👏', '😍', '🙏', '✨', '😢'];
        return Container(
          padding: const EdgeInsets.all(16),
          height: 200,
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
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'አስተያየቶች ($totalCommentCount)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(color: Colors.white24),
                Expanded(
                  child: _comments.isEmpty
                      ? const Center(
                          child: Text(
                            'ገና ምንም አስተያየት የለም',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: GestureDetector(
                                onLongPress: () => _deleteComment(commentId, index),
                                child: Container(
                                  color: Colors.transparent,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.green[800],
                                        child: Text(
                                          userName.isNotEmpty ? userName[0] : 'አ',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userName,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
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
                                                  fontSize: 14,
                                                ),
                                              ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Text(timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                                const SizedBox(width: 16),
                                                GestureDetector(
                                                  onTap: () => _onReplyPressed(userName),
                                                  child: const Text(
                                                    'Reply',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.favorite_border, color: Colors.grey, size: 20),
                                            onPressed: () => _updateLikeDislike(commentId, likesCount, dislikesCount, true),
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                          const SizedBox(height: 2),
                                          Text('$likesCount', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                          const SizedBox(height: 10),
                                          IconButton(
                                            icon: const Icon(Icons.thumb_down_outlined, color: Colors.grey, size: 20),
                                            onPressed: () => _updateLikeDislike(commentId, likesCount, dislikesCount, false),
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                          ),
                                          const SizedBox(height: 2),
                                          Text('$dislikesCount', style: const TextStyle(color: Colors.grey, fontSize: 11)),
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
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                  ),
                  color: Colors.black54,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_replyingToUser != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Replying to $_replyingToUser',
                                style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _replyingToUser = null),
                                child: const Icon(Icons.close, color: Colors.grey, size: 16),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.green[800],
                            child: const Text('አ', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              focusNode: _commentFocusNode,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: _replyingToUser != null ? 'Add reply...' : 'Add comment...',
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[850],
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (val) => _sendCommentToSupabase(text: val),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.image_outlined, color: Colors.grey),
                            onPressed: _onImagePickPressed,
                          ),
                          IconButton(
                            icon: const Icon(Icons.sentiment_satisfied_outlined, color: Colors.grey),
                            onPressed: _onEmojiPressed,
                          ),
                          IconButton(
                            icon: const Icon(Icons.alternate_email, color: Colors.grey),
                            onPressed: _onMentionPressed,
                          ),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.greenAccent),
                            onPressed: () => _sendCommentToSupabase(text: _commentController.text),
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
