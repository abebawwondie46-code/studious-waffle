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
      title: 'VibeShare Studio Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF14161B),
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
            // 1. TOP SKETCHWARE TOOLBAR
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

            // 2. MIDDLE SECTION (SIDEBAR & MOBILE FRAME)
            Expanded(
              child: Row(
                children: [
                  // LEFT SIDEBAR
                  Container(
                    width: 145,
                    color: const Color(0xFF181A20),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF252830),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF333842)),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.add_circle_outline, color: Color(0xFFBAC7FF), size: 22),
                              SizedBox(height: 4),
                              Text('Upload Video', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        _buildSectionHeader('Social Features'),
                        _buildWidgetItem(Icons.favorite_border, 'LikeButton Block'),
                        _buildWidgetItem(Icons.chat_bubble_outline, 'CommentBox Block'),
                        _buildWidgetItem(Icons.bookmark_border, 'Bookmark Block'),
                        _buildWidgetItem(Icons.reply, 'ShareOption Block'),
                        _buildSectionHeader('Navigation Elements'),
                        _buildWidgetItem(Icons.tab, 'Top Feed Tabs'),
                        _buildWidgetItem(Icons.view_day_outlined, 'Bottom Nav Bar'),
                        _buildWidgetItem(Icons.account_circle_outlined, 'Profile Overlay'),
                        _buildSectionHeader('Settings'),
                        _buildWidgetItem(Icons.account_circle, 'Profile Picture'),
                        _buildWidgetItem(Icons.manage_accounts, 'Account Setup'),
                        _buildWidgetItem(Icons.security, 'Privacy Safety'),
                      ],
                    ),
                  ),

                  // CENTER CANVAS (MOBILE WITH EXTERNAL TOP/BOTTOM NAV & INTERNAL SOCIAL ICONS)
                  Expanded(
                    child: Container(
                      color: const Color(0xFF0F1015),
                      padding: const EdgeInsets.all(8),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 9 / 18,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: const Color(0xFF3B404E), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.7),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Column(
                                children: [
                                  // EXTERNAL TOP NAV BAR (OUTSIDE VIDEO)
                                  Container(
                                    height: 36,
                                    color: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.live_tv, color: Colors.white, size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: const [
                                                Text('Friends', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                                                SizedBox(width: 8),
                                                Text('For You', style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
                                                SizedBox(width: 8),
                                                Text('Following', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.white54),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('HD 1080p', style: TextStyle(color: Colors.white, fontSize: 8)),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.search, color: Colors.white, size: 16),
                                      ],
                                    ),
                                  ),

                                  // VIDEO CANVAS WITH INTERNAL SIDE ICONS
                                  const Expanded(child: TikTokStyleVideoCanvas()),

                                  // EXTERNAL BOTTOM NAV BAR (OUTSIDE VIDEO)
                                  Container(
                                    height: 42,
                                    color: Colors.black,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildBottomNavItem(Icons.home, 'Home', color: Colors.redAccent),
                                        _buildBottomNavItem(Icons.people_outline, 'Friends'),
                                        Container(
                                          width: 32,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF2C55),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.add, color: Colors.white, size: 18),
                                        ),
                                        _buildBottomNavItem(Icons.chat_bubble_outline, 'Inbox'),
                                        _buildBottomNavItem(Icons.person_outline, 'Profile'),
                                      ],
                                    ),
                                  ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        title,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildWidgetItem(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF252830),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF333842)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFFBAC7FF)),
          const SizedBox(width: 8),
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

  Widget _buildBottomNavItem(IconData icon, String label, {Color color = Colors.grey}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 16),
        Text(label, style: TextStyle(color: color, fontSize: 8)),
      ],
    );
  }
}

// ==================== TIKTOK VIDEO CANVAS WITH SIDE ICONS ====================
class TikTokStyleVideoCanvas extends StatefulWidget {
  const TikTokStyleVideoCanvas({super.key});

  @override
  State<TikTokStyleVideoCanvas> createState() => _TikTokStyleVideoCanvasState();
}

class _TikTokStyleVideoCanvasState extends State<TikTokStyleVideoCanvas> {
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
    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
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

          // PLAY OVERLAY ICON IF PAUSED
          if (_controller.value.isInitialized && !_controller.value.isPlaying)
            Container(
              decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, color: Colors.white70, size: 45),
            ),

          // 2. RIGHT SIDE SOCIAL ACTION ICONS (INSIDE CANVAS)
          Positioned(
            right: 8,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Profile Avatar with (+) icon
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 20, color: Colors.white),
                    ),
                    Transform.translate(
                      offset: const Offset(0, 5),
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: const BoxDecoration(color: Color(0xFFFF2C55), shape: BoxShape.circle),
                        child: const Icon(Icons.add, size: 10, color: Colors.white),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 14),

                // Like Button
                GestureDetector(
                  onTap: () => setState(() => _isLiked = !_isLiked),
                  child: Icon(Icons.favorite, color: _isLiked ? const Color(0xFFFF2C55) : Colors.white, size: 26),
                ),
                const Text('12500', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // Comment Button
                const Icon(Icons.comment, color: Colors.white, size: 24),
                const Text('3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // Bookmark Button
                const Icon(Icons.bookmark, color: Colors.white, size: 24),
                const Text('2409', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // Share Button
                const Icon(Icons.reply, color: Colors.white, size: 24),
                const Text('751', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // Rotating Audio Disc Icon
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.white, size: 10),
                ),
              ],
            ),
          ),

          // 3. BOTTOM LEFT TEXT & CAPTION (INSIDE CANVAS)
          Positioned(
            left: 10,
            bottom: 12,
            right: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('@kuanyngne_official', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 3),
                const Text(
                  'Welcome to kuanyngne! Professional 5-Minute HD Video Sharing Feed 🔥 #kuany...',
                  style: TextStyle(color: Colors.white, fontSize: 9),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(Icons.music_note, color: Colors.white, size: 10),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Original Audio - kuanyngne Sound',
                        style: TextStyle(color: Colors.white, fontSize: 8),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
