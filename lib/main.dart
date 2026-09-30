import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

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
        scaffoldBackgroundColor: const Color(0xFF101014),
        cardColor: const Color(0xFF1C1C24),
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          backgroundColor: const Color(0xFF16161E),
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
              icon: Icon(Icons.add_circle_outline, size: 30),
              activeIcon: Icon(Icons.add_circle, size: 30),
              label: 'Create Ad',
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 1. ENHANCED FEED SCREEN ====================
class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> videos = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
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
        errorMessage = 'መረጃዎችን ማምጣት አልተቻለም፡ $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, color: Colors.amber, size: 24),
            SizedBox(width: 6),
            Text(
              'KuanYngne Ads',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchVideos,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchVideos,
                          icon: const Icon(Icons.refresh),
                          label: const Text('እንደገና ሞክር'),
                        )
                      ],
                    ),
                  ),
                )
              : videos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ምንም ማስታወቂያ አልተገኘም። የመጀመሪያውን ማስታወቂያ ይፍጠሩ!',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _fetchVideos,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          )
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchVideos,
                      child: PageView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          return AdCard(adData: videos[index]);
                        },
                      ),
                    ),
    );
  }
}

class AdCard extends StatefulWidget {
  final dynamic adData;
  const AdCard({super.key, required this.adData});

