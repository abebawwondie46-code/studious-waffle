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
      title: 'kuanyngne Studio Pro',
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

            // 2. MIDDLE SECTION (SIDEBAR & CENTER CANVAS)
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
                              Icon(Icons.cloud_upload_outlined, color: Color(0xFFBAC7FF), size: 22),
                              SizedBox(height: 4),
                              Text('Supabase Upload', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
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

                  // CENTER CANVAS
                  Expanded(
                    child: Container(
                      color: const Color(0xFF0F1015),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // TOP FEED TABS
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF181A20),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.live_tv, color: Colors.white, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: const [
                                          Text('Friends', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
                                          SizedBox(width: 10),
                                          Text('For You', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
                                          SizedBox(width: 10),
                                          Text('Following', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white54),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('HD 1080p', style: TextStyle(color: Colors.white, fontSize: 8)),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.search, color: Colors.white, size: 16),
                                ],
                              ),
                            ),

                            // MAIN MOBILE VIDEO SCREEN FRAME
                            Expanded(
                              child: AspectRatio(
                                aspectRatio: 9 / 16,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(20),
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
                                    borderRadius: BorderRadius.circular(18),
                                    child: const TikTokScrollableFeed(),
                                  ),
                                ),
                              ),
                            ),

                            // BOTTOM NAVIGATION BAR
                            Container(
                              height: 48,
                              margin: const EdgeInsets.only(top: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF181A20),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildBottomNavItem(Icons.home, 'Home', color: Colors.white),
                                  _buildBottomNavItem(Icons.people_outline, 'Friends'),
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
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: color, fontSize: 9)),
      ],
    );
  }
}

// ==================== VERTICAL SCROLLABLE TIKTOK FEED ====================
class TikTokScrollableFeed extends StatefulWidget {
  const TikTokScrollableFeed({super.key});

  @override
  State<TikTokScrollableFeed> createState() => _TikTokScrollableFeedState();
}

class _TikTokScrollableFeedState extends State<TikTokScrollableFeed> {
  final PageController _pageController = PageController();

  // SUPABASE / FAST CDN DIRECT VIDEO URLS FOR kuanyngne
  final List<Map<String, String>> _videoData = [
    {
      'url': 'https://assets.mixkit.co/videos/preview/mixkit-tree-with-yellow-flowers-1173-large.mp4',
      'username': '@kuanyngne',
      'caption': 'Kuanyngne Official Supabase Video Stream! 🚀 Live HD Streaming Test #kuanyngne',
      'likes': '24.1K',
      'comments': '152',
      'bookmarks': '3100',
      'shares': '1200',
    },
    {
      'url': 'https://assets.mixkit.co/videos/preview/mixkit-vertical-shot-of-a-waterfall-in-a-forest-42891-large.mp4',
      'username': '@kuanyngne',
      'caption': '5-Minute High Quality Streaming via Supabase Network Connection 🔥',
      'likes': '58.9K',
      'comments': '890',
      'bookmarks': '4500',
      'shares': '2100',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: _pageController,
      itemCount: _videoData.length,
      itemBuilder: (context, index) {
        return SingleVideoItem(videoInfo: _videoData[index]);
      },
    );
  }
}

class SingleVideoItem extends StatefulWidget {
  final Map<String, String> videoInfo;

  const SingleVideoItem({super.key, required this.videoInfo});

  @override
  State<SingleVideoItem> createState() => _SingleVideoItemState();
}

class _SingleVideoItemState extends State<SingleVideoItem> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _discAnimController;
  bool _isLiked = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();

    _discAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoInfo['url']!),
    )..initialize().then((_) {
        if (mounted) {
          setState(() {
            _hasError = false;
          });
          _controller.setLooping(true);
          _controller.play();
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _discAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_controller.value.isInitialized) {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
              _discAnimController.stop();
            } else {
              _controller.play();
              _discAnimController.repeat();
            }
          });
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. VIDEO PLAYER OR LOADING/ERROR STATUS
          if (_hasError)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off, color: Colors.white54, size: 30),
                  SizedBox(height: 6),
                  Text('የኢንተርኔት ግንኙነትዎን ያረጋግጡ', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            )
          else if (_controller.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFFBAC7FF), strokeWidth: 2),
            ),

          // BOTTOM GRADIENT SHADOW
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // PAUSE ICON OVERLAY
          if (_controller.value.isInitialized && !_controller.value.isPlaying)
            Container(
              decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, color: Colors.white70, size: 45),
            ),

          // 2. RIGHT SIDE SOCIAL ACTION ICONS
          Positioned(
            right: 8,
            bottom: 15,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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

                GestureDetector(
                  onTap: () => setState(() => _isLiked = !_isLiked),
                  child: Icon(Icons.favorite, color: _isLiked ? const Color(0xFFFF2C55) : Colors.white, size: 26),
                ),
                Text(widget.videoInfo['likes']!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                const Icon(Icons.comment, color: Colors.white, size: 24),
                Text(widget.videoInfo['comments']!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                const Icon(Icons.bookmark, color: Colors.white, size: 24),
                Text(widget.videoInfo['bookmarks']!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                const Icon(Icons.reply, color: Colors.white, size: 24),
                Text(widget.videoInfo['shares']!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                RotationTransition(
                  turns: _discAnimController,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 1.5),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white, size: 10),
                  ),
                ),
              ],
            ),
          ),

          // 3. BOTTOM LEFT TEXT & CAPTION
          Positioned(
            left: 10,
            bottom: 12,
            right: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.videoInfo['username']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 3),
                Text(
                  widget.videoInfo['caption']!,
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white, size: 10),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Original Audio - ${widget.videoInfo['username']}',
                        style: const TextStyle(color: Colors.white, fontSize: 8),
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
