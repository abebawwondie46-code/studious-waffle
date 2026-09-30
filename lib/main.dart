import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Supabase Initialization
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
      title: 'kuanyngne Feed',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.amber,
      ),
      home: const MainHomeScreen(),
    );
  }
}

// ==========================================
// MAIN NAVIGATION
// ==========================================
class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const VerticalVideoFeed(),
    const TemplateEditorScreen(),
    const Center(child: Text("ፕሮፋይል / የተሰሩ ማስታወቂያዎች", style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.white54,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.style), label: "Feed"),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: "Create"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// ==========================================
// VERTICAL VIDEO FEED
// ==========================================
class VerticalVideoFeed extends StatefulWidget {
  const VerticalVideoFeed({super.key});

  @override
  State<VerticalVideoFeed> createState() => _VerticalVideoFeedState();
}

class _VerticalVideoFeedState extends State<VerticalVideoFeed> {
  String _selectedCategory = "ሁሁሉም";
  final List<String> _categories = ["ሁሁሉም", "ንግድ", "ቴክኖሎጂ", "ጥቅሶች", "ዜና"];

  @override
  Widget build(BuildContext context) {
    final videoStream = Supabase.instance.client
        .from('videos')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    return Scaffold(
      body: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: videoStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.amber));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "የኢንተርኔት ግንኙነት ችግር ተፈጥሯል፦ ${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }

              final posts = snapshot.data;

              if (posts == null || posts.isEmpty) {
                return const Center(
                  child: Text("ምንም ቪዲዮ/ማስታወቂያ አልተገኘም።", style: TextStyle(color: Colors.white70)),
                );
              }

              final filteredPosts = _selectedCategory == "ሁሁሉም"
                  ? posts
                  : posts.where((p) => p["category"] == _selectedCategory).toList();

