import 'package:flutter/material.dart';

void main() {
  runApp(const KuanyngneApp());
}

class KuanyngneApp extends StatelessWidget {
  const KuanyngneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'kuanyngne',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const FeedScreen(),
    );
  }
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  int _selectedBottomIndex = 0;
  bool _isLiked = false;
  int _likeCount = 12500;
  bool _isSaved = false;
  int _saveCount = 2409;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Video Player Area (Background)
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.movie_creation_outlined, size: 80, color: Colors.white54),
                  SizedBox(height: 12),
                  Text(
                    'Video Playing...',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // 2. Gradient Overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 3. Top Navigation Bar (LIVE | Community | Following | For You + Search)
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              children: [
                const Icon(Icons.live_tv, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _topNavText('Community', false),
                      const SizedBox(width: 12),
                      _topNavText('Following', false),
                      const SizedBox(width: 12),
                      _topNavText('For You', true),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white, size: 26),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // 4. Right Side Actions (Profile, Like, Comment, Save, Share, Audio Disc)
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              children: [
                // Profile Avatar with Plus Badge
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    Positioned(
                      bottom: -8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Like Button
                _actionButton(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  iconColor: _isLiked ? Colors.redAccent : Colors.white,
                  label: _formatCount(_likeCount),
                  onTap: () {
                    setState(() {
                      _isLiked = !_isLiked;
                      _isLiked ? _likeCount++ : _likeCount--;
                    });
                  },
                ),

                // Comment Button
                _actionButton(
                  icon: Icons.comment_rounded,
                  label: '458',
                  onTap: () {},
                ),

                // Save / Bookmark Button
                _actionButton(
                  icon: _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  iconColor: _isSaved ? Colors.yellow : Colors.white,
                  label: _formatCount(_saveCount),
                  onTap: () {
                    setState(() {
                      _isSaved = !_isSaved;
                      _isSaved ? _saveCount++ : _saveCount--;
                    });
                  },
                ),

                // Share Button
                _actionButton(
                  icon: Icons.shortcut_rounded,
                  label: '751',
                  onTap: () {},
                ),

                const SizedBox(height: 8),

                // Rotating Audio Disc
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: const Icon(Icons.music_note, size: 18, color: Colors.white),
                ),
              ],
            ),
          ),

          // 5. Left Side Info (Username, Caption, Audio Title)
          Positioned(
            left: 16,
            right: 80,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '@kuanyngne_official',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Welcome to kuanyngne! Professional 5-Minute HD Video Sharing Feed 🔥 #kuanyngne #viral',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.music_note, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Original Audio - kuanyngne Sound',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      // 6. Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedBottomIndex,
        onTap: (index) => setState(() => _selectedBottomIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Container(
              width: 45,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, color: Colors.black),
            ),
            label: '',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Inbox',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _topNavText(String text, bool isActive) {
    return Text(
      text,
      style: TextStyle(
        color: isActive ? Colors.white : Colors.white60,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        fontSize: isActive ? 16 : 14,
        decoration: isActive ? TextDecoration.underline : TextDecoration.none,
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, size: 34, color: iconColor),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
