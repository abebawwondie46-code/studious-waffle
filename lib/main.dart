import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const TikTokApp());
}

class TikTokApp extends StatelessWidget {
  const TikTokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikTok Full UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF2C55),
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
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    FriendsScreen(),
    SizedBox(), // Add Button Action
    InboxScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isWhiteBgScreen = _currentIndex == 3 || _currentIndex == 4;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 55,
        color: isWhiteBgScreen ? Colors.white : Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_filled, 'Home', 0, isWhiteBgScreen),
            _buildNavItem(Icons.people_outline, 'Friends', 1, isWhiteBgScreen),
            _buildAddButton(),
            _buildNavItem(Icons.chat_bubble_outline_rounded, 'Inbox', 3, isWhiteBgScreen, hasNotification: true),
            _buildNavItem(Icons.person_outline, 'Profile', 4, isWhiteBgScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isWhiteBg, {bool hasNotification = false}) {
    final isSelected = _currentIndex == index;
    Color activeColor = isWhiteBg ? Colors.black : Colors.white;
    Color inactiveColor = isWhiteBg ? Colors.black54 : Colors.white60;

    return GestureDetector(
      onTap: () {
        if (index != 2) {
          setState(() => _currentIndex = index);
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? activeColor : inactiveColor, size: 26),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          if (hasNotification)
            Positioned(
              right: 0,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(3.5),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF2C55),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: 45,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: const Center(
        child: Icon(Icons.add, color: Colors.black, size: 22),
      ),
    );
  }
}

// ==================== 1. HOME SCREEN & COMMENTS ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 4;

  Widget _buildHeaderTab(String label, int index) {
    final bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 2,
            width: 28,
            color: isSelected ? Colors.white : Colors.transparent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const VideoPlayerWidget(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.live_tv, color: Colors.white, size: 16),
                      ),
                      const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      _buildHeaderTab('STEM', 1),
                      const SizedBox(width: 12),
                      _buildHeaderTab('Community', 2),
                      const SizedBox(width: 12),
                      _buildHeaderTab('Following', 3),
                      const SizedBox(width: 12),
                      _buildHeaderTab('For You', 4),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({super.key});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late AnimationController _discController;
  bool _isLiked = false;
  bool _isSaved = false;
  int _likes = 48400;

  @override
  void initState() {
    super.initState();
    _discController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse('https://assets.mixkit.co/videos/preview/mixkit-tree-with-yellow-flowers-1173-large.mp4'),
    )..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _discController.dispose();
    super.dispose();
  }

  void _showCommentsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  const Text('583 comments ≡', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    _buildCommentTile('TEREFE🎵🎧', 'እውነት ለመናገር ሮበአ ጠካራው', '08-28', '193'),
                    _buildCommentTile('Wasinet Wada', 'ንቃቴ ህልና አሁን ወደርኩት እውነቱን ስላወራህ', '08-28', '120'),
                    _buildCommentTile('TEMESGEN MITIKU🥊', 'THE KING IS HERE 👑👑👑👑👏', '08-28', '15'),
                    _buildCommentTile('Lij_yohans🔥', 'slashenefk des blonal 🫡👏👏\nTemesgen ykrbh kebad new ‼️', '08-28', '42'),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.white,
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.green,
                      radius: 18,
                      child: Text('a', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const TextField(
                          style: TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Add comment...',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.image_outlined, color: Colors.black54),
                    const SizedBox(width: 8),
                    const Icon(Icons.emoji_emotions_outlined, color: Colors.black54),
                    const SizedBox(width: 8),
                    const Icon(Icons.alternate_email, color: Colors.black54),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentTile(String name, String comment, String date, String likes) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 18, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(comment, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(width: 12),
                    const Text('Reply', style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.favorite_border, size: 18, color: Colors.grey),
              Text(likes, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _controller.value.isInitialized
            ? AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))
            : const Center(child: CircularProgressIndicator(color: Colors.white)),
        Positioned(
          bottom: 15,
          left: 12,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('jemii_Jems', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              SizedBox(height: 4),
              Text('@💡NIKATEHILINA💡', style: TextStyle(color: Colors.white, fontSize: 15)),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.music_note, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('original sound - jemii_fn - ...', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 15,
          right: 12,
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: const CircleAvatar(radius: 22, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                  ),
                  const Positioned(
                    bottom: 0,
                    child: CircleAvatar(radius: 10, backgroundColor: Color(0xFFFF2C55), child: Icon(Icons.add, size: 14, color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _isLiked = !_isLiked),
                child: Column(
                  children: [
                    Icon(Icons.favorite, size: 36, color: _isLiked ? const Color(0xFFFF2C55) : Colors.white),
                    Text('${(_likes / 1000).toStringAsFixed(1)}K', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _showCommentsModal,
                child: const Column(
                  children: [
                    Icon(Icons.chat_bubble_rounded, size: 34, color: Colors.white),
                    Text('435', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _isSaved = !_isSaved),
                child: Column(
                  children: [
                    Icon(Icons.bookmark, size: 34, color: _isSaved ? Colors.amber : Colors.white),
                    const Text('4,491', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Column(
                children: [
                  Icon(Icons.reply_sharp, size: 36, color: Colors.white),
                  Text('906', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16),
              RotationTransition(
                turns: _discController,
                child: const CircleAvatar(radius: 14, backgroundColor: Colors.grey, child: Icon(Icons.music_note, size: 12, color: Colors.white)),
              ),
            ],
          ),
        )
      ],
    );
  }
}

// ==================== 2. FRIENDS SCREEN ====================
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(10.0),
          child: CircleAvatar(
            backgroundColor: Colors.green,
            child: Text('a', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ),
        title: const Text('Friends', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white, size: 28), onPressed: () {}),
        ],
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.cyan, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFFF2C55), shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}

// ==================== 3. INBOX SCREEN ====================
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.person_add_alt_1_outlined, color: Colors.black),
        title: const Text('Inbox •', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.black, size: 28), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.green,
                    child: Text('a', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.cyan, shape: BoxShape.circle),
                      child: const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Create', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          _buildInboxTile(Icons.person_outline, 'New followers', 'See your new followers here.'),
          _buildInboxTile(Icons.notifications_none, 'Activity', 'Team Work Family invited you to joi...'),
          _buildInboxTile(Icons.campaign_outlined, 'System notifications', 'Account updates: Communit... • 4d', hasRedDot: true),
        ],
      ),
    );
  }

  Widget _buildInboxTile(IconData icon, String title, String subtitle, {bool hasRedDot = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.grey.shade200,
            child: Icon(icon, color: Colors.black54, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          if (hasRedDot)
            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF2C55), shape: BoxShape.circle)),
        ],
      ),
    );
  }
}

