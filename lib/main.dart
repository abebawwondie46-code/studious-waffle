import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

// 1. የ Supabase አድራሻ እና አዲሱ Key
const String supabaseUrl = 'https://ycvycgdnnmlfaebtxvfl.supabase.co';
const String supabaseAnonKey = 'sb_publishable_jEgLbgOCrBU3NZ0pM_lWlw_rJjyRbBp';

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'kuanyngne',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(primary: Colors.amber),
      ),
      home: const MainFeedScreen(),
    );
  }
}

enum MediaType { video, image, none }

class FeedItem {
  final String id;
  final String title;
  final String username;
  final String phoneNumber;
  final String category;
  final String? mediaUrl;
  final MediaType mediaType;
  int likes;
  int commentsCount;
  int views;
  bool isLiked;

  FeedItem({
    required this.id,
    required this.title,
    required this.username,
    required this.phoneNumber,
    required this.category,
    this.mediaUrl,
    required this.mediaType,
    required this.likes,
    required this.commentsCount,
    required this.views,
    this.isLiked = false,
  });

  factory FeedItem.fromMap(Map<String, dynamic> map) {
    MediaType mType = MediaType.none;
    if (map['media_type'] == 'video') mType = MediaType.video;
    if (map['media_type'] == 'image') mType = MediaType.image;

    return FeedItem(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      username: map['username'] ?? '@user_ethio',
      phoneNumber: map['phone_number'] ?? '',
      category: map['category'] ?? 'ሁሉም',
      mediaUrl: map['media_url'],
      mediaType: mType,
      likes: map['likes'] ?? 0,
      commentsCount: map['comments_count'] ?? 0,
      views: map['views'] ?? 0,
    );
  }
}

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({super.key});

  @override
  State<MainFeedScreen> createState() => _MainFeedScreenState();
}

class _MainFeedScreenState extends State<MainFeedScreen> {
  List<FeedItem> _feedItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'ሁሉም';
  final List<String> _categories = ['ሁሉም', 'ንግድ', 'ፖለቲካ', 'ዜና', 'ቪዲዮ'];

  @override
  void initState() {
    super.initState();
    _fetchFeedFromSupabase();
  }

  // 1. ቪዲዮዎችን ከ Supabase መሳብ
  Future<void> _fetchFeedFromSupabase() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('videos')
          .select()
          .order('id', ascending: false);

