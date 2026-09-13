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

            // 2. MIDDLE SECTION (SIDEBAR & PRO CANVAS)
            Expanded(
              child: Row(
                children: [
                  // LEFT SIDEBAR COMPONENTS
                  Container(
                    width: 145,
                    color: const Color(0xFF181A20),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      children: [
                        // (+) Upload Video Component
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

                  // CENTER CANVAS (PRO CLEAN VIDEO PLAYER DISPLAY)
                  Expanded(
                    child: Container(
                      color: const Color(0xFF0F1015),
                      padding: const EdgeInsets.all(10),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 9 / 18,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: const Color(0xFF3B404E), width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.7),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(19),
                              child: Column(
                                children: [
                                  // MOBILE FRAME TOP BAR (DYNAMIC ISLAND + STATUS BAR)
                                  Container(
                                    height: 26,
                                    color: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Row(
                                      children: [
                                        const Text('1:37', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                        const Spacer(),
                                        // Dynamic Notch / Camera Hole
                                        Container(
                                          width: 45,
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E1E1E),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        const Spacer(),
                                        const Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 10),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.wifi, color: Colors.white, size: 10),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.battery_full, color: Colors.white, size: 10),
                                      ],
                                    ),
                                  ),
                                  // ULTRA CLEAN HD VIDEO PLAYER
                                  const Expanded(child: CleanProVideoPlayer()),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  
                  // RUN BUTTON
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
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Building VibeShare Pro App...')),
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
}

// ==================== ULTRA PRO VIDEO PLAYER CANVAS ====================
class CleanProVideoPlayer extends StatefulWidget {
  const CleanProVideoPlayer({super.key});

  @override
  State<CleanProVideoPlayer> createState() => _CleanProVideoPlayerState();
}

class _CleanProVideoPlayerState extends State<CleanProVideoPlayer> {
  late VideoPlayerController _controller;
  bool _showControls = true;
  bool _isMuted = false;
  bool _showHeartAnimation = false;

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

  void _triggerDoubleTapLike() {
    setState(() {
      _showHeartAnimation = true;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _showHeartAnimation = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      onDoubleTap: _triggerDoubleTapLike,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. CLEAN VIDEO DISPLAY
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

          // 2. DOUBLE TAP LIKE ANIMATION
          if (_showHeartAnimation)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.2),
              duration: const Duration(milliseconds: 300),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: const Icon(Icons.favorite, color: Colors.redAccent, size: 80),
                );
              },
            ),

          // 3. PRO CONTROLS OVERLAY
          if (_showControls && _controller.value.isInitialized)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: Colors.black38,
              child: Stack(
                children: [
                  // Top Quick Action (Mute Button)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white, size: 20),
                      onPressed: () {
                        setState(() {
                          _isMuted = !_isMuted;
                          _controller.setVolume(_isMuted ? 0 : 1);
                        });
                      },
                    ),
                  ),

                  // Center Play/Pause Button
                  Center(
                    child: IconButton(
                      iconSize: 48,
                      icon: Icon(
                        _controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                        });
                      },
                    ),
                  ),

                  // Bottom Gradient Progress Bar & Timer
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: 10,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_controller.value.position),
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatDuration(_controller.value.duration),
                              style: const TextStyle(color: Colors.white70, fontSize: 9),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Color(0xFFBAC7FF),
                            bufferedColor: Colors.white30,
                            backgroundColor: Colors.white12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
