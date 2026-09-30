import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yszkonhhprwtavxywchz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlzemtvbmhocHJ3dGF2eHl3Y2h6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3NjQxNDksImV4cCI6MjEwNjM0MDE0OX0.TXL0yzOlI3Kx5CyW6CvOsWMMc_wRafTVt7CcTxYev7E',
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
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.redAccent,
          secondary: Colors.amber,
        ),
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
    const AdEditorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.style_outlined),
            activeIcon: Icon(Icons.style),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline, size: 28),
            activeIcon: Icon(Icons.add_circle, size: 28),
            label: 'Create Ad',
          ),
        ],
      ),
    );
  }
}

// ==================== 1. FEED SCREEN ====================
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
      final response = await supabase
          .from('videos')
          .select()
          .order('id', ascending: false);
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
        title: const Text(
          'KuanYngne Feed',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : videos.isEmpty
              ? const Center(
                  child: Text(
                    'ምንም ማስታወቂያ አልተገኘም። "Create Ad" ላይ ገብተው ይፍጠሩ!',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(templateData['bgColor'] ?? Colors.indigo.value),
                        Color(templateData['bgColor'] ?? Colors.indigo.value)
                            .withOpacity(0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (templateData['sticker'] != null &&
                              templateData['sticker'].toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black26, blurRadius: 8)
                                ],
                              ),
                              child: Text(
                                templateData['sticker'],
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          const SizedBox(height: 30),
                          Text(
                            templateData['text'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 25),
                          if (templateData['phone'] != null &&
                              templateData['phone'].toString().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade700,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    templateData['phone'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 5,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AdEditorScreen(initialTemplate: templateData),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, color: Colors.white),
                  label: const Text(
                    'Remix This',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          bottom: 40,
          left: 20,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 6)],
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== 2. PRO AD/POSTER EDITOR SCREEN ====================
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

  Color _selectedBgColor = const Color(0xFF3F51B5);
  String _selectedSticker = 'Telebirr Accepted';
  bool _isPublishing = false;

  final List<Color> _colors = [
    const Color(0xFF3F51B5), // Indigo
    const Color(0xFF673AB7), // Deep Purple
    const Color(0xFF009688), // Teal
    const Color(0xFF1E88E5), // Blue
    const Color(0xFFD81B60), // Pink/Red
    const Color(0xFF43A047), // Green
    const Color(0xFF37474F), // Dark Slate
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
      _textController.text = 'የማስታወቂያ መልዕክትዎን እዚህ ይፃፉ...';
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
        'video_url': '',
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
        title: const Text(
          'Create Poster Ad',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _isPublishing
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.green),
                    ),
                  )
                : TextButton.icon(
                    onPressed: _publishAd,
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.greenAccent, size: 20),
                    label: const Text(
                      'Publish',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Canvas Live Preview Area
              Container(
                width: double.infinity,
                height: 250,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _selectedBgColor,
                      _selectedBgColor.withOpacity(0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _selectedBgColor.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 15.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_selectedSticker.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black26, blurRadius: 4)
                                  ],
                                ),
                                child: Text(
                                  _selectedSticker,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 15),
                            Text(
                              _textController.text.isEmpty
                                  ? 'የማስታወቂያ ጽሁፍ...'
                                  : _textController.text,
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            if (_phoneController.text.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade700,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.phone,
                                        size: 14, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      _phoneController.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const Positioned(
                      top: 12,
                      right: 12,
                      child: Chip(
                        label: Text('LIVE PREVIEW',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        backgroundColor: Colors.black38,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  ],
                ),
              ),

              // 2. Control Forms Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'የማስታወቂያው ርዕስ (Title)',
                        prefixIcon: const Icon(Icons.title, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'የማስታወቂያ መልዕክት/ፅሁፍ',
                        prefixIcon:
                            const Icon(Icons.edit_note, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'የስልክ ቁጥር (Contact)',
                        prefixIcon: const Icon(Icons.phone_android,
                            color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'የጀርባ ከለር ይምረጡ:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _colors.length,
                        itemBuilder: (context, index) {
                          final color = _colors[index];
                          final isSelected = _selectedBgColor == color;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedBgColor = color;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              width: isSelected ? 48 : 40,
                              height: isSelected ? 48 : 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                            color: color.withOpacity(0.6),
                                            blurRadius: 8)
                                      ]
                                    : [],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'ስቲከር / ባጅ ይምረጡ:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _stickers.map((sticker) {
                        final isSelected = _selectedSticker == sticker;
                        return ChoiceChip(
                          label: Text(sticker),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          selected: isSelected,
                          selectedColor: Colors.amber,
                          backgroundColor: const Color(0xFF2C2C2C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedSticker = sticker;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              )
            ],
          ),
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
