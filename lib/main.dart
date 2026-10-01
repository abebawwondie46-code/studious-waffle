import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yszkonhhprwtavxywchz.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlzemtvbmhocHJ3dGF2eHl3Y2h6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3NjQxNDksImV4cCI6MjEwNjM0MDE0OX0.TXL0yzOlI3Kx5CyW6CvOsWMMc_wRafTVt7CcTxYev7E',
  );

  runApp(const KuanYngneApp());
}

class KuanYngneApp extends StatelessWidget {
  const KuanYngneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KuanYngne',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF101014),
        cardColor: const Color(0xFF1C1C24),
        colorScheme: const ColorScheme.dark(
          primary: Colors.redAccent,
          secondary: Colors.amber,
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
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const VideoFeedScreen(),
    const AdEditorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          backgroundColor: const Color(0xFF16161E),
          selectedItemColor: Colors.redAccent,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.style_outlined),
              activeIcon: Icon(Icons.style),
              label: 'Feed',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline, size: 30),
              activeIcon: Icon(Icons.add_circle, size: 30),
              label: 'Create Ad',
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 1. FEED SCREEN ====================
class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> allVideos = [];
  List<dynamic> filteredVideos = [];
  bool isLoading = true;
  bool isSearching = false;
  String errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final response = await supabase
          .from('videos')
          .select()
          .order('id', ascending: false);
      setState(() {
        allVideos = response;
        filteredVideos = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'መረጃዎችን ማምጣት አልተቻለም፡ $e';
      });
    }
  }

  void _universalSearch(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      setState(() {
        filteredVideos = allVideos;
      });
      return;
    }
    setState(() {
      filteredVideos = allVideos.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final rawTemplate = item['template_json'];
        String templateStr = '';
        if (rawTemplate != null) {
          templateStr = rawTemplate.toString().toLowerCase();
        }

        return title.contains(cleanQuery) || templateStr.contains(cleanQuery);
      }).toList();
    });
  }

  void _deleteAd(int id) async {
    try {
      await supabase.from('videos').delete().eq('id', id);
      setState(() {
        allVideos.removeWhere((item) => item['id'] == id);
        filteredVideos.removeWhere((item) => item['id'] == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ማስታወቂያው በትክክል ተሰርዟል!'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ማጥፋት አልተቻለም: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'ማንኛውንም ነገር ይፈልጉ...',
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                  border: InputBorder.none,
                ),
                onChanged: _universalSearch,
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt, color: Colors.amber, size: 24),
                  SizedBox(width: 6),
                  Text(
                    'KuanYngne Ads',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                ],
              ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search,
                color: Colors.white),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  _searchController.clear();
                  filteredVideos = allVideos;
                }
              });
            },
          ),
          if (!isSearching)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchVideos,
            )
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent))
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.redAccent, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchVideos,
                          icon: const Icon(Icons.refresh),
                          label: const Text('እንደገና ሞክር'),
                        )
                      ],
                    ),
                  ),
                )
              : filteredVideos.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ምንም ማስታወቂያ አልተገኘም።',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _fetchVideos,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          )
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchVideos,
                      child: PageView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: filteredVideos.length,
                        itemBuilder: (context, index) {
                          return AdCard(
                            key: ValueKey(filteredVideos[index]['id']),
                            adData: filteredVideos[index],
                            onDelete: () =>
                                _deleteAd(filteredVideos[index]['id']),
                          );
                        },
                      ),
                    ),
    );
  }
}

class AdCard extends StatefulWidget {
  final dynamic adData;
  final VoidCallback onDelete;
  const AdCard({super.key, required this.adData, required this.onDelete});

  @override
  State<AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<AdCard> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool isLiked = false;
  int likeCount = 44000;
  int commentCount = 745;
  int shareCount = 1809;
  bool isVideoInitialized = false;

  bool showControls = false;
  bool showHeartAnim = false;
  Timer? _hideControlsTimer;
  late AnimationController _discAnimController;