  @override
  State<AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<AdCard> {
  VideoPlayerController? _videoController;
  bool isLiked = false;
  int likeCount = 12;
  bool isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    final String videoUrl = widget.adData['video_url'] ?? '';
    if (videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              isVideoInitialized = true;
            });
            _videoController!.setLooping(true);
            _videoController!.play();
          }
        }).catchError((err) {
          // Video Load Error handling
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _shareAd(String title, String text) {
    Share.share('$title\n\n$text\n\nየተፈጠረው በ KuanYngne App ነው!');
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.adData['title'] ?? 'ማስታወቂያ';
    final videoUrl = widget.adData['video_url'] ?? '';
    final templateJson = widget.adData['template_json'];

    Map<String, dynamic>? templateData;
    if (templateJson != null) {
      if (templateJson is String) {
        try {
          templateData = jsonDecode(templateJson);
        } catch (_) {}
      } else {
        templateData = Map<String, dynamic>.from(templateJson);
      }
    }

    final int startColorVal = templateData?['colorStart'] ?? Colors.indigo.value;
    final int endColorVal = templateData?['colorEnd'] ?? Colors.blueAccent.value;
    final String phone = templateData?['phone'] ?? '';
    final String text = templateData?['text'] ?? '';
    final String sticker = templateData?['sticker'] ?? '';

    return Stack(
      children: [
        // 1. Fullscreen Media
        Positioned.fill(
          child: videoUrl.isNotEmpty
              ? (isVideoInitialized && _videoController != null
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          _videoController!.value.isPlaying
                              ? _videoController!.pause()
                              : _videoController!.play();
                        });
                      },
                      child: SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _videoController!.value.size.width,
                            height: _videoController!.value.size.height,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.redAccent)))
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(startColorVal), Color(endColorVal)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (sticker.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 10,
                                      offset: Offset(0, 4))
                                ],
                              ),
                              child: Text(
                                sticker,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          const SizedBox(height: 30),
                          Text(
                            text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                              shadows: [
                                Shadow(
                                    color: Colors.black45,
                                    blurRadius: 10,
                                    offset: Offset(0, 3))
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          if (phone.isNotEmpty)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 8,
                              ),
                              onPressed: () => _makePhoneCall(phone),
                              icon: const Icon(Icons.phone, color: Colors.white),
                              label: Text(
                                phone,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),

        // Dark Overlay when video plays
        if (videoUrl.isNotEmpty)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black26,
                    Colors.transparent,
                    Colors.black87,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

        // Bottom Left Info Overlay
        Positioned(
          bottom: 30,
          left: 16,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sticker.isNotEmpty && videoUrl.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sticker,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                ),
              ),
              const SizedBox(height: 6),
              if (text.isNotEmpty && videoUrl.isNotEmpty)
                Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                ),
              const SizedBox(height: 4),
              const Text(
                'በ KuanYngne የተዘጋጀ ማስታወቂያ',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ),

        // Right Action Bar
        Positioned(
          bottom: 30,
          right: 16,
          child: Column(
            children: [
              IconButton(
                iconSize: 32,
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.redAccent : Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    isLiked = !isLiked;
                    isLiked ? likeCount++ : likeCount--;
                  });
                },
              ),
              Text(
                '$likeCount',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              if (phone.isNotEmpty) ...[
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.phone, color: Colors.greenAccent),
                  onPressed: () => _makePhoneCall(phone),
                ),
                const SizedBox(height: 18),
              ],
              IconButton(
                iconSize: 30,
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: () => _shareAd(title, text),
              ),
              const SizedBox(height: 18),
              FloatingActionButton.small(
                heroTag: null,
                backgroundColor: Colors.redAccent,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AdEditorScreen(initialTemplate: templateData),
                    ),
                  );
                },
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== 2. CREATOR / EDITOR SCREEN ====================
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

  File? _selectedVideoFile;
  VideoPlayerController? _previewVideoController;

  int _selectedPresetIndex = 0;
  String _selectedSticker = 'Telebirr Accepted';
  bool _isPublishing = false;

  final List<Map<String, dynamic>> _colorPresets = [
    {
      'name': 'Dark Indigo',
      'start': const Color(0xFF283593).value,
      'end': const Color(0xFF1A237E).value
    },
    {
      'name': 'Sunset Gold',
      'start': const Color(0xFFFF8F00).value,
      'end': const Color(0xFFFF3D00).value
    },
    {
      'name': 'Emerald Green',
      'start': const Color(0xFF00897B).value,
      'end': const Color(0xFF004D40).value
    },
    {
      'name': 'Neon Purple',
      'start': const Color(0xFF8E24AA).value,
      'end': const Color(0xFF4A148C).value
    },
    {
      'name': 'Ocean Blue',
      'start': const Color(0xFF0288D1).value,
      'end': const Color(0xFF01579B).value
    },
    {
      'name': 'Deep Crimson',
      'start': const Color(0xFFC62828).value,
      'end': const Color(0xFF880E4F).value
    },
  ];

  final List<String> _stickers = [
    'Telebirr Accepted',
    'CBE Birr',
    '50% DISCOUNT',
    'SPECIAL OFFER',
    'CALL NOW',
    'HOT DEAL 🔥',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTemplate != null) {
      _textController.text = widget.initialTemplate!['text'] ?? '';
      _phoneController.text = widget.initialTemplate!['phone'] ?? '';
      _selectedSticker = widget.initialTemplate!['sticker'] ?? _stickers.first;
    } else {
      _textController.text = 'የማስታወቂያ መልዕክትዎን እዚህ ይፃፉ...';
    }
  }

  @override
  void dispose() {
    _previewVideoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      setState(() {
        _selectedVideoFile = File(video.path);
      });

      _previewVideoController?.dispose();
      _previewVideoController = VideoPlayerController.file(_selectedVideoFile!)
        ..initialize().then((_) {
          setState(() {});
          _previewVideoController!.setLooping(true);
          _previewVideoController!.play();
        });
    }
  }

  Future<void> _publishAd() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('እባክዎን ለማስታወቂያው ርዕስ (Title) ያስገቡ!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    String uploadedVideoUrl = '';

    try {
      if (_selectedVideoFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
        await supabase.storage
            .from('videos')
            .upload(fileName, _selectedVideoFile!);

        uploadedVideoUrl =
            supabase.storage.from('videos').getPublicUrl(fileName);
      }

      final selectedPreset = _colorPresets[_selectedPresetIndex];
      final templateMap = {
        'text': _textController.text,
        'phone': _phoneController.text,
        'sticker': _selectedSticker,
        'colorStart': selectedPreset['start'],
        'colorEnd': selectedPreset['end'],
      };

      await supabase.from('videos').insert({
        'title': _titleController.text.trim(),
        'video_url': uploadedVideoUrl,
        'template_json': templateMap,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 ማስታወቂያዎ በትክክል ተለጥፏል!'),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        setState(() {
          _selectedVideoFile = null;
          _previewVideoController?.dispose();
          _previewVideoController = null;
        });
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
    final activePreset = _colorPresets[_selectedPresetIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Poster / Video Ad',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF16161E),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _isPublishing
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.greenAccent),
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
              // Preview Canvas
              Container(
                width: double.infinity,
                height: 260,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: _selectedVideoFile == null
                      ? LinearGradient(
                          colors: [
                            Color(activePreset['start']),
                            Color(activePreset['end']),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Color(activePreset['start']).withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      if (_selectedVideoFile != null &&
                          _previewVideoController != null &&
                          _previewVideoController!.value.isInitialized)
                        SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _previewVideoController!.value.size.width,
                              height:
                                  _previewVideoController!.value.size.height,
                              child: VideoPlayer(_previewVideoController!),
                            ),
                          ),
                        )
                      else
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
                                      borderRadius: BorderRadius.circular(16),
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
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.video_call,
                              color: Colors.redAccent),
                          label: Text(_selectedVideoFile == null
                              ? 'ቪዲዮ ምረጥ'
                              : 'ቪዲዮ ቀይር'),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // Inputs Section
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
                        prefixIcon:
                            const Icon(Icons.title, color: Colors.redAccent),
                        filled: true,
                        fillColor: const Color(0xFF1E1E28),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
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
                            const Icon(Icons.edit_note, color: Colors.amber),
                        filled: true,
                        fillColor: const Color(0xFF1E1E28),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
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
                            color: Colors.greenAccent),
                        filled: true,
                        fillColor: const Color(0xFF1E1E28),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_selectedVideoFile == null) ...[
                      const Text(
                        'የጀርባ ዲዛይን/ከለር ይምረጡ:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _colorPresets.length,
                          itemBuilder: (context, index) {
                            final preset = _colorPresets[index];
                            final isSelected = _selectedPresetIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPresetIndex = index;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 12),
                                width: isSelected ? 52 : 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(preset['start']),
                                      Color(preset['end'])
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 22)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
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
                      runSpacing: 10,
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
                          backgroundColor: const Color(0xFF252532),
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
