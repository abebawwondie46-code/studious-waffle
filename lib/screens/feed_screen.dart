import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _ads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAds();
  }

  Future<void> _fetchAds() async {
    try {
      final response = await supabase.from('videos').select().order('created_at', ascending: false);
      setState(() {
        _ads = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.redAccent)),
      );
    }

    if (_ads.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('VibeShare AI', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black,
          centerTitle: true,
        ),
        body: const Center(
          child: Text('ምንም ማስታወቂያዎች የሉም።', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _ads.length,
        itemBuilder: (context, index) {
          final ad = _ads[index];
          return AdVideoItem(
            title: ad['title'] ?? '',
            videoUrl: ad['video_url'] ?? '',
            templateJson: ad['template_json'] ?? {},
          );
        },
      ),
    );
  }
}

class AdVideoItem extends StatefulWidget {
  final String title;
  final String videoUrl;
  final Map<String, dynamic> templateJson;

  const AdVideoItem({
    super.key,
    required this.title,
    required this.videoUrl,
    required this.templateJson,
  });

  @override
  State<AdVideoItem> createState() => _AdVideoItemState();
}

class _AdVideoItemState extends State<AdVideoItem> with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool isVideoInitialized = false;
  late AnimationController _discAnimController;

  bool _isLiked = false;
  int _likeCount = 44000;
  final int commentCount = 745;
  final int shareCount = 1809;

  @override
  void initState() {
    super.initState();
    _discAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    if (widget.videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          setState(() {
            isVideoInitialized = true;
          });
          _videoController?.play();
          _videoController?.setLooping(true);
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _discAnimController.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount++;
      } else {
        _likeCount--;
      }
    });
  }

  void _openCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('አስተያየቶች (Comments)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView(
                  children: const [
                    ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.redAccent, child: Text('አ')),
                      title: Text('በቀለ'),
                      subtitle: Text('በጣም አሪፍ ማስታወቂያ ነው! ቀጥበት።'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareAd(String title, String text) {
    Share.share('ይህን አስደናቂ ማስታወቂያ ይመልከቱ፦ $title - $text');
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.templateJson['text'] ?? '';
    final phone = widget.templateJson['phone'] ?? '';
    final sticker = widget.templateJson['sticker'] ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_videoController != null && isVideoInitialized)
          GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(widget.templateJson['colorStart'] ?? Colors.indigo.value),
                  Color(widget.templateJson['colorEnd'] ?? Colors.blueAccent.value),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),

        if (_videoController != null && isVideoInitialized && !_videoController!.value.isPlaying)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, size: 50, color: Colors.white),
            ),
          ),

        // የጽሁፍ እና የስልክ መረጃ ቦታ (ከታች ከፍ እንዲል ተደርጓል)
        Positioned(
          bottom: 110,
          left: 16,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sticker.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                  child: Text(sticker, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              const SizedBox(height: 8),
              Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final Uri launchUri = Uri(scheme: 'tel', path: phone);
                    await launchUrl(launchUri);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(phone, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // የቀኝဘက် አዝራሮች (ላይክ፣ ኮሜንት፣ ሼር)
        Positioned(
          right: 12,
          bottom: 115,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: CircleAvatar(radius: 20, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _toggleLike,
                child: Column(
                  children: [
                    Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.redAccent : Colors.white, size: 36),
                    const SizedBox(height: 4),
                    Text(_formatCount(_likeCount), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _openCommentsBottomSheet,
                child: Column(
                  children: [
                    const Icon(Icons.comment, color: Colors.white, size: 36),
                    const SizedBox(height: 4),
                    Text(_formatCount(commentCount), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _shareAd(widget.title, text),
                child: Column(
                  children: [
                    const Icon(Icons.share, color: Colors.white, size: 36),
                    const SizedBox(height: 4),
                    Text(_formatCount(shareCount), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              RotationTransition(
                turns: _discAnimController,
                child: Container(
                  width: 45,
                  height: 45,
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                  child: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.music_note, size: 16, color: Colors.white)),
                ),
class _AdVideoItemState extends State<AdVideoItem> with TickerProviderStateMixin {
  VideoPlayerController? _videoController;
  bool isVideoInitialized = false;
  late AnimationController _discAnimController;

  bool _isLiked = false;
  int _likeCount = 44000;
  final int commentCount = 745;
  final int shareCount = 1809;

  @override
  void initState() {
    super.initState();
    _discAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    if (widget.videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              isVideoInitialized = true;
            });
            _videoController?.play();
            _videoController?.setLooping(true);
          }
        });

      // ቪዲዮው ሲጫወት የጊዜ መስመሩ እና ሰዓቱ በቀጣይነት እንዲዘምን Listener ተጨምሯል
      _videoController?.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _discAnimController.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likeCount++;
      } else {
        _likeCount--;
      }
    });
  }

  void _openCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('አስተያየቶች (Comments)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView(
                  children: const [
                    ListTile(
                      leading: CircleAvatar(backgroundColor: Colors.redAccent, child: Text('አ')),
                      title: Text('በቀለ'),
                      subtitle: Text('በጣም አሪፍ ማስታወቂያ ነው[cite: 5]! ቀጥበት።'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareAd(String title, String text) {
    Share.share('ይህን አስደናቂ ማስታወቂያ ይመልከቱ፦ $title - $text');
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.templateJson['text'] ?? '';
    final phone = widget.templateJson['phone'] ?? '';
    final sticker = widget.templateJson['sticker'] ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_videoController != null && isVideoInitialized)
          GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(widget.templateJson['colorStart'] ?? Colors.indigo.value),
                  Color(widget.templateJson['colorEnd'] ?? Colors.blueAccent.value),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),

        if (_videoController != null && isVideoInitialized && !_videoController!.value.isPlaying)
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, size: 50, color: Colors.white),
            ),
          ),

        // የጽሁፍ እና የስልክ መረጃ ቦታ
        Positioned(
          bottom: 110,
          left: 16,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sticker.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                  child: Text(sticker, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              const SizedBox(height: 8),
              Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final Uri launchUri = Uri(scheme: 'tel', path: phone);
                    await launchUrl(launchUri);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(phone, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // የቀኝဘက် አዝራሮች (ላይክ፣ ኮሜንት፣ ሼር)
        Positioned(
          right: 12,
          bottom: 115,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: CircleAvatar(radius: 20, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _toggleLike,
                child: Column(
                  children: [
                    Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.redAccent : Colors.white, size: 36),
                    const SizedBox(height: 4),
                    Text(_formatCount(_likeCount), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _openCommentsBottomSheet,
                child: Column(
                  children: [
                    const Icon(Icons.comment, color: Colors.white, size: 36),
                    const SizedBox(height: 4),
                    Text(_formatCount(commentCount), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _shareAd(widget.title, text),
                child: Column(
                  children: [
                    const Icon(Icons.share, color: Colors.white, size: 36),
                    const SizedBox(height: 4),
                    Text(_formatCount(shareCount), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              RotationTransition(
                turns: _discAnimController,
                child: Container(
                  width: 45,
                  height: 45,
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                  child: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.music_note, size: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),

        // የቪዲዮ የጊዜ መስመር (Progress Bar) - አሁን በትክክል ይንቀሳቀሳል
        if (_videoController != null && isVideoInitialized)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_videoController!.value.position), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                      Text(_formatDuration(_videoController!.value.duration), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                VideoProgressIndicator(
                  _videoController!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.redAccent,
                    bufferedColor: Colors.white30,
                    backgroundColor: Colors.white10,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
