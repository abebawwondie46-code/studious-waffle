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

    return Scaffold(
      backgroundColor: Colors.black,
      // ከላይ አናት ላይ Search እና ከጎኑ የ Feed አዝራር እንዲኖር የተደረገበት AppBar
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('kuanyngne', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // ከላይ አናት ላይ ከሰርች አጠገብ (በግራ በኩል ጫፍ ላይ) የተተከለው የ Feed / Explore አዝራር
          IconButton(
            icon: const Icon(Icons.dynamic_feed_rounded, color: Colors.redAccent),
            tooltip: 'Feed',
            onPressed: () {
              // እዚህ ጋር ወደ ፖስተሮች/ፎቶዎች ፊድ ወይም የሚፈልጉት ገጽ መሸጋገሪያ ማስቀመጥ ይቻላል
            },
          ),
          // የሰርች አዝራር (Search)
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Search functionality
            },
          ),
        ],
      ),
      body: _ads.isEmpty
          ? const Center(
              child: Text(
                'No videos found.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _ads.length,
              itemBuilder: (context, index) {
                final ad = _ads[index];
                return AdVideoItem(
                  key: ValueKey(ad['id'] ?? index),
                  caption: ad['caption'] ?? '',
                  videoUrl: ad['video_url'] ?? '',
                  templateJson: ad['template_json'] ?? {},
                  videoId: ad['id']?.toString(),
                );
              },
            ),
    );
  }
}
