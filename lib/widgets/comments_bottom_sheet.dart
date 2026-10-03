import 'dart:convert';
import 'package:flutter/material.dart';
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
  List<Map<String, String>> _comments = [];
  bool _isLoading = true;

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
        _comments = decodedList.map((item) => Map<String, String>.from(item)).toList();
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
    
    setState(() {
      _comments.insert(0, {
        'name': 'እርስዎ',
        'comment': _commentController.text.trim(),
        'time': 'አሁን',
      });
      _commentController.clear();
    });

    await _saveCommentsToPrefs();

    final int totalComments = 741 + _comments.length;
    if (widget.onCommentCountUpdated != null) {
      widget.onCommentCountUpdated!(totalComments);
    }
    
    FocusScope.of(context).unfocus();
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

  @override
  void dispose() {
    _commentController.dispose();
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
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: GestureDetector(
                                onLongPress: () => _deleteComment(index),
                                child: Container(
                                  color: Colors.transparent,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // የፕሮፋይል ቼክል ፎቶ/አክታር
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: Colors.green[800],
                                        child: Text(
                                          item['name']![0],
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // የኮሜንቱ ዝርዝር አቀማመጥ (እንደ ቲክቶክ)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // 1. የተጠቃሚው ስም
                                            Text(
                                              item['name']!,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            // 2. የኮሜንቱ ጽሁፍ
                                            Text(
                                              item['comment']!,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            // 3. ሰዓት እና ሪፕላይ (Reply) በግራ በኩል
                                            Row(
                                              children: [
                                                Text(
                                                  item['time']!,
                                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                                ),
                                                const SizedBox(width: 16),
                                                const Text(
                                                  'Reply',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // 4. በስተቀኝ በኩል የሚቀመጡ የላይክ እና የዲስላይክ አዶዎች (እንደ ቲክቶክ)
                                      Column(
                                        children: [
                                          const Icon(Icons.favorite_border, color: Colors.grey, size: 20),
                                          const SizedBox(height: 2),
                                          const Text('0', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                          const SizedBox(height: 10),
                                          const Icon(Icons.thumb_down_off_alt, color: Colors.grey, size: 18),
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
                // የታችኛው የ ግብዓት (Input) ሣጥን
                Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                  ),
                  color: Colors.black54,
                  child: Row(
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
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Add comment...',
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
                      const SizedBox(width: 8),
                      const Icon(Icons.image_outlined, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Icon(Icons.sentiment_satisfied_outlined, color: Colors.grey),
                      const SizedBox(width: 8),
                      const Icon(Icons.alternate_email, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
