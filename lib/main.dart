import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yszkonhhprwtavxywchz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlzemtvbmhocHJ3dGF2eHl3Y2h6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3NjQxNDksImV4cCI6MjEwNjM0MDE0OX0.TXL0yzOlI3Kx5CyW6CvOsWMMc_wRafTVt7CcTxYev7E',
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
      theme: ThemeData.dark(),
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
    const AdEditorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.movie),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box, size: 30),
            label: 'Create Ad',
          ),
        ],
      ),
    );
  }
}

// ==================== 1. FEED SCREEN (የቪዲዮ እና የቴምፕሌት ፍሰት) ====================
class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> videos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    try {
      final response = await supabase.from('videos').select().order('id', ascending: false);
      setState(() {
        videos = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KuanYngne Feed'),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : videos.isEmpty
              ? const Center(child: Text('ምንም ማስታወቂያ አልተገኘም። "Create Ad" ገፅ ላይ ገብተው ይፍጠሩ!'))
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final item = videos[index];
                    return AdCard(adData: item);
                  },
                ),
    );
  }
}

class AdCard extends StatelessWidget {
  final dynamic adData;
  const AdCard({super.key, required this.adData});

  @override
  Widget build(BuildContext context) {
    final title = adData['title'] ?? 'ማስታወቂያ';
    final templateJson = adData['template_json'];
    final videoUrl = adData['video_url'] ?? '';

    // የቴምፕሌት ዳታ ካለ በፖስተር መልክ ያሳያል
    Map<String, dynamic>? templateData;
    if (templateJson != null) {
      if (templateJson is String) {
        templateData = jsonDecode(templateJson);
      } else {
        templateData = Map<String, dynamic>.from(templateJson);
      }
    }

    return Stack(
      children: [
        Positioned.fill(
          child: templateData != null
              ? Container(
                  color: Color(templateData['bgColor'] ?? Colors.indigo.value),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (templateData['sticker'] != null && templateData['sticker'].isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                templateData['sticker'],
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          const SizedBox(height: 30),
                          Text(
                            templateData['text'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          if (templateData['phone'] != null && templateData['phone'].isNotEmpty)
                            Chip(
                              avatar: const Icon(Icons.phone, color: Colors.white),
                              label: Text(templateData['phone'], style: const TextStyle(color: Colors.white)),
                              backgroundColor: Colors.green,
                            ),
                        ],
                      ),
                    ),
                  ),
                )
              : videoUrl.isNotEmpty
                  ? NetworkVideoPlayer(videoUrl: videoUrl)
                  : Container(color: Colors.black),
        ),
        // Remix Button
        Positioned(
          bottom: 40,
          right: 20,
          child: Column(
            children: [
              if (templateData != null)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdEditorScreen(initialTemplate: templateData),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, color: Colors.white),
                  label: const Text('Remix This', style: TextStyle(color: Colors.white)),
                ),
            ],
          ),
        ),
        Positioned(
          bottom: 40,
          left: 20,
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ==================== 2. AD/POSTER EDITOR SCREEN (ማስታወቂያ መስሪያ) ====================
class AdEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? initialTemplate;
  const AdEditorScreen({super.key, this.initialTemplate});

  @override
  State<AdEditorScreen> createState() => _AdEditorScreenState();
}

class _AdEditorScreenState extends State<AdEditorScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  Color _selectedBgColor = Colors.indigo;
  String _selectedSticker = 'Telebirr Accepted';
  bool _isPublishing = false;

  final List<Color> _colors = [
    Colors.indigo,
    Colors.deepPurple,
    Colors.teal,
    Colors.darkBlue,
    Colors.brown,
    Colors.redHeadline,
  ];

  final List<String> _stickers = [
    'Telebirr Accepted',
    'CBE Birr',
    '50% DISCOUNT',
    'SPECIAL OFFER',
    'CALL NOW',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTemplate != null) {
      _textController.text = widget.initialTemplate!['text'] ?? '';
      _phoneController.text = widget.initialTemplate!['phone'] ?? '';
      _selectedSticker = widget.initialTemplate!['sticker'] ?? _stickers.first;
      if (widget.initialTemplate!['bgColor'] != null) {
        _selectedBgColor = Color(widget.initialTemplate!['bgColor']);
      }
    } else {
      _textController.text = 'የእርስዎ ማስታወቂያ ፅሁፍ እዚህ ይፃፉ...';
    }
  }

  Future<void> _publishAd() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('እባክዎን ለማስታወቂያው ርዕስ ያስገቡ!')),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    final templateMap = {
      'text': _textController.text,
      'phone': _phoneController.text,
      'sticker': _selectedSticker,
      'bgColor': _selectedBgColor.value,
    };

    try {
      await supabase.from('videos').insert({
        'title': _titleController.text.trim(),
        'video_url': '', // ቴምፕሌት ስለሆነ
        'template_json': templateMap,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ማስታወቂያዎ በትክክል ተለጥፏል!')),
        );
        _titleController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('መለጠፍ አልተቻለም: $e')),
        );
      }
    } finally {
      setState(() {
        _isPublishing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad & Poster Canvas'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green, size: 30),
            onPressed: _isPublishing ? null : _publishAd,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Preview Canvas Area
            Container(
              height: 320,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedBgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_selectedSticker.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedSticker,
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          const SizedBox(height: 20),
                          Text(
                            _textController.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 15),
                          if (_phoneController.text.isNotEmpty)
                            Chip(
                              avatar: const Icon(Icons.phone, size: 16, color: Colors.white),
                              label: Text(_phoneController.text, style: const TextStyle(color: Colors.white)),
                              backgroundColor: Colors.green,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Controls Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'የማስታወቂያው ርዕስ (Title)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _textController,
                    maxLines: 2,
                    onChanged: (val) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'የማስታወቂያ መልዕክት/ፅሁፍ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    onChanged: (val) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'የስልክ ቁጥር (Contact)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('የጀርባ ከለር ይምረጡ:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 45,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colors.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBgColor = _colors[index];
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 45,
                            decoration: BoxDecoration(
                              color: _colors[index],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedBgColor == _colors[index] ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('ስቲከር / ባጅ ይምረጡ:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _stickers.map((sticker) {
                      final isSelected = _selectedSticker == sticker;
                      return ChoiceChip(
                        label: Text(sticker),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedSticker = sticker;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ቪዲዮ ማጫወቻ ረዳት ዊጄት
class NetworkVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const NetworkVideoPlayer({super.key, required this.videoUrl});

  @override
  State<NetworkVideoPlayer> createState() => _NetworkVideoPlayerState();
}

class _NetworkVideoPlayerState extends State<NetworkVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInit = true;
        });
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isInit
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(child: CircularProgressIndicator());
  }
}