              return PageView.builder(
                scrollDirection: Axis.vertical,
                itemCount: filteredPosts.length,
                itemBuilder: (context, index) {
                  return FeedItemCard(postData: filteredPosts[index]);
                },
              );
            },
          ),

          // Top Categories Overlay
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category, style: TextStyle(color: isSelected ? Colors.black : Colors.white)),
                      selected: isSelected,
                      selectedColor: Colors.amber,
                      backgroundColor: Colors.black54,
                      onSelected: (selected) {
                        setState(() => _selectedCategory = category);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// FEED ITEM CARD WITH VIDEO & TTS
// ==========================================
class FeedItemCard extends StatefulWidget {
  final Map<String, dynamic> postData;
  const FeedItemCard({super.key, required this.postData});

  @override
  State<FeedItemCard> createState() => _FeedItemCardState();
}

class _FeedItemCardState extends State<FeedItemCard> {
  late VideoPlayerController _controller;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    final videoUrl = widget.postData["video_url"] ?? "";
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _speakAmharic(String text) async {
    await _flutterTts.setLanguage("am-ET");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  void _makePhoneCall(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _openTelegram(String username) async {
    final Uri url = Uri.parse("https://t.me/$username");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Color _hexToColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.amber;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Video
        _controller.value.isInitialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator(color: Colors.amber)),

        // Text Overlay
        Positioned(
          top: 120,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber, width: 1.5),
            ),
            child: Text(
              widget.postData["overlay_text"] ?? "",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _hexToColor(widget.postData["text_color"]),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Action Buttons
        Positioned(
          right: 15,
          bottom: 110,
          child: Column(
            children: [
              IconButton(
                icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : Colors.white, size: 32),
                onPressed: () => setState(() => _isLiked = !_isLiked),
              ),
              Text("${widget.postData["likes"] ?? 0}", style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 15),

              IconButton(
                icon: const Icon(Icons.volume_up, color: Colors.amber, size: 32),
                onPressed: () => _speakAmharic(widget.postData["overlay_text"] ?? ""),
              ),
              const Text("AI ድምፅ", style: TextStyle(color: Colors.white, fontSize: 10)),
              const SizedBox(height: 15),

              IconButton(
                icon: const Icon(Icons.auto_fix_high, color: Colors.lightBlueAccent, size: 32),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TemplateEditorScreen(templateData: widget.postData),
                    ),
                  );
                },
              ),
              const Text("Remix", style: TextStyle(color: Colors.white, fontSize: 10)),
            ],
          ),
        ),

        // CTA Section
        Positioned(
          left: 15,
          right: 80,
          bottom: 25,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.postData["title"] ?? "",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.account_balance, color: Colors.amber, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      widget.postData["bank_account"] ?? "",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () => _makePhoneCall(widget.postData["phone"] ?? ""),
                    icon: const Icon(Icons.call, color: Colors.white, size: 16),
                    label: const Text("ደውል"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: () => _openTelegram(widget.postData["telegram_user"] ?? "telegram"),
                    icon: const Icon(Icons.send, color: Colors.white, size: 16),
                    label: const Text("ቴሌግራም"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// TEMPLATE EDITOR SCREEN
// ==========================================
class TemplateEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? templateData;
  const TemplateEditorScreen({super.key, this.templateData});

  @override
  State<TemplateEditorScreen> createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _overlayController;
  late TextEditingController _phoneController;
  late TextEditingController _bankController;
  late TextEditingController _telegramController;
  Color _selectedColor = Colors.amber;
  String _selectedCategory = "ንግድ";

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.templateData?["title"] ?? "የእኔ ማስታወቂያ");
    _overlayController = TextEditingController(text: widget.templateData?["overlay_text"] ?? "አዲስ ቅናሽ ገባ!");
    _phoneController = TextEditingController(text: widget.templateData?["phone"] ?? "+251900000000");
    _bankController = TextEditingController(text: widget.templateData?["bank_account"] ?? "CBE: 1000XXXXXXXX");
    _telegramController = TextEditingController(text: widget.templateData?["telegram_user"] ?? "my_telegram");
  }

  void _publishToFeed() async {
    try {
      await Supabase.instance.client.from('videos').insert({
        'title': _titleController.text,
        'overlay_text': _overlayController.text,
        'phone': _phoneController.text,
        'bank_account': _bankController.text,
        'telegram_user': _telegramController.text,
        'category': _selectedCategory,
        'video_url': widget.templateData?["video_url"] ?? "https://assets.mixkit.co/videos/preview/mixkit-tree-with-yellow-leaves-2578-large.mp4",
        'text_color': '#${_selectedColor.value.toRadixString(16).substring(2)}',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("በስኬት ወደ Feed ታትሟል!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ማተም አልተቻለም፦ $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Remix / Template Editor"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.send, color: Colors.amber),
            onPressed: _publishToFeed,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber),
              ),
              child: Center(
                child: Text(
                  _overlayController.text,
                  style: TextStyle(color: _selectedColor, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "የማስታወቂያው ርዕስ", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
              controller: _overlayController,
              decoration: const InputDecoration(labelText: "ቪዲዮው ላይ የሚጻፍ ፅሁፍ", border: OutlineInputBorder()),
              onChanged: (val) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "የስልክ ቁጥር", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _bankController, decoration: const InputDecoration(labelText: "የባንክ አካውንት", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _telegramController, decoration: const InputDecoration(labelText: "የቴሌግራም Username", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            
            const Text("የፅሁፍ ቀለም ይምረጡ፦"),
            const SizedBox(height: 8),
            Row(
              children: [
                _colorOption(Colors.amber),
                _colorOption(Colors.cyan),
                _colorOption(Colors.redAccent),
                _colorOption(Colors.green),
                _colorOption(Colors.white),
              ],
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: _publishToFeed,
                icon: const Icon(Icons.cloud_upload, color: Colors.black),
                label: const Text("ወደ Feed በነጠላ ጠቅታ ለጥፍ (Publish)", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _colorOption(Color color) {
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: _selectedColor == color ? Colors.white : Colors.transparent, width: 3),
        ),
      ),
    );
  }
}
