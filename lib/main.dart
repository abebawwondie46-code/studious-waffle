import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const SketchwareTikTokApp());
}

class SketchwareTikTokApp extends StatelessWidget {
  const SketchwareTikTokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sketchware Style Video Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121418), // Sketchware Dark Background
        primaryColor: const Color(0xFF1F222A),
        cardColor: const Color(0xFF1D2027),
      ),
      home: const SketchwareMainEditor(),
    );
  }
}

class SketchwareMainEditor extends StatefulWidget {
  const SketchwareMainEditor({super.key});

  @override
  State<SketchwareMainEditor> createState() => _SketchwareMainEditorState();
}

class _SketchwareMainEditorState extends State<SketchwareMainEditor> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedBottomIndex = 0;

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
      // 1. SKETCHWARE TOP TOOLBAR
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F222A),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {},
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'vibe_share_studio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '601 • Video Project',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.undo, color: Colors.grey), onPressed: () {}),
          IconButton(icon: const Icon(Icons.redo, color: Colors.grey), onPressed: () {}),
          IconButton(icon: const Icon(Icons.save, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4C8CFA),
          labelColor: const Color(0xFF4C8CFA),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'View'),
            Tab(text: 'Event'),
            Tab(text: 'Component'),
          ],
        ),
      ),

      // 2. MAIN BODY (LEFT WIDGET PANEL + CENTER CANVAS)
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // የጎን SKETCHWARE WIDGET PALETTE (Left Sidebar)
                Container(
                  width: 140,
                  color: const Color(0xFF191B20),
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      const Text('Layouts', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      _buildSketchwareWidgetItem(Icons.table_rows_outlined, 'Linear(H)'),
                      _buildSketchwareWidgetItem(Icons.view_stream_outlined, 'Linear(V)'),
                      _buildSketchwareWidgetItem(Icons.swap_vert_outlined, 'Scroll(V)'),
                      const Divider(color: Colors.white24),
                      const Text('Media & Video', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      _buildSketchwareWidgetItem(Icons.play_circle_fill, 'VideoFeed'),
                      _buildSketchwareWidgetItem(Icons.music_note, 'AudioTrack'),
                      _buildSketchwareWidgetItem(Icons.subtitles, 'SubtitleUI'),
                      const Divider(color: Colors.white24),
                      const Text('Widgets', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      _buildSketchwareWidgetItem(Icons.text_fields, 'TextView'),
                      _buildSketchwareWidgetItem(Icons.favorite, 'LikeButton'),
                      _buildSketchwareWidgetItem(Icons.comment, 'CommentBox'),
                    ],
                  ),
                ),

                // የመሃከለኛው CANVAS / MOBILE PREVIEW (የቲክቶክ ቪዲዮ የሚያሳየው ክፍል)
                Expanded(
                  child: Container(
                    color: const Color(0xFF121418),
                    child: Center(
                      child: Container(
                        width: 280,
                        height: 520,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF333842), width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: const MobileVideoCanvas(),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. BOTTOM RUN BUTTON BAR (Sketchware Style)
          Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: const Color(0xFF1F222A),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: 'main.xml',
                  dropdownColor: const Color(0xFF1F222A),
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: const [
                    DropdownMenuItem(value: 'main.xml', child: Text('main.xml')),
                    DropdownMenuItem(value: 'video_feed.xml', child: Text('video_feed.xml')),
                  ],
                  onChanged: (val) {},
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C8CFA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {
                    // RUN / PLAY ACTION
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Building and Loading Video Engine...')),
                    );
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                  label: const Text('Run', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSketchwareWidgetItem(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF252830),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF333842)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4C8CFA)),
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

// ==================== MOBILE CANVAS WITH VIDEO PLAYER (5 MIN SUPPORT) ====================
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
    // እስከ 5 ደቂቃ ያሉ ረጅም ቪዲዮዎችን በለስላሳ ሁኔታ ለማጫወት
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
            : const Center(child: CircularProgressIndicator(color: Color(0xFF4C8CFA))),

        // 2. SKETCHWARE OVERLAY GRID (አፑ የዲዛይን ኤዲተር እንደሆነ የሚያሳይ መስመር)
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.withOpacity(0.15), width: 1),
            ),
          ),
        ),

        // 3. VIDEO CONTROLS & INFO OVERLAY (የቲክቶክ አይነት ቁልፎች)
        Positioned(
          bottom: 25,
          left: 10,
          right: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                '@sketch_creator',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'በ Sketchware አቀማመጥ የተሰራ አዲስ የቪዲዮ አፕ! 🚀 #flutter #tech',
                style: TextStyle(color: Colors.white70, fontSize: 11),
                maxLines: 2,
              ),
            ],
          ),
        ),

        // 4. RIGHT SIDE BUTTONS
        Positioned(
          bottom: 25,
          right: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.favorite, color: _isLiked ? Colors.red : Colors.white, size: 24),
                onPressed: () => setState(() => _isLiked = !_isLiked),
              ),
              const Text('2.4k', style: TextStyle(color: Colors.white, fontSize: 10)),
              const SizedBox(height: 10),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 22),
                onPressed: () {},
              ),
              const Text('180', style: TextStyle(color: Colors.white, fontSize: 10)),
            ],
          ),
        ),

        // 5. 5-MINUTE VIDEO PROGRESS BAR (ከታች የሚሄድ የጊዜ መስመር)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            _controller,
            allowScrubbing: true, // ተጠቃሚው እስከ 5 ደቂቃ ያለውን ቪዲዮ ወደፊት/ወደኋላ እንዲስብ ያደርጋል
            colors: const VideoProgressColors(
              playedColor: Color(0xFF4C8CFA),
              bufferedColor: Colors.white24,
              backgroundColor: Colors.black26,
            ),
          ),
        ),
      ],
    );
  }
}
