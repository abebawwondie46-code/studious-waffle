import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/ad_video_item.dart'; // Contains the video player and control components

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
      // Fetch video data from Supabase
      final response = await supabase.from('videos').select();
      setState(() {
        _ads = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Failed to load videos due to no internet connection or error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        ),
      );
    }

    if (_ads.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('kuanyngne', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'No videos found.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    // Display videos vertically in sequential order
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _ads.length,
        itemBuilder: (context, index) {
          final ad = _ads[index];
          return AdVideoItem(
            key: ValueKey(ad['id'] ?? index),
            caption: ad['caption'] ?? '', // <--- እዚህ ጋር caption ተስተካክሏል
            videoUrl: ad['video_url'] ?? '',
            templateJson: ad['template_json'] ?? {},
            videoId: ad['id']?.toString(), // Video ID ን ማስተላለፍ ለላይክ/ኮሜንት ይጠቅማል
          );
        },
      ),
    );
  }
}
