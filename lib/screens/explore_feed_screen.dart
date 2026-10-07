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

  final TextEditingController _postCaptionController = TextEditingController();
  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;

  // የጀርባ ቀለሞችን መምረጫ እና መደበቂያ ሁኔታዎች
  bool _showColorPicker = false;
  Color _selectedBackgroundColor = Colors.black87;

  // በጣም የሚያምሩ የጀርባ ቀለሞች ዝርዝር
  final List<Color> _backgroundColors = [
    Colors.black87,
    Colors.deepPurple.shade900,
    Colors.indigo.shade900,
    Colors.teal.shade900,
    Colors.brown.shade900,
    Colors.pink.shade900,
    Colors.orange.shade900,
    Colors.blueGrey.shade900,
    Colors.red.shade900,
  ];

  @override
  void initState() {
    super.initState();
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

  Future<void> _uploadPost() async {
    setState(() {
      _isPosting = true;
    });

    try {
      String imageUrl = '';
      if (_selectedImageFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = 'posts/$fileName';

        await supabase.storage.from('videos').upload(
              filePath,
              _selectedImageFile!,
              fileOptions: const FileOptions(upsert: false),
            );

        imageUrl = supabase.storage.from('videos').getPublicUrl(filePath);
      }

      await supabase.from('posts').insert({
        'caption': _postCaptionController.text.trim(),
        'media_url': imageUrl,
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
      _fetchPosts();
    } catch (e) {
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
                    
                    // Image Picker Box
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
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade700),
                        ),
                        child: _selectedImageFile == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_rounded, color: Colors.redAccent, size: 40),
                                  SizedBox(height: 6),
                                  Text('Tap to select photo (Optional)', style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(_selectedImageFile!, fit: BoxFit.cover),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Caption Input with Background Color Container
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
                          
                          // (^) ምልክት እና የቀለም መምረጫ ቁልፍ
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _showColorPicker ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                                  color: Colors.redAccent,
                                  size: 28,
                                ),
                                tooltip: 'Choose Background Color',
                                onPressed: () {
                                  setModalState(() {
                                    _showColorPicker = !_showColorPicker;
                                  });
                                },
                              ),
                              const Text('^ Style', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),

                          // (^) ምልክት ሲነካ የሚታዩ የሚያምሩ የጀርባ ቀለሞች
                          if (_showColorPicker) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 45,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _backgroundColors.length,
                                itemBuilder: (context, index) {
                                  final color = _backgroundColors[index];
                                  return GestureDetector(
                                    onTap: () {
                                      setModalState(() {
                                        _selectedBackgroundColor = color;
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: 40,
                                      height: 40,
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
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isPosting ? null : _uploadPost,
                      child: _isPosting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Post Now', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
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
                    final caption = post['caption'] ?? '';
                    final mediaUrl = post['media_url'] ?? '';

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.redAccent,
                                  child: Icon(Icons.person, color: Colors.white, size: 20),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Community Creator',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          if (mediaUrl.isNotEmpty)
                            Container(
                              height: 350,
                              width: double.infinity,
                              color: Colors.black,
                              child: Image.network(
                                mediaUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(
                                    child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                                ),
                              ),
                            ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.favorite_border, color: Colors.white, size: 26),
                                SizedBox(width: 16),
                                Icon(Icons.comment_outlined, color: Colors.white, size: 24),
                                SizedBox(width: 16),
                                Icon(Icons.share_outlined, color: Colors.white, size: 24),
                              ],
                            ),
                          ),
                          if (caption.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                              child: Text(
                                caption,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: _showCreatePostBottomSheet,
        child: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
      ),
    );
  }
}