      final List<dynamic> data = response;
      setState(() {
        _feedItems = data.map((item) => FeedItem.fromMap(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching videos: $e');
      setState(() => _isLoading = false);
    }
  }

  // 2. ላይክ ማድረግ (Like Sync)
  Future<void> _toggleLike(FeedItem item) async {
    setState(() {
      item.isLiked = !item.isLiked;
      if (item.isLiked) {
        item.likes++;
      } else {
        item.likes--;
      }
    });

    try {
      await supabase.from('videos').update({
        'likes': item.likes,
      }).eq('id', int.parse(item.id));
    } catch (e) {
      debugPrint('Like Update Error: $e');
    }
  }

  // 3. አስተያየት መስጫ ሞዳል (Comment Sync)
  void _showCommentsModal(FeedItem item) {
    final commentController = TextEditingController();
    bool isPosting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'አስተያየቶች (${item.commentsCount})',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'አስተያየት ይፃፉ...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF2C2C2C),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      isPosting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.amber, strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send, color: Colors.amber),
                              onPressed: () async {
                                final text = commentController.text.trim();
                                if (text.isNotEmpty) {
                                  setModalState(() => isPosting = true);

                                  try {
                                    // A. comment ን መፃፍ
                                    await supabase.from('comments').insert({
                                      'video_id': int.parse(item.id),
                                      'comment': text,
                                    });

                                    // B. comments_count ን ማሳደግ
                                    final newCount = item.commentsCount + 1;
                                    await supabase.from('videos').update({
                                      'comments_count': newCount,
                                    }).eq('id', int.parse(item.id));

                                    setState(() {
                                      item.commentsCount = newCount;
                                    });

                                    if (mounted) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('አስተያየትዎ ተልኳል!')),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint('Comment Error: $e');
                                    setModalState(() => isPosting = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('ስህተት: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 4. አዲስ ቪዲዮ/ጽሑፍ መጫኛ (Upload & Database Sync)
  void _showAddContentBottomSheet() {
    final titleController = TextEditingController();
    final usernameController = TextEditingController();
    final phoneController = TextEditingController();

    File? selectedMediaFile;
    MediaType selectedMediaType = MediaType.none;
    String selectedCategory = 'ንግድ';
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'አዲስ ይዘት ለጥፍ',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'የተጠቃሚ ስም (ምሳሌ፡ @user)',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'ስልክ ቁጥር (አማራጭ)',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'ርዕስ / መግለጫ',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.videocam),
                            label: const Text('ቪዲዮ መዝግብ/ምረጥ'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black),
                            onPressed: () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickVideo(
                                  source: ImageSource.gallery);
                              if (pickedFile != null) {
                                setModalState(() {
                                  selectedMediaFile = File(pickedFile.path);
                                  selectedMediaType = MediaType.video;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (selectedMediaFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'የተመረጠ ፋይል: ${selectedMediaFile!.path.split('/').last}',
                          style: const TextStyle(
                              color: Colors.green, fontSize: 12),
                        ),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: isUploading
                          ? null
                          : () async {
                              final inputUsername =
                                  usernameController.text.trim();
                              final inputPhone = phoneController.text.trim();
                              final inputTitle = titleController.text.trim();

                              if (inputTitle.isNotEmpty ||
                                  selectedMediaFile != null) {
                                setModalState(() => isUploading = true);

                                String? mediaUrl;
                                String mTypeString = 'none';
                                String finalUsername = inputUsername.isEmpty
                                    ? '@user_ethio'
                                    : inputUsername;
                                if (!finalUsername.startsWith('@')) {
                                  finalUsername = '@$finalUsername';
                                }

                                try {
                                  // 1. Storage Upload
                                  if (selectedMediaFile != null) {
                                    final fileName =
                                        '${DateTime.now().millisecondsSinceEpoch}.mp4';

                                    await supabase.storage
                                        .from('media')
                                        .upload(
                                          fileName,
                                          selectedMediaFile!,
                                          fileOptions: const FileOptions(
                                              cacheControl: '3600',
                                              upsert: true),
                                        );

                                    mediaUrl = supabase.storage
                                        .from('media')
                                        .getPublicUrl(fileName);
                                    mTypeString =
                                        selectedMediaType == MediaType.video
                                            ? 'video'
                                            : 'image';
                                  }

                                  // 2. Database Insert
                                  await supabase.from('videos').insert({
                                    'title': inputTitle,
                                    'username': finalUsername,
                                    'phone_number': inputPhone,
                                    'category': selectedCategory,
                                    'media_url': mediaUrl,
                                    'media_type': mTypeString,
                                    'likes': 0,
                                    'comments_count': 0,
                                    'views': 0,
                                  });

                                  // 3. ዳታን እንደገና መሳብ
                                  await _fetchFeedFromSupabase();

                                  if (mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('በተሳካ ሁኔታ ተልፏል!')),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Upload Error: $e');
                                  setModalState(() => isUploading = false);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('የመጫን ስህተት: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                      child: isUploading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'ለጥፍ (Publish)',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
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
    final filteredList = _selectedCategory == 'ሁሉም'
        ? _feedItems
        : _feedItems.where((i) => i.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('kuanyngne Feed'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ካቴጎሪዎች
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.amber,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          // የቪዲዮ/ይዘት ዝርዝር
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.amber))
                : RefreshIndicator(
                    onRefresh: _fetchFeedFromSupabase,
                    child: ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final item = filteredList[index];
                        return FeedCard(
                          item: item,
                          onLike: () => _toggleLike(item),
                          onComment: () => _showCommentsModal(item),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: _showAddContentBottomSheet,
        child: const Icon(Icons.add, color: Colors.black, size: 30),
      ),
    );
  }
}

// የቪዲዮ አጫዋች እና ይዘት ማሳያ ካርድ
class FeedCard extends StatefulWidget {
  final FeedItem item;
  final VoidCallback onLike;
  final VoidCallback onComment;

  const FeedCard({
    super.key,
    required this.item,
    required this.onLike,
    required this.onComment,
  });

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.item.mediaType == MediaType.video &&
        widget.item.mediaUrl != null &&
        widget.item.mediaUrl!.isNotEmpty) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.item.mediaUrl!))
            ..initialize().then((_) {
              setState(() {});
              _videoController?.setLooping(true);
            });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ቪዲዮው ካለ ማሳያ
          if (widget.item.mediaType == MediaType.video &&
              _videoController != null &&
              _videoController!.value.isInitialized)
            GestureDetector(
              onTap: () {
                setState(() {
                  _videoController!.value.isPlaying
                      ? _videoController!.pause()
                      : _videoController!.play();
                });
              },
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_videoController!),
                    if (!_videoController!.value.isPlaying)
                      const Icon(Icons.play_circle_fill,
                          size: 60, color: Colors.amber),
                  ],
                ),
              ),
            )
          else if (widget.item.mediaType == MediaType.video)
            const SizedBox(
              height: 200,
              child: Center(
                  child: CircularProgressIndicator(color: Colors.amber)),
            ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.username,
                    style: const TextStyle(
                        color: Colors.amber, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(widget.item.title,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: Icon(
                        widget.item.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.item.isLiked ? Colors.red : Colors.white,
                      ),
                      onPressed: widget.onLike,
                    ),
                    Text('${widget.item.likes}',
                        style: const TextStyle(color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.comment, color: Colors.white),
                      onPressed: widget.onComment,
                    ),
                    Text('${widget.item.commentsCount}',
                        style: const TextStyle(color: Colors.white)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
