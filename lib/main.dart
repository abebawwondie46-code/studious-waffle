import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://ycvycgdnnmlfaebtxvfl.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljdnljZ2Rubm1sZmFlYnR4dmZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyOTk2MjAsImV4cCI6MjA5Njg3NTYyMH0.Os73HGXe4EOijqpBVHk9Bcm6uzZXkgZjWRoroV1m2gE',
    );
  } catch (e) {
    debugPrint('Supabase Init Error: $e');
  }

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CultureNegne Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const FeedScreen(),
    );
  }
}

enum MediaType { none, image, video }

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
    this.mediaType = MediaType.none,
    required this.likes,
    this.commentsCount = 0,
    this.views = 0,
    this.isLiked = false,
  });

  factory FeedItem.fromMap(Map<String, dynamic> map) {
    MediaType mType = MediaType.none;
    if (map['media_type'] == 'video') {
      mType = MediaType.video;
    } else if (map['media_type'] == 'image') {
      mType = MediaType.image;
    }

    return FeedItem(
      id: map['id'].toString(),
      title: map['title'] ?? '',
      username: map['username'] ?? '@user',
      phoneNumber: map['phone_number'] ?? '',
      category: map['category'] ?? 'ንግድ',
      mediaUrl: map['media_url'],
      mediaType: mType,
      likes: map['likes'] ?? 0,
      commentsCount: map['comments_count'] ?? 0,
      views: map['views'] ?? 0,
    );
  }
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<String> _categories = ['ሁሉም', 'ንግድ', 'ፖለቲካ', 'ዜና', 'ቪዲዮ', 'ጥቅስ', 'ቴክኖሎጂ'];
  String _selectedCategory = 'ሁሉም';
  List<FeedItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase.from('videos').select().order('created_at', ascending: false);
      setState(() {
        _items = (data as List).map((e) => FeedItem.fromMap(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Fetch Error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showAddModal() {
    final titleController = TextEditingController();
    final usernameController = TextEditingController();
    final phoneController = TextEditingController();
    String category = 'ንግድ';
    File? mediaFile;
    MediaType mediaType = MediaType.none;
    bool uploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickMedia(bool isVideo) async {
            final picker = ImagePicker();
            final file = isVideo
                ? await picker.pickVideo(source: ImageSource.gallery)
                : await picker.pickImage(source: ImageSource.gallery);
            if (file != null) {
              setModalState(() {
                mediaFile = File(file.path);
                mediaType = isVideo ? MediaType.video : MediaType.image;
              });
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              top: 20, left: 20, right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('አዲስ ፖስት ማጋሪያ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                const SizedBox(height: 12),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'መረጃ / ፅሁፍ')),
                const SizedBox(height: 8),
                TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'የተጠቃሚ ስም (@username)')),
                const SizedBox(height: 8),
                TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'ስልክ ቁጥር')),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.video_collection),
                      label: const Text('ቪዲዮ'),
                      onPressed: () => pickMedia(true),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('ፎቶ'),
                      onPressed: () => pickMedia(false),
                    ),
                  ],
                ),
                if (mediaFile != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('ተመርጧል: ${mediaFile!.path.split('/').last}', style: const TextStyle(color: Colors.amber)),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    onPressed: uploading
                        ? null
                        : () async {
                            setModalState(() => uploading = true);
                            try {
                              String? mediaUrl;
                              if (mediaFile != null) {
                                final ext = mediaFile!.path.split('.').last;
                                final path = '${DateTime.now().millisecondsSinceEpoch}.$ext';
                                
                                await supabase.storage.from('media').upload(path, mediaFile!);
                                mediaUrl = supabase.storage.from('media').getPublicUrl(path);
                              }

                              await supabase.from('videos').insert({
                                'title': titleController.text.trim(),
                                'username': usernameController.text.trim().isEmpty ? '@user' : usernameController.text.trim(),
                                'phone_number': phoneController.text.trim(),
                                'category': category,
                                'media_url': mediaUrl,
                                'media_type': mediaType == MediaType.video ? 'video' : (mediaType == MediaType.image ? 'image' : 'none'),
                                'likes': 0,
                                'comments_count': 0,
                                'views': 0,
                              });

                              await _fetchItems();
                              if (mounted) Navigator.pop(ctx);
                            } catch (e) {
                              setModalState(() => uploading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('ስህተት ተፈጥሯል: $e')),
                              );
                            }
                          },
                    child: uploading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text('ለጥፍ (Upload)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Stack(
              children: [
                PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: _items.length,
                  itemBuilder: (ctx, index) => FeedCardItem(item: _items[index]),
                ),
                Positioned(
                  right: 16,
                  bottom: 35,
                  child: FloatingActionButton(
                    backgroundColor: Colors.amber,
                    onPressed: _showAddModal,
                    child: const Icon(Icons.add, color: Colors.black, size: 30),
                  ),
                )
              ],
            ),
    );
  }
}

class FeedCardItem extends StatefulWidget {
  final FeedItem item;
  const FeedCardItem({super.key, required this.item});

  @override
  State<FeedCardItem> createState() => _FeedCardItemState();
}

class _FeedCardItemState extends State<FeedCardItem> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.item.mediaType == MediaType.video && widget.item.mediaUrl != null) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.item.mediaUrl!))
        ..initialize().then((_) {
          setState(() {});
          _controller!.setLooping(true);
          _controller!.play();
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          if (widget.item.mediaType == MediaType.video && _controller != null && _controller!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          else if (widget.item.mediaType == MediaType.image && widget.item.mediaUrl != null)
            SizedBox.expand(
              child: Image.network(widget.item.mediaUrl!, fit: BoxFit.cover),
            ),
          Positioned(
            left: 16, bottom: 40, right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.username, style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(widget.item.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