// ==================== 4. PROFILE SCREEN & DRAWER ====================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      endDrawer: const SettingsDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Icon(Icons.edit_outlined, color: Colors.black),
        title: const Text('abee w. ▾', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          const Icon(Icons.qr_code_scanner, color: Colors.black),
          const SizedBox(width: 12),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          const CircleAvatar(
            radius: 42,
            backgroundColor: Colors.green,
            child: Text('a', style: TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          const Text('@abee1w0', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatColumn('1', 'Following'),
              _buildStatDivider(),
              _buildStatColumn('0', 'Followers'),
              _buildStatDivider(),
              _buildStatColumn('0', 'Likes'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('ኢትዮ ስራ ኮኔክት (Ethio Sira Connect)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
          const Text('ስራ ፈላጊና አሳሪን የሚያገናኝ መድረክ::', style: TextStyle(color: Colors.black54)),
          const Text('ለመመዝገብ:- t.me/Ethio_Sira_Connect_Bot', style: TextStyle(color: Colors.black87)),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_outline, color: Color(0xFFFF2C55), size: 18),
              SizedBox(width: 4),
              Text('TikTok Studio', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.grid_on, color: Colors.black),
              Icon(Icons.lock_outline, color: Colors.grey),
              Icon(Icons.bookmark_border, color: Colors.grey),
              Icon(Icons.favorite_border, color: Colors.grey),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey),
                const SizedBox(height: 12),
                const Text(
                  'What are some good photos\nyou\'ve taken recently?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF2C55),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () {},
                  child: const Text('Upload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 12, width: 1, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 24));
  }
}

// Drawer Side Panel
class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            const Text('Assets', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDrawerTile(Icons.account_balance_wallet_outlined, 'Balance'),
            const Divider(),
            const Text('Personal tools', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDrawerTile(Icons.history, 'Activity centre'),
            _buildDrawerTile(Icons.cloud_download_outlined, 'Offline videos'),
            _buildDrawerTile(Icons.qr_code_2, 'Your QR code'),
            const Divider(),
            const Text('Creation & business tools', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDrawerTile(Icons.star_outline, 'TikTok Studio'),
            _buildDrawerTile(Icons.settings_outlined, 'Settings and privacy'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(IconData icon, String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () {},
    );
  }
}
