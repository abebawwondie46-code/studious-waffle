import 'dart:io';
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

  String _userName = 'Community Creator';
  String? _userAvatarUrl;

  final TextEditingController _postCaptionController = TextEditingController();
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;

  bool _showColorPicker = false;
  Color _selectedBackgroundColor = const Color(0xFF1A1A2E);

  final List<Color> _backgroundColors = [
    const Color(0xFF1A1A2E),
    const Color(0xFF16213E),
    const Color(0xFF0F3460),
    const Color(0xFF533483),
    const Color(0xFFE94560),
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
    Colors.black87,
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfileAndPosts();
  }

  void _showNoInternetToast() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No internet connection! Please check your network.'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _fetchUserProfileAndPosts() async {
    try {
      try {
        final profileData = await supabase
            .from('profiles')
            .select('full_name, avatar_url')
            .maybeSingle();

        if (profileData != null) {
          setState(() {
            _userName = profileData['full_name'] ?? 'Community Creator';
            _userAvatarUrl = profileData['avatar_url'];
          });
        }
      } catch (_) {}

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
      _showNoInternetToast();
    }
  }

  Future<void> _deletePost(String postId) async {
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showNoInternetToast();
    }
  }

  Future<void> _uploadPost() async {
    if (_postCaptionController.text.trim().isEmpty && _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something or select an image!'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
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
        const SnackBar(
          content: Text('Posted successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _postCaptionController.clear();
      setState(() {
        _selectedImageFile = null;
        _selectedBackgroundColor = const Color(0xFF1A1A2E);
        _showColorPicker = false;
      });

      Navigator.pop(context);
      _fetchUserProfileAndPosts();
    } catch (e) {
      _showNoInternetToast();
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
      backgroundColor: const Color(0xFF121214),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                24,
                16,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create New Post',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
                        height: 130,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F23),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: _selectedImageFile == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded, color: Colors.indigoAccent, size: 34),
                                  SizedBox(height: 6),
                                  Text('Tap to select photo (Optional)', style: TextStyle(color: Colors.white54, fontSize: 13)),
                                ],
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(_selectedImageFile!, width: double.infinity, height: 130, fit: BoxFit.cover),
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

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _postCaptionController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'Write a caption or description...',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(color: Colors.white12),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _showColorPicker ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                                  color: Colors.indigoAccent,
                                  size: 26,
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    _showColorPicker = !_showColorPicker;
                                  });
                                },
                              ),
                              const Text('^ Style', style: TextStyle(color: Colors.white38, fontSize: 12)),
                            ],
                          ),

                          if (_showColorPicker) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _backgroundColors.map((color) {
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      _selectedBackgroundColor = color;
                                    });
                                  },
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _selectedBackgroundColor == color ? Colors.white : Colors.transparent,
                                        width: 2,
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
                          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2575FC).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  void _openZoomableImage(String imageUrl, String tag) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        pageBuilder: (BuildContext context, _, __) {
          return Scaffold(
            backgroundColor: Colors.black.withOpacity(0.92),
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: Hero(
                      tag: tag,
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0C),
        elevation: 0,
        title: const Text(
          'Explore Feed & Posters',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2575FC)))
          : RefreshIndicator(
              onRefresh: _fetchUserProfileAndPosts,
              color: const Color(0xFF2575FC),
              backgroundColor: const Color(0xFF1F1F23),
              child: _posts.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 200),
                        Center(
                          child: Text(
                            'No posts or photos available yet!',
                            style: TextStyle(color: Colors.white38, fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        final postId = post['id']?.toString() ?? '';
                        final caption = post['caption'] ?? '';
                        final mediaUrl = post['media_url'] ?? '';
                        final heroTag = 'post_image_${postId}_$index';
                        
                        Color postBgColor = const Color(0xFF1A1A2E);
                        if (post['bg_color'] != null) {
                          try {
                            postBgColor = Color(int.parse(post['bg_color'], radix: 16));
                          } catch (_) {}
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. User Profile Header
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: const Color(0xFF2575FC),
                                          backgroundImage: (_userAvatarUrl != null && _userAvatarUrl!.isNotEmpty)
                                              ? NetworkImage(_userAvatarUrl!)
                                              : null,
                                          child: (_userAvatarUrl == null || _userAvatarUrl!.isEmpty)
                                              ? const Icon(Icons.person, color: Colors.white, size: 20)
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _userName,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ],
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                                      color: const Color(0xFF1F1F23),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

                              // 2. Caption Above Photo (If present)
                              if (caption.isNotEmpty && mediaUrl.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                                  child: Text(
                                    caption,
                                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
                                  ),
                                ),

                              // 3. Clean Single Image/Poster View
                              if (mediaUrl.isNotEmpty)
                                GestureDetector(
                                  onTap: () => _openZoomableImage(mediaUrl, heroTag),
                                  child: Hero(
                                    tag: heroTag,
                                    child: Container(
                                      width: double.infinity,
                                      constraints: const BoxConstraints(
                                        maxHeight: 480,
                                      ),
                                      color: Colors.black,
                                      child: Image.network(
                                        mediaUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => const SizedBox(
                                          height: 200,
                                          child: Center(
                                            child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                // Text Poster Card
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.symmetric(horizontal: 12),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: postBgColor,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    caption,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4, fontWeight: FontWeight.w500),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2575FC),
        onPressed: _showCreatePostBottomSheet,
        child: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
      ),
    );
  }
}
