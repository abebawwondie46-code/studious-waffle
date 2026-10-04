import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http; // ለኢንተርኔት ፍለጋ (Unsplash API ለመጠቀም)

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

  @override
  void initState() {
    super.initState();
    _loadSavedComments();
  }

  Future<void> _loadSavedComments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('comments_${widget.videoId}');

    if (savedData != null) {
      final List decodedList = jsonDecode(savedData);
      setState(() {
        _comments = decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _comments = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCommentsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_comments);
    await prefs.setString('comments_${widget.videoId}', encodedData);
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    String commentText = _commentController.text.trim();
    if (_replyingToUser != null) {
      commentText = '$_replyingToUser $commentText';
    }

    setState(() {
      _comments.insert(0, {
        'name': 'እርስዎ',
        'comment': commentText,
        'imagePath': null,
        'imageUrl': null,
        'time': '2s ago',
        'likes': 0,
        'isLiked': false,
        'isDisliked': false,
      });
      _commentController.clear();
      _replyingToUser = null;
    });

    await _saveCommentsToPrefs();

    final int totalComments = 741 + _comments.length;
    if (widget.onCommentCountUpdated != null) {
      widget.onCommentCountUpdated!(totalComments);
    }
    
    FocusScope.of(context).unfocus();
  }

  void _toggleLike(int index) {
    setState(() {
      final comment = _comments[index];
      bool isLiked = comment['isLiked'] ?? false;
      int likes = comment['likes'] ?? 0;

      if (isLiked) {
        comment['isLiked'] = false;
        comment['likes'] = likes - 1;
      } else {
        comment['isLiked'] = true;
        comment['likes'] = likes + 1;
        if (comment['isDisliked'] == true) {
          comment['isDisliked'] = false;
        }
      }
    });
    _saveCommentsToPrefs();
  }

  void _toggleDislike(int index) {
    setState(() {
      final comment = _comments[index];
      bool isDisliked = comment['isDisliked'] ?? false;

      if (isDisliked) {
        comment['isDisliked'] = false;
      } else {
        comment['isDisliked'] = true;
        if (comment['isLiked'] == true) {
          comment['isLiked'] = false;
          comment['likes'] = (comment['likes'] ?? 1) - 1;
        }
      }
    });
    _saveCommentsToPrefs();
  }

  void _deleteComment(int index) {
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
                setState(() {
                  _comments.removeAt(index);
                });
                
                await _saveCommentsToPrefs();

                final int totalComments = 741 + _comments.length;
                if (widget.onCommentCountUpdated != null) {
                  widget.onCommentCountUpdated!(totalComments);
                }
                
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // የፎቶ አዶ ሲጫን: ከጋለሪ ወይም ከኢንተርኔት የመምረጫ አማራጭ ማሳየት
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
                  _pickFromGallery();
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

  // ከጋለሪ የመረጠውን መጫን
  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _comments.insert(0, {
          'name': 'እርስዎ',
          'comment': '',
          'imagePath': image.path,
          'imageUrl': null,
          'time': '2s ago',
          'likes': 0,
          'isLiked': false,
          'isDisliked': false,
        });
      });
      await _saveCommentsToPrefs();
      if (widget.onCommentCountUpdated != null) {
        widget.onCommentCountUpdated!(741 + _comments.length);
      }
    }
  }

  // ከኢንተርኔት ፎቶ ለመፈለግ የሚረዳ ፕላትፎርም/ዲያሎግ
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
                // የልብ፣ የሰው ጭንቅላት ወይም ሌላ ኪይዎርድ በUnsplash API ወይም በነፃ ፑብሊክ አፒአይ መፈለግ
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
                // በኔትወርክ ችግር ጊዜ የሚታዩ ነባሪ ናሙና ፎቶዎች (Fallback Images)
                setDialogState(() {
                  searchResults = [
                    'https://images.unsplash.com/photo-1518791841217-8f162f1e1131',
                    'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
                  ];
                  isSearching = false;
                });
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
                        hintText: 'ምሳሌ፦ heart, head, hand, smile...',
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
                                        Navigator.pop(context); // የሰርች ሳጥኑን ዝጋ
                                        
                                        // የተመረጠውን የኢንተርኔት ፎቶ ወደ ኮሜንት ጨምር
                                        setState(() {
                                          _comments.insert(0, {
                                            'name': 'እርስዎ',
                                            'comment': '',
                                            'imagePath': null,
                                            'imageUrl': selectedUrl,
                                            'time': '2s ago',
                                            'likes': 0,
                                            'isLiked': false,
                                            'isDisliked': false,
                                          });
                                        });
                                        await _saveCommentsToPrefs();
                                        if (widget.onCommentCountUpdated != null) {
                                          widget.onCommentCountUpdated!(741 + _comments.length);
                                        }
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          searchResults[index],
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent));
                                          },
                                        ),
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
                  child: Text(
                    emojis[index],
                    style: const TextStyle(fontSize: 28),
                  ),
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
                            final bool isLiked = item['isLiked'] ?? false;
                            final bool isDisliked = item['isDisliked'] ?? false;
                            final int likesCount = item['likes'] ?? 0;
                            final String userName = item['name'];
                            final String? imagePath = item['imagePath'];
                            final String? imageUrl = item['imageUrl'];
                            final String commentText = item['comment'] ?? '';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: GestureDetector(
                                onLongPress: () => _deleteComment(index),
                                child: Container(
                                  color: Colors.transparent,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.green[800],
                                        child: Text(
                                          userName[0],
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
                                            // ከጋለሪ የተመረጠ ፎቶ ከሆነ
                                            if (imagePath != null && imagePath.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4, bottom: 4),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.file(
                                                    File(imagePath),
                                                    width: 150,
                                                    height: 150,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              )
                                            // ከኢንተርኔት የተመረጠ ፎቶ ከሆነ
                                            else if (imageUrl != null && imageUrl.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4, bottom: 4),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    imageUrl,
                                                    width: 150,
                                                    height: 150,
                                                    fit: BoxFit.cover,
                                                  ),
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
                                                Text(
                                                  item['time'],
                                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                ),
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
                                          GestureDetector(
                                            onTap: () => _toggleLike(index),
                                            child: Icon(
                                              isLiked ? Icons.favorite : Icons.favorite_border,
                                              color: isLiked ? Colors.redAccent : Colors.grey,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text('$likesCount', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                                          const SizedBox(height: 10),
                                          GestureDetector(
                                            onTap: () => _toggleDislike(index),
                                            child: Icon(
                                              isDisliked ? Icons.thumb_down : Icons.thumb_down_off_alt,
                                              color: isDisliked ? Colors.redAccent : Colors.grey,
                                              size: 18,
                                            ),
                                          ),
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
                              onSubmitted: (_) => _addComment(),
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
                            onPressed: _addComment,
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
