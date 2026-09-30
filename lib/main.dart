import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
  url: 'https://ycvycgdnrmlfaebtxvfl.supabase.co',
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljdnljZ2Rubm1sZmFlYnR4dmZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyOTk2MjAsImV4cCI6MjA5Njg3NTYyMH0.Os73HGXe4EOijqpBVHk9Bcm6uzZXkgZjWRoroV1m2gE',
);

  runApp(const KuanYngneApp());
}

class KuanYngneApp extends StatelessWidget {
  const KuanYngneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KuanYngne',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.amber,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const VideoFeedScreen(),
    const TemplateEditorScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.black,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.style), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ------------------- VIDEO FEED SCREEN -------------------
class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final _supabase = Supabase.instance.client;
  String _selectedCategory = 'ሁሉም';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ሁሉም', 'ንግድ', 'ቴክኖሎጂ', 'ጥቅሶች', 'ኮሜዲ'].map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: Colors.amber,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = cat);
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchVideos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'የኮኔክሽን ችግር ተፈጥሯል፦ ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final videos = snapshot.data ?? [];
          if (videos.isEmpty) {
            return const Center(child: Text('ምንም ቪዲዮ አልተገኘም'));
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: videos.length,
            itemBuilder: (context, index) {
              return VideoCard(videoData: videos[index]);
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchVideos() async {
    dynamic query = _supabase.from('videos').select();
    if (_selectedCategory != 'ሁሉም') {
      query = query.eq('category', _selectedCategory);
    }
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}

class VideoCard extends StatefulWidget {
  final Map<String, dynamic> videoData;
  const VideoCard({super.key, required this.videoData});

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final url = widget.videoData['video_url']?.toString() ?? '';
    if (url.isNotEmpty) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _controller?.setLooping(true);
            _controller?.play();
          }
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
    final phone = widget.videoData['phone_number']?.toString();
    final telegram = widget.videoData['telegram_username']?.toString();

    return Stack(
      children: [
        _controller != null && _controller!.value.isInitialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator(color: Colors.amber)),

        Positioned(
          bottom: 20,
          left: 15,
          right: 70,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.videoData['title']?.toString() ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  if (phone != null && phone.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('ደውል'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  if (telegram != null && telegram.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => launchUrl(Uri.parse('https://t.me/$telegram')),
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Telegram'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                ],
              )
            ],
          ),
        ),

        Positioned(
          right: 15,
          bottom: 40,
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white, size: 30),
                onPressed: () {
                  final videoUrl = widget.videoData['video_url']?.toString() ?? '';
                  if (videoUrl.isNotEmpty) {
                    Share.share(videoUrl);
                  }
                },
              ),
            ],
          ),
        )
      ],
    );
  }
}

// ------------------- TEMPLATE EDITOR SCREEN -------------------
class TemplateEditorScreen extends StatefulWidget {
  const TemplateEditorScreen({super.key});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  final _flutterTts = FlutterTts();
  final _titleController = TextEditingController(text: 'የእኔ ማስታወቂያ');
  final _textController = TextEditingController(text: 'አዲስ ቅናሽ ገባ!');
  final _phoneController = TextEditingController(text: '+251900000000');
  final _telegramController = TextEditingController(text: 'my_telegram');

  File? _selectedVideo;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _flutterTts.setLanguage('am-ET');
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedVideo = File(pickedFile.path));
    }
  }

  Future<void> _speakText() async {
    if (_textController.text.isNotEmpty) {
      await _flutterTts.speak(_textController.text);
    }
  }

  Future<void> _uploadAndPublish() async {
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('እባክዎን አስቀድመው ቪዲዮ ይምረጡ')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final supabase = Supabase.instance.client;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';

      await supabase.storage.from('videos').upload(fileName, _selectedVideo!);
      final videoUrl = supabase.storage.from('videos').getPublicUrl(fileName);

      await supabase.from('videos').insert({
        'title': _titleController.text,
        'video_url': videoUrl,
        'category': 'ንግድ',
        'phone_number': _phoneController.text,
        'telegram_username': _telegramController.text,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ቪዲዮው በትክክል ተለጥፏል!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ስህተት ተፈጥሯል፦ $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Remix / Template Editor'), backgroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[900],
                ),
                child: _selectedVideo != null
                    ? const Center(child: Icon(Icons.check_circle, color: Colors.green, size: 50))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_library, color: Colors.amber, size: 40),
                          SizedBox(height: 8),
                          Text('ቪዲዮ ለመምረጥ እዚህ ይጫኑ'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'የማስታወቂያው ርዕስ', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: 'ቪዲዮው ላይ የሚነበብ ፅሁፍ (TTS)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.amber),
                  onPressed: _speakText,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'የስልክ ቁጥር', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _telegramController,
              decoration: const InputDecoration(labelText: 'የቴሌግራም Username', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            _isUploading
                ? const CircularProgressIndicator(color: Colors.amber)
                : ElevatedButton(
                    onPressed: _uploadAndPublish,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('ለጥፍ (Publish)'),
                  ),
          ],
        ),
      ),
    );
  }
}

// ------------------- PROFILE SCREEN -------------------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), backgroundColor: Colors.black),
      body: const Center(
        child: Text('የመገለጫ ገጽ (Profile)', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
