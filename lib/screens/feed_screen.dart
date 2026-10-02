import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/comments_bottom_sheet.dart';

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
            key: ValueKey(ad['id'] ?? index),
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
  int _likeCount = 54; // ከ 54 ጀምሮ የሚቆጥር የላይክ መጠን
  final int commentCount = 745;
  final int shareCount = 1809;

  @override
  void initState() {
    super.initState();
    _discAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _initializeVideo();
  }

  void _initializeVideo() {
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

      // ቪዲዮው ሲጫወት የጊዜ መስመሩ (Slider) አብሮ እንዲንቀሳቀስ Listener ተጨምሯል
      _videoController?.addListener(_videoListener);
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
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
        return const CommentsBottomSheet();
      },
    );
  }

  void _shareAd(String title, String text) {
    Share.share('ይህን አስደናቂ ማስታወቂያ ይመልከቱ፦ $title -$text');
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.templateJson['text'] ?? '';
    final phone = widget.templateJson['phone'] ?? '';
    final sticker = widget.templateJson['sticker'] ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. ቪዲዮ ማጫወቻው እና ስክሪኑን ሲነኩት Play/Pause የሚያደርግበት ሲስተም
        if (_videoController != null && isVideoInitialized)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.ይቅርታ አድርጉልኝ! በሲስተሙ ላይ በተፈጠረ አጭር ችግር ምክንያት ነው መልሱ የተቋረጠው። አሁን እንድታስደስቱኝ የፈለጋችሁትን የቪዲዮ የጊዜ መስመር (Video Progress Bar/Slider) ከነ ቪዲዮው ቆይታ ጋር አብሮ የሚሰራውን ሙሉ የ Flutter ኮድ ከዚህ በታች አዘጋጅቼላችሁሀለሁ።

እባክዎ የ **`lib/screens/feed_screen.dart`** ፋይል ውስጥ ያለውን ኮድ ሙሉ በሙሉ ከዚህ በታች ባለው አዲስ ኮድ ይተኩት፦

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/comments_bottom_sheet.dart';

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
            key: ValueKey(ad['id'] ?? index),
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
  int _likeCount = 54;
  final int commentCount = 745;
  final int shareCount = 1809;

  @override
  void initState() {
    super.initState();
    _discAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _initializeVideo();
  }

  void _initializeVideo() {
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

      // ቪዲዮው ሲጫወት የጊዜ መስመሩ እንዲንቀሳቀስ ማዳመጫ (Listener) ተጨምሯል
      _videoController?.addListener(_videoListener);
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
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

  // የሰዓት ቆጣሪ ቅርጸት ማስተካከያ (ለምሳሌ 00:15)
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
        return const CommentsBottomSheet();
      },
    );
  }

  void _shareAd(String title, String text) {
    Share.share('ይህን አስደናቂ ማስታወቂያ ይመልከቱ፦ $title -$text');
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.templateJson['text'] ?? '';
    final phone = widget.templateJson['phone'] ?? '';
    final sticker = widget.templateJson['sticker'] ?? '';

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. ቪዲዮ ማጫወቻ እና ስክሪኑን ሲነኩት Play/Pause የሚያደርግበት ሲስተም
        if (_videoController != null && isVideoInitialized)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_videoController!.value.isPlaying) {
                    _videoController!.pause();
                  } else {
                    _videoController!.play();
                  }
                });
              },
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
