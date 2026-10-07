import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExploreFeedScreen extends StatefulWidget {
  const ExploreFeedScreen({super.key});

  @override
  State<ExploreFeedScreen> createState() => _ExploreFeedScreenState();
}

class _ExploreFeedScreenState extends State<ExploreFeedScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  final TextEditingController _postCaptionController = TextEditingController();
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;

  bool _showColorPicker = false;
  Color _selectedBackgroundColor = Colors.black87;

  final List<Color> _backgroundColors = [
    Colors.black87,
    Colors.deepPurple.shade900,
    Colors.indigo.shade900,
    Colors.blue.shade900,
    Colors.teal.shade900,
    Colors.green.shade900,
    Colors.brown.shade900,
    Colors.deepOrange.shade900,
    Colors.pink.shade900,
    Colors.purple.shade900,
    Colors.cyan.shade900,
    Colors.amber.shade900,
    Colors.blueGrey.shade900,
    Colors.red.shade900,
    Colors.grey.shade900,
  ];

  @override
  void initState() {
    super.initState();
    _checkInternetAndFetchPosts();
  }

  // የኢንተርኔት ሁኔታን እያረጋገጡ ፖስቶችን ማምጣት
  Future<void> _checkInternetAndFetchPosts() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection! Please check your network.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final response = await supabase
          .from('posts')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _posts = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ፖስትን ከዳታቤዝ የመሰረዝ (Delete) ተግባር
  Future<void> _deletePost(String postId) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection to delete post!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await supabase.from('posts').delete().eq('id', postId);
      setState(() {
        _posts.removeWhere((post) => post['id'].toString() == postId);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _uploadPost() async {
    // የኢንተርኔት ግንኙነት መኖሩን ማረጋገጥ
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection! Cannot publish post.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_postCaptionController.text.trim().isEmpty && _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something or select an image!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      String imageUrl = '';
      if (_selectedImageFile != null) {
        try {
          final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
          final filePath = 'posts/$fileName';

          await supabase.storage.from('videos').upload(
                filePath,
                _selectedImageFile!,
                fileOptions: const FileOptions(upsert: false),
              );

          imageUrl = supabase.storage.from('videos').getPublicUrl(filePath);
        } catch (storageError) {
          debugPrint('Storage error: $storageError');
        }
      }

      final colorValue = _selectedBackgroundColor.value.toRadixString(16);

      await supabase.from('posts').insert({
        'caption': _postCaptionController.text.trim(),
        'media_url': imageUrl,
        'bg_color': colorValue,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posted successfully!'), backgroundColor: Colors.green),
      );

      _postCaptionController.clear();
      setState(() {
        _selectedImageFile = null;
        _selectedBackgroundColor = Colors.black87;
        _showColorPicker = false;
      });

      Navigator.pop(context);
      _checkInternetAndFetchPosts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  void _showCreatePostBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                20,
                16,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create New Post',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    
                    GestureDetector(
                      onTap: () async {
                        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setModalState(() {
                            _selectedImageFile = File(image.path);
                          });
                        }
                      },
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade700),
                        ),
                        child: _selectedImageFile == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded, color: Colors.deepPurpleAccent, size: 36),
                                  SizedBox(height: 6),
                                  Text('Tap to select photo (Optional)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                ],
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.file(_selectedImageFile!, width: double.infinity, height: 140, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          _selectedImageFile = null;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade700),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _postCaptionController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Write a caption or description...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(color: Colors.white24),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _showColorPicker ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                                  color: Colors.deepPurpleAccent,
                                  size: 28,
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    _showColorPicker = !_showColorPicker;
                                  });
                                },
                              ),
                              const Text('^ Style', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),

                          if (_showColorPicker) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _backgroundColors.map((color) {
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      _selectedBackgroundColor = color;
                                    });
                                  },
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _selectedBackgroundColor == color ? Colors.white : Colors.transparent,
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.indigoAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isPosting ? null : _uploadPost,
                        child: _isPosting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Post Now',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Explore Feed & Posters',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent))
          : _posts.isEmpty
              ? const Center(
                  child: Text(
                    'No posts or photos available yet!',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    final postId = post['id']?.toString() ?? '';
                    final caption = post['caption'] ?? '';
                    final mediaUrl = post['media_url'] ?? '';
                    
                    Color postBgColor = Colors.grey.shade900;
                    if (post['bg_color'] != null) {
                      try {
                        postBgColor = Color(int.parse(post['bg_color'], radix: 16));
                      } catch (_) {}
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: postBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade800, width: 0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.deepPurpleAccent,
                                      child: Icon(Icons.person, color: Colors.white, size: 20),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Community Creator',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                // የሰርዝ (Delete) አማራጭ ማኑ (PopupMenuButton)
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                                  color: Colors.grey[850],
                                  onSelected: (value) {
                                    if (value == 'delete' && postId.isNotEmpty) {
                                      _deletePost(postId);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                          SizedBox(width: 8),
                                          Text('Delete Post', style: TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (mediaUrl.isNotEmpty)
                            Container(
                              height: 320,
                              width: double.infinity,
                              color: Colors.black,
                              child: Image.network(
                                mediaUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                                ),
                              ),
                            ),
                          if (caption.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                caption,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: _showCreatePostBottomSheet,
        child: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
      ),
    );
  }
}
