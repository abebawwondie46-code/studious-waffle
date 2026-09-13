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
            // 1. TOP TOOLBAR
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
                  // LEFT SIDEBAR
                  Container(
                    width: 140,
                    color: const Color(0xFF191B20),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      children: [
                        // (+) Upload Video Button
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

                        // SETTINGS
                        _buildSectionHeader('Settings'),
                        _buildWidgetItem(Icons.account_circle, 'Profile Picture'),
                        _buildWidgetItem(Icons.manage_accounts, 'Account Setup'),
                        _buildWidgetItem(Icons.security, 'Privacy Safety'),

                        // MEDIA & VIDEO
                        _buildSectionHeader('Media & Video'),
                        _buildWidgetItem(Icons.video_library, 'VideoFeed'),
                        _buildWidgetItem(Icons.audiotrack, 'AudioTrack'),
                        _buildWidgetItem(Icons.subtitles, 'SubtitleUI'),
                        _buildWidgetItem(Icons.auto_fix_high, 'VideoEffects'),

                        // SOCIAL FEATURES
                        _buildSectionHeader('Social Features'),
                        _buildWidgetItem(Icons.favorite, 'LikeButton'),
                        _buildWidgetItem(Icons.comment, 'CommentBox'),
                        _buildWidgetItem(Icons.share, 'ShareOption'),
                      ],
                    ),
                  ),

                  // CENTER CANVAS (TIKTOK STYLE CANVAS)
                  Expanded(
                    child: Container(
                      color: const Color(0xFF121418),
                      padding: const EdgeInsets.all(6),
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
                                    height: 20,
                                    color: const Color(0xFF5C6BC0),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Row(
                                      children: const [
                                        Text('main.xml', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                        Spacer(),
                                        Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 9),
                                        SizedBox(width: 4),
                                        Icon(Icons.wifi, color: Colors.white, size: 9),
                                        SizedBox(width: 4),
                                        Text('1:37', style: TextStyle(color: Colors.white, fontSize: 9)),
                                      ],
                                    ),
                                  ),
                                  const Expanded(child: TikTokCanvasPreview()),
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

            // 3. BOTTOM BAR (RUN BUTTON)
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF1F222A),
              child: Row(
                children: [
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
                  
                  // RUN BUTTON (RESTORED AS REQUESTED)
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBAC7FF),
                          foregroundColor: const Color(0xFF1F222A),
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Building and running project...')),
                          );
                        },
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Run', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

// ==================== TIKTOK STYLE CANVAS PREVIEW ====================
class TikTokCanvasPreview extends StatefulWidget {
  const TikTokCanvasPreview({super.key});

  @override
  State<TikTokCanvasPreview> createState() => _TikTokCanvasPreviewState();
}

class _TikTokCanvasPreviewState extends State<TikTokCanvasPreview> {
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
        // 1. VIDEO PLAYER
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

        // 2. TOP TIKTOK NAVIGATION (LIVE, TEM, Community, Following, For You, Search)
        Positioned(
          top: 6,
          left: 4,
          right: 4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.live_tv, color: Colors.white, size: 14),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: const [
                      SizedBox(width: 4),
                      Text('TEM', style: TextStyle(color: Colors.white60, fontSize: 8)),
                      SizedBox(width: 6),
                      Text('Community', style: TextStyle(color: Colors.white60, fontSize: 8)),
                      SizedBox(width: 6),
                      Text('Following', style: TextStyle(color: Colors.white60, fontSize: 8)),
                      SizedBox(width: 6),
                      Text('For You', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 8)),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.search, color: Colors.white, size: 14),
            ],
          ),
        ),

        // 3. RIGHT SIDEBAR BUTTONS (PROFILE, LIKE, COMMENT, BOOKMARK, SHARE, AUDIO)
        Positioned(
          right: 6,
          bottom: 45,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Avatar with Plus
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 14, color: Colors.white),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 0),
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(color: Colors.pink, shape: BoxShape.circle),
                    child: const Icon(Icons.add, size: 8, color: Colors.white),
                  )
                ],
              ),
              const SizedBox(height: 8),
              
              // Like Button
              GestureDetector(
                onTap: () => setState(() => _isLiked = !_isLiked),
                child: Icon(Icons.favorite, color: _isLiked ? Colors.red : Colors.white, size: 18),
              ),
              const Text('48.4K', style: TextStyle(color: Colors.white, fontSize: 7)),
              const SizedBox(height: 6),

              // Comment Button
              const Icon(Icons.comment, color: Colors.white, size: 18),
              const Text('435', style: TextStyle(color: Colors.white, fontSize: 7)),
              const SizedBox(height: 6),

              // Bookmark Button
              const Icon(Icons.bookmark, color: Colors.white, size: 18),
              const Text('4,491', style: TextStyle(color: Colors.white, fontSize: 7)),
              const SizedBox(height: 6),

              // Share Button
              const Icon(Icons.reply, color: Colors.white, size: 18),
              const Text('906', style: TextStyle(color: Colors.white, fontSize: 7)),
            ],
          ),
        ),

        // 4. BOTTOM USER DETAILS
        Positioned(
          left: 8,
          bottom: 40,
          right: 45,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text('jemii_Jems', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
              SizedBox(height: 2),
              Text('@NIKATEHILINA 💡', style: TextStyle(color: Colors.white70, fontSize: 8)),
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.music_note, color: Colors.white, size: 8),
                  SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      'original sound - jemii_fn - ...',
                      style: TextStyle(color: Colors.white, fontSize: 7),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 5. TIKTOK BOTTOM NAVIGATION BAR (Home, Friends, (+), Inbox, Profile)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 32,
            color: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', isActive: true),
                _buildNavItem(Icons.people_outline, 'Friends'),
                // Center (+) Create Button
                Container(
                  width: 24,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.add, color: Colors.black, size: 12),
                ),
                _buildNavItem(Icons.chat_bubble_outline, 'Inbox'),
                _buildNavItem(Icons.person_outline, 'Profile'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 12),
        Text(
          label,
          style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontSize: 6),
        ),
      ],
    );
  }
}
