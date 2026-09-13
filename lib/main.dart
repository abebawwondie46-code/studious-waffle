import 'package:flutter/material.dart';

void main() {
  runApp(const KuanyngneAppBuilder());
}

class KuanyngneAppBuilder extends StatelessWidget {
  const KuanyngneAppBuilder({super.key});

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
                              'kuanyngne_studio',
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

            // 2. EXPANDED WIDE MOBILE CANVAS
            Expanded(
              child: Container(
                color: const Color(0xFF0F1015),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    // TOP FEED TABS
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181A20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.live_tv, color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: const [
                                  Text('Friends', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500)),
                                  SizedBox(width: 16),
                                  Text('For You', style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500)),
                                  SizedBox(width: 16),
                                  Text('Following', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white54),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('HD 1080p', style: TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.search, color: Colors.white, size: 18),
                        ],
                      ),
                    ),

                    // WIDE SCREEN MOBILE FRAME
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF3B404E), width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: const TikTokScrollableFeed(),
                        ),
                      ),
                    ),

                    // BOTTOM NAVIGATION BAR
                    Container(
                      height: 52,
                      margin: const EdgeInsets.only(top: 8),
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
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, {Color color = Colors.grey}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: color, fontSize: 10)),
      ],
    );
  }
}

// ==================== VERTICAL SCROLLABLE FEED ====================
class TikTokScrollableFeed extends StatefulWidget {
  const TikTokScrollableFeed({super.key});

  @override
  State<TikTokScrollableFeed> createState() => _TikTokScrollableFeedState();
}

class _TikTokScrollableFeedState extends State<TikTokScrollableFeed> {
  final PageController _pageController = PageController();

  final List<Map<String, String>> _videoData = [
    {
      'username': '@kuanyngne',
      'caption': 'kuanyngne Official Network Stream! 🚀 Streaming Test #kuanyngne',
      'likes': '24.1K',
      'comments': '152',
      'bookmarks': '3100',
      'shares': '1200',
    },
    {
      'username': '@kuanyngne',
      'caption': 'High Quality Live Stream via kuanyngne Connection 🔥',
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
  late AnimationController _discAnimController;
  bool _isLiked = false;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _discAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _discAnimController.dispose();
    super.dispose();
  }

  void _showCommentSection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181A20),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 350,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              Text('${widget.videoInfo['comments']} ኮሜንቶች', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: const [
                    ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.blueAccent, child: Text('A', style: TextStyle(color: Colors.white))),
                      title: Text('@user_one', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text('በጣም አሪፍ ቪዲዮ ነው! 🔥', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.purpleAccent, child: Text('B', style: TextStyle(color: Colors.white))),
                      title: Text('@user_two', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text('kuanyngne ሲስተም በጥራት ይሰራል 👍', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'ኮሜንት ጻፍ...',
                        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF252830),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.horizontal(16),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFFBAC7FF)),
                    onPressed: () {},
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  void _showShareOptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('የቪዲዮው ሊንክ ተቀድቷል (Link Copied!)'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121318),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // BACKGROUND PLACEHOLDER DISPLAY
          const Center(
            child: Icon(Icons.play_circle_fill, size: 70, color: Colors.white24),
          ),

          // BOTTOM GRADIENT SHADOW
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 140,
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

          // RIGHT SIDE SOCIAL ACTION ICONS
          Positioned(
            right: 12,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 22, color: Colors.white),
                    ),
                    Transform.translate(
                      offset: const Offset(0, 5),
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: const BoxDecoration(color: Color(0xFFFF2C55), shape: BoxShape.circle),
                        child: const Icon(Icons.add, size: 12, color: Colors.white),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),

                // LIKE
                GestureDetector(
                  onTap: () => setState(() => _isLiked = !_isLiked),
                  child: Icon(Icons.favorite, color: _isLiked ? const Color(0xFFFF2C55) : Colors.white, size: 30),
                ),
                Text(widget.videoInfo['likes']!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),

                // COMMENT
                GestureDetector(
                  onTap: _showCommentSection,
                  child: const Icon(Icons.comment, color: Colors.white, size: 28),
                ),
                Text(widget.videoInfo['comments']!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),

                // BOOKMARK
                GestureDetector(
                  onTap: () => setState(() => _isBookmarked = !_isBookmarked),
                  child: Icon(Icons.bookmark, color: _isBookmarked ? Colors.amber : Colors.white, size: 28),
                ),
                Text(widget.videoInfo['bookmarks']!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),

                // SHARE
                GestureDetector(
                  onTap: _showShareOptions,
                  child: const Icon(Icons.reply, color: Colors.white, size: 28),
                ),
                Text(widget.videoInfo['shares']!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),

                RotationTransition(
                  turns: _discAnimController,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 1.5),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white, size: 12),
                  ),
                ),
              ],
            ),
          ),

          // BOTTOM LEFT TEXT & CAPTION
          Positioned(
            left: 14,
            bottom: 16,
            right: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.videoInfo['username']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  widget.videoInfo['caption']!,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Original Audio - ${widget.videoInfo['username']}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
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
