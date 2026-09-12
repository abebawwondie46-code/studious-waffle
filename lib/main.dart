import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==================== MAIN ENTRY POINT ====================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Supabase ማስተካከያ (የራስህን URL እና Anon Key እዚህ ያስገቡ)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const ShortVideoApp());
}

class ShortVideoApp extends StatelessWidget {
  const ShortVideoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Short Video App',
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

// ==================== MAIN NAVIGATION SCREEN ====================
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
    SizedBox(), // Add Button Placeholder
    InboxScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    bool isWhiteBg = _currentIndex == 3 || _currentIndex == 4;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        height: 55,
        color: isWhiteBg ? Colors.white : Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_filled, 'Home', 0, isWhiteBg),
            _buildNavItem(Icons.people_outline, 'Friends', 1, isWhiteBg),
            _buildAddButton(),
            _buildNavItem(Icons.chat_bubble_outline, 'Inbox', 3, isWhiteBg),
            _buildNavItem(Icons.person_outline, 'Profile', 4, isWhiteBg),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isWhiteBg) {
    final isSelected = _currentIndex == index;
    Color activeColor = isWhiteBg ? Colors.black : Colors.white;
    Color inactiveColor = isWhiteBg ? Colors.black54 : Colors.white60;

    return GestureDetector(
      onTap: () {
        if (index != 2) {
          setState(() => _currentIndex = index);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? activeColor : inactiveColor, size: 24),
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
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: 45,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.add, color: Colors.black, size: 20),
      ),
    );
  }
}

// ==================== HOME SCREEN (VERTICAL VIDEO FEED) ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // የናሙና ቪዲዮዎች ዳታ (በኋላ ከ Supabase የሚመጣ)
  final List<Map<String, String>> _videoData = [
    {
      'videoUrl': 'https://assets.mixkit.co/videos/preview/mixkit-tree-with-yellow-flowers-1173-large.mp4',
      'username': '@chala_tech',
      'caption': 'አዲሱ አፕሊኬሽን ተለቀቀ! ሞክሩት 🔥 #tech #amharic',
      'music': 'Original Sound - Chala Tech'
    },
    {
      'videoUrl': 'https://assets.mixkit.co/videos/preview/mixkit-vertical-shot-of-a-waterfall-41525-large.mp4',
      'username': '@ethio_vibes',
      'caption': 'የተፈጥሮ ውበት በኢትዮጵያ 🇪🇹',
      'music': 'Abebe Tessema - Instrumental'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _videoData.length,
        itemBuilder: (context, index) {
          return SingleVideoItem(data: _videoData[index]);
        },
      ),
    );
  }
}

// ==================== SINGLE VIDEO PLAYER ITEM ====================
class SingleVideoItem extends StatefulWidget {
  final Map<String, String> data;
  const SingleVideoItem({super.key, required this.data});

  @override
  State<SingleVideoItem> createState() => _SingleVideoItemState();
}

class _SingleVideoItemState extends State<SingleVideoItem> {
  late VideoPlayerController _controller;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.data['videoUrl']!),
    )..initialize().then((_) {
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
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
        // 1. የቪዲዮ ማጫወቻ
        GestureDetector(
          onTap: () {
            setState(() {
              _controller.value.isPlaying ? _controller.pause() : _controller.play();
            });
          },
          child: _controller.value.isInitialized
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
              : const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),

        // 2. የቪዲዮ መረጃዎች (ከታች በስተግራ)
        Positioned(
          bottom: 20,
          left: 15,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.data['username']!,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                widget.data['caption']!,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.music_note, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    widget.data['music']!,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3. የተግባር ቁልፎች (ከታች በስተቀኝ)
        Positioned(
          bottom: 20,
          right: 15,
          child: Column(
            children: [
              IconButton(
                icon: Icon(
                  Icons.favorite,
                  color: _isLiked ? const Color(0xFFFF2C55) : Colors.white,
                  size: 35,
                ),
                onPressed: () {
                  setState(() => _isLiked = !_isLiked);
                },
              ),
              const Text('1.2K', style: TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(height: 15),
              IconButton(
                icon: const Icon(Icons.chat_bubble, color: Colors.white, size: 32),
                onPressed: () {},
              ),
              const Text('234', style: TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(height: 15),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white, size: 32),
                onPressed: () {},
              ),
              const Text('Share', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        )
      ],
    );
  }
}

// ==================== FRIENDS SCREEN ====================
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Friends Feed Screen', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ==================== INBOX SCREEN ====================
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Inbox', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('የመልእክት ሳጥን (Messages)', style: TextStyle(color: Colors.black)),
      ),
    );
  }
}

// ==================== PROFILE SCREEN ====================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('የእኔ ፕሮፋይል', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text('@username', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStat('0', 'Following'),
                const SizedBox(width: 30),
                _buildStat('0', 'Followers'),
                const SizedBox(width: 30),
                _buildStat('0', 'Likes'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String number, String label) {
    return Column(
      children: [
        Text(number, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