  final List<String> commentsList = [
    'በጣም አሪፍ ማስታወቂያ ነው!',
    'ዋጋው ስንት ነው?',
    'አድራሻችሁ የት ነው?',
    'አሪፍ አገልግሎት ነው በርቱ!'
  ];
  final TextEditingController _commentInputController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _discAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    final String videoUrl = widget.adData['video_url'] ?? '';
    if (videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              isVideoInitialized = true;
            });
            _videoController!.setLooping(true);
            _videoController!.play();

            _videoController!.addListener(() {
              if (mounted) {
                setState(() {});
              }
            });
          }
        });
    }
  }

  @override
  void dispose() {
    _discAnimController.dispose();
    _hideControlsTimer?.cancel();
    _videoController?.dispose();
    _commentInputController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _discAnimController.stop();
        showControls = true;
        _hideControlsTimer?.cancel();
      } else {
        _videoController!.play();
        _discAnimController.repeat();
        showControls = true;
        _startHideControlsTimer();
      }
    });
  }

  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      if (isLiked) {
        likeCount += 1;
      } else {
        likeCount -= 1;
      }
    });
  }

  void _onDoubleTap() {
    setState(() {
      if (!isLiked) {
        isLiked = true;
        likeCount += 1;
      }
      showHeartAnim = true;
    });
    Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          showHeartAnim = false;
        });
      }
    });
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E28),
        title: const Text('ማስታወቂያውን ላጥፋው?'),
        content: const Text('ይህንን ማስታወቂያ ሙሉ በሙሉ ማጥፋት ይፈልጋሉ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ተው', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 2), () {
      if (mounted &&
          _videoController != null &&
          _videoController!.value.isPlaying) {
        setState(() {
          showControls = false;
        });
      }
    });
  }

  void _openCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181820),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'አስተያየቶች ($commentCount)',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: commentsList.length,
                      itemBuilder: (context, idx) {
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.redAccent,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            commentsList[idx],
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentInputController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'አስተያየት ይፃፉ...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF252532),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.redAccent),
                        onPressed: () {
                          if (_commentInputController.text.trim().isNotEmpty) {
                            setModalState(() {
                              commentsList.add(_commentInputController.text);
                              commentCount++;
                            });
                            setState(() {});
                            _commentInputController.clear();
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _shareAd(String title, String text) {
    Share.share('$title\n\n$text\n\nየተፈጠረው በ KuanYngne App ነው!');
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.adData['title'] ?? 'ማስታወቂያ';
    final videoUrl = widget.adData['video_url'] ?? '';
    final templateJson = widget.adData['template_json'];

    Map<String, dynamic>? templateData;
    if (templateJson != null) {
      if (templateJson is String) {
        try {
          templateData = jsonDecode(templateJson);
        } catch (_) {}
      } else {
        templateData = Map<String, dynamic>.from(templateJson);
      }
    }

    final int startColorVal =
        templateData?['colorStart'] ?? Colors.indigo.value;
    final int endColorVal =
        templateData?['colorEnd'] ?? Colors.blueAccent.value;
    final String phone = templateData?['phone'] ?? '';
    final String text = templateData?['text'] ?? '';
    final String sticker = templateData?['sticker'] ?? '';

    return Stack(
      children: [
        // 1. Fullscreen Video / Poster Background with Single Tap Pause/Play
        Positioned.fill(
          child: GestureDetector(
            onTap: _togglePlayPause,
            onDoubleTap: _onDoubleTap,
            onLongPress: _showDeleteDialog,
            child: videoUrl.isNotEmpty
                ? (isVideoInitialized && _videoController != null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _videoController!.value.size.width,
                                height: _videoController!.value.size.height,
                                child: VideoPlayer(_videoController!),
                              ),
                            ),
                          ),
                          if (showHeartAnim)
                            const Icon(
                              Icons.favorite,
                              color: Colors.redAccent,
                              size: 110,
                            ),
                          if (showControls)
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: showControls ? 1.0 : 0.0,
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _videoController!.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  size: 55,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                            color: Colors.redAccent)))
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(startColorVal), Color(endColorVal)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (sticker.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black38,
                                        blurRadius: 10,
                                        offset: Offset(0, 4))
                                  ],
                                ),
                                child: Text(
                                  sticker,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 30),
                            Text(
                              text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.3,
                                shadows: [
                                  Shadow(
                                      color: Colors.black45,
                                      blurRadius: 10,
                                      offset: Offset(0, 3))
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            if (phone.isNotEmpty)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 8,
                                ),
                                onPressed: () => _makePhoneCall(phone),
                                icon: const Icon(Icons.phone,
                                    color: Colors.white),
                                label: Text(
                                  phone,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),

        // Gradient Overlay
        if (videoUrl.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black26,
                      Colors.transparent,
                      Colors.black87,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

        // Bottom Left Info Area
        Positioned(
          bottom: 25,
          left: 16,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sticker.isNotEmpty && videoUrl.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4)
                    ],
                  ),
                  child: Text(
                    sticker,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.verified,
                      color: Colors.blueAccent, size: 18),
                ],
              ),
              const SizedBox(height: 6),
              if (text.isNotEmpty && videoUrl.isNotEmpty)
                Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                ),
              const SizedBox(height: 6),
              if (phone.isNotEmpty && videoUrl.isNotEmpty)
                InkWell(
                  onTap: () => _makePhoneCall(phone),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Call Now: $phone',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Right Action Bar
        Positioned(
          bottom: 25,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      image: const DecorationImage(
                        image: NetworkImage(
                            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.add, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Like Button with Heart Outline / Filled Red Heart
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 36,
                icon: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.redAccent : Colors.white,
                ),
                onPressed: _toggleLike,
              ),
              Text(
                _formatCount(likeCount),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Comment Button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 32,
                icon: const Icon(Icons.comment_rounded, color: Colors.white),
                onPressed: _openCommentsBottomSheet,
              ),
              Text(
                '$commentCount',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Share Button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 38,
                icon: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(3.14159),
                  child: const Icon(
                    Icons.reply_all_rounded,
                    color: Colors.white,
                  ),
                ),
                onPressed: () => _shareAd(title, text),
              ),
              Text(
                '$shareCount',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Remix Button
              FloatingActionButton.small(
                heroTag: null,
                backgroundColor: Colors.redAccent,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AdEditorScreen(initialTemplate: templateData),
                    ),
                  );
                },
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Disc Animation
              RotationTransition(
                turns: _discAnimController,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade800, width: 6),
                    image: const DecorationImage(
                      image: NetworkImage(
                          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=100'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Exact Video Progress Timeline Line
        if (videoUrl.isNotEmpty &&
            isVideoInitialized &&
            _videoController != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 2.5,
              child: VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.redAccent,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ==================== 2. AD EDITOR SCREEN ====================
class AdEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? initialTemplate;
  const AdEditorScreen({super.key, this.initialTemplate});

  @override
  State<AdEditorScreen> createState() => _AdEditorScreenState();
}

class _AdEditorScreenState extends State<AdEditorScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  File? _selectedVideoFile;
  VideoPlayerController? _previewVideoController;

  int _selectedPresetIndex = 0;
  String _selectedSticker = 'Telebirr Accepted';
  bool _isPublishing = false;

  final List<Map<String, dynamic>> _colorPresets = [
    {
      'name': 'Dark Indigo',
      'start': const Color(0xFF283593).value,
      'end': const Color(0xFF1A237E).value
    },
    {
      'name': 'Sunset Gold',
      'start': const Color(0xFFFF8F00).value,
      'end': const Color(0xFFFF3D00).value
    },
    {
      'name': 'Emerald Green',
      'start': const Color(0xFF00897B).value,
      'end': const Color(0xFF004D40).value
    },
    {
      'name': 'Neon Purple',
      'start': const Color(0xFF8E24AA).value,
      'end': const Color(0xFF4A148C).value
    },
    {
      'name': 'Ocean Blue',
      'start': const Color(0xFF0288D1).value,
      'end': const Color(0xFF01579B).value
    },
    {
      'name': 'Deep Crimson',
      'start': const Color(0xFFC62828).value,
      'end': const Color(0xFF880E4F).value
    },
  ];

  final List<String> _stickers = [
    'Telebirr Accepted',
    'CBE Birr',
    '50% DISCOUNT',
    'SPECIAL OFFER',
    'CALL NOW',
    'HOT DEAL 🔥',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialTemplate != null) {
      _textController.text = widget.initialTemplate!['text'] ?? '';
      _phoneController.text = widget.initialTemplate!['phone'] ?? '';
      _selectedSticker = widget.initialTemplate!['sticker'] ?? _stickers.first;
    } else {
      _textController.text = 'የማስታወቂያ መልዕክትዎን እዚህ ይፃፉ...';
    }
  }

  @override
  void dispose() {
    _previewVideoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      setState(() {
        _selectedVideoFile = File(video.path);
      });

      _previewVideoController?.dispose();
      _previewVideoController = VideoPlayerController.file(_selectedVideoFile!)
        ..initialize().then((_) {
          setState(() {});
          _previewVideoController!.setLooping(true);
          _previewVideoController!.play();
        });
    }
  }

  Future<void> _publishAd() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('እባክዎን ለማስታወቂያው ርዕስ (Title) ያስገቡ!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    String uploadedVideoUrl = '';

    try {
      if (_selectedVideoFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
        await supabase.storage
            .from('videos')
            .upload(fileName, _selectedVideoFile!);

        uploadedVideoUrl =
            supabase.storage.from('videos').getPublicUrl(fileName);
      }

      final selectedPreset = _colorPresets[_selectedPresetIndex];
      final templateMap = {
        'text': _textController.text,
        'phone': _phoneController.text,
        'sticker': _selectedSticker,
        'colorStart': selectedPreset['start'],
        'colorEnd': selectedPreset['end'],
      };

      await supabase.from('videos').insert({
        'title': _titleController.text.trim(),
        'video_url': uploadedVideoUrl,
        'template_json': templateMap,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 ማስታወቂያዎ በትክክል ተለጥፏል!'),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        setState(() {
          _selectedVideoFile = null;
          _previewVideoController?.dispose();
          _previewVideoController = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('መለጠፍ አልተቻለም: $e')),
        );
      }
    } finally {
      setState(() {
        _isPublishing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePreset = _colorPresets[_selectedPresetIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Poster / Video Ad',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF16161E),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _isPublishing
                ? const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.greenAccent),
                      ),
                      SizedBox(width: 8),
                      Text('Uploading...',
                          style: TextStyle(
                              color: Colors.greenAccent, fontSize: 13)),
                    ],
                  )
                : TextButton.icon(
                    onPressed: _publishAd,
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.greenAccent, size: 20),
                    label: const Text(
                      'Publish',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview Canvas
              Container(
                width: double.infinity,
                height: 260,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: _selectedVideoFile == null
                      ? LinearGradient(
                          colors: [
                            Color(activePreset['start']),
                            Color(activePreset['end']),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Color(activePreset['start']).withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      if (_selectedVideoFile != null &&
                          _previewVideoController != null &&
                          _previewVideoController!.value.isInitialized)
                        SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _previewVideoController!.value.size.width,
                              height:
                                  _previewVideoController!.value.size.height,
                              child: VideoPlayer(_previewVideoController!),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 15.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_selectedSticker.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      _selectedSticker,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 15),
                                Text(
                                  _textController.text.isEmpty
                                      ? 'የማስታወቂያ ጽሁፍ...'
                                      : _textController.text,
                                  textAlign: TextAlign.center,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.video_call,
                              color: Colors.redAccent),
                          label: Text(_selectedVideoFile == null
                              ? 'ቪዲዮ ምረጥ'
                              : 'ቪዲዮ ቀይር'),
                        ),
                      )
                    ],
                  ),
                ),
              ),

              // Inputs Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'የማስታወቂያው ርዕስ (Title)',
                        prefixIcon:
                            const Icon(Icons.title, color: Colors.redAccent),
                        filled: true,
                        fillColor: const Color(0xFF1E1E28),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'የማስታወቂያ መልዕክት/ፅሁፍ',
                        prefixIcon:
                            const Icon(Icons.edit_note, color: Colors.amber),
                        filled: true,
                        fillColor: const Color(0xFF1E1E28),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'የስልክ ቁጥር (Contact)',
                        prefixIcon: const Icon(Icons.phone_android,
                            color: Colors.greenAccent),
                        filled: true,
                        fillColor: const Color(0xFF1E1E28),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (_selectedVideoFile == null) ...[
                      const Text(
                        'የጀርባ ዲዛይን/ከለር ይምረጡ:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _colorPresets.length,
                          itemBuilder: (context, index) {
                            final preset = _colorPresets[index];
                            final isSelected = _selectedPresetIndex == index;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPresetIndex = index;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 12),
                                width: isSelected ? 52 : 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(preset['start']),
                                      Color(preset['end'])
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 22)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],
                    const Text(
                      'ስቲከር / ባጅ ይምረጡ:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: _stickers.map((sticker) {
                        final isSelected = _selectedSticker == sticker;
                        return ChoiceChip(
                          label: Text(sticker),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          selected: isSelected,
                          selectedColor: Colors.amber,
                          backgroundColor: const Color(0xFF252532),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedSticker = sticker;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
