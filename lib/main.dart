import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const VibeShareAppBuilder());
}

class VibeShareAppBuilder extends StatelessWidget {
  const VibeShareAppBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeShare Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF16181D),
        primaryColor: const Color(0xFF1F222A),
      ),
      home: const MainStudioEditor(),
    );
  }
}

class MainStudioEditor extends StatefulWidget {
  const MainStudioEditor({super.key});

  @override
  State<MainStudioEditor> createState() => _MainStudioEditorState();
}

class _MainStudioEditorState extends State<MainStudioEditor> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP TOOLBAR (ORIGINAL SKETCHWARE DESIGN)
            Container(
              color: const Color(0xFF1F222A),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          onPressed: () {},
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'vibe_share_studio',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            Text(
                              '601',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(icon: const Icon(Icons.undo, color: Colors.white70, size: 20), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.redo, color: Colors.white70, size: 20), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.save, color: Colors.white, size: 20), onPressed: () {}),
                        IconButton(icon: const Icon(Icons.more_vert, color: Colors.white, size: 20), onPressed: () {}),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFFBAC7FF),
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'View'),
                      Tab(text: 'Event'),
                      Tab(text: 'Component'),
                    ],
                  ),
                ],
              ),
            ),

            // 2. MIDDLE SECTION (SIDEBAR & CANVAS)
            Expanded(
              child: Row(
                children: [
                  // LEFT SIDEBAR (EXACT SKETCHWARE STRUCTURE)
                  Container(
                    width: 140,
                    color: const Color(0xFF191B20),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      children: [
                        // ከላይ ያለው (+) የቪዲዮ/ይዘት መጫኛ ባር
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252830),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF333842)),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.add, color: Colors.white, size: 22),
                              SizedBox(height: 2),
                              Text('Upload Video', style: TextStyle(color: Colors.white70, fontSize: 10)),
                            ],
                          ),
                        ),

                        // SETTINGS SECTION
                        _buildSectionHeader('Settings'),
                        _buildWidgetItem(Icons.account_circle, 'Profile Picture'),
                        _buildWidgetItem(Icons.manage_accounts, 'Account Setup'),
                        _buildWidgetItem(Icons.security, 'Privacy Safety'),

                        // MEDIA & VIDEO SECTION
                        _buildSectionHeader('Media & Video'),
                        _buildWidgetItem(Icons.video_library, 'VideoFeed'),
                        _buildWidgetItem(Icons.audiotrack, 'AudioTrack'),
                        _buildWidgetItem(Icons.subtitles, 'SubtitleUI'),
                        _buildWidgetItem(Icons.auto_fix_high, 'VideoEffects'),

                        // SOCIAL FEATURES SECTION
                        _buildSectionHeader('Social Features'),
                        _buildWidgetItem(Icons.favorite, 'LikeButton'),
                        _buildWidgetItem(Icons.comment, 'CommentBox'),
                        _buildWidgetItem(Icons.share, 'ShareOption'),
                      ],
                    ),
                  ),

                  // CENTER CANVAS (MOBILE PREVIEW WITH VIDEO)
                  Expanded(
                    child: Container(
                      color: const Color(0xFF121418),
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 9 / 16,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF333842), width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Column(
                                children: [
                                  // SKETCHWARE CANVAS STATUS BAR
                                  Container(
                                    height: 24,
                                    color: const Color(0xFF5C6BC0),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Row(
                                      children: const [
                                        Text('main.xml', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        Spacer(),
                                        Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 10),
                                        SizedBox(width: 4),
                                        Icon(Icons.wifi, color: Colors.white, size: 10),
                                        SizedBox(width: 4),
                                        Text('1:37', style: TextStyle(color: Colors.white, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                  const Expanded(child: MobileVideoCanvas()),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. BOTTOM BAR (RUN BUTTON REPLACED WITH DOWNLOAD IN SAME DESIGN)
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF1F222A),
              child: Row(
                children: [
                  // MAIN.XML DROPDOWN
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16181D),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.crop_square, color: Colors.white70, size: 14),
                        SizedBox(width: 6),
                        Text('main.xml', style: TextStyle(color: Colors.white, fontSize: 12)),
                        Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                      ],
                    ),
                  ),
                  const Spacer(),
                  
                  // DOWNLOAD BUTTON (EXACT POSITION & SHAPE OF RUN BUTTON)
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBAC7FF), // SKETCHWARE RUN BUTTON COLOR
                          foregroundColor: const Color(0xFF1F222A),
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Downloading Video / Project...')),
                          );
                        },
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      Container(
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBAC7FF),
                          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF1F222A), size: 18),
                          onPressed: () {},
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildWidgetItem(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF252830),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF333842)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFFBAC7FF)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== VIDEO PLAYER ENGINE ====================
class MobileVideoCanvas extends StatefulWidget {
  const MobileVideoCanvas({super.key});

  @override
  State<MobileVideoCanvas> createState() => _MobileVideoCanvasState();
}

class _MobileVideoCanvasState extends State<MobileVideoCanvas> {
  late VideoPlayerController _controller;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse('https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'),
    )..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _controller.setLooping(true);
          _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
            : const Center(
                child: CircularProgressIndicator(color: Color(0xFFBAC7FF), strokeWidth: 2),
              ),
        Positioned(
          bottom: 12,
          left: 10,
          right: 45,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('@vibe_share', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              SizedBox(height: 2),
              Text('አዲሱ አፕሊኬሽን ገፅታ! 🚀', style: TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ),
        Positioned(
          bottom: 12,
          right: 6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => setState(() => _isLiked = !_isLiked),
                child: Icon(Icons.favorite, color: _isLiked ? Colors.red : Colors.white, size: 22),
              ),
              const Text('2.4k', style: TextStyle(color: Colors.white, fontSize: 9)),
              const SizedBox(height: 10),
              const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
              const Text('180', style: TextStyle(color: Colors.white, fontSize: 9)),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Color(0xFFBAC7FF),
              bufferedColor: Colors.white30,
              backgroundColor: Colors.black26,
            ),
          ),
        ),
      ],
    );
  }
}
