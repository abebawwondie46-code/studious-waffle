import 'package:flutter/material.dart';
import 'video_service.dart';
import 'poster_editor_screen.dart';

class TikTokFeedScreen extends StatefulWidget {
  const TikTokFeedScreen({Key? key}) : super(key: key);

  @override
  _TikTokFeedScreenState createState() => _TikTokFeedScreenState();
}

class _TikTokFeedScreenState extends State<TikTokFeedScreen> {
  final VideoService _videoService = VideoService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _videos = [];

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _videoService.fetchVideos();
      setState(() {
        _videos = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'የኢንተርኔት ግንኙነት አልተገኘም:: እባክዎን ኔትወርክዎን ያረጋግጡ::';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('kuanyngne Feed', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.amber, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PosterEditorScreen()),
              );
            },
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 70, color: Colors.amber),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadFeed,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              child: const Text('እንደገና ይሞክሩ'),
            ),
          ],
        ),
      );
    }

    if (_videos.isEmpty) {
      return const Center(child: Text('ምንም ቪዲዮ/ማስታወቂያ አልተገኘም::', style: TextStyle(color: Colors.white)));
    }

    return PageView.builder(
      scrollDirection: Axis.vertical,
      itemCount: _videos.length,
      itemBuilder: (context, index) {
        final item = _videos[index];
        return Stack(
          children: [
            // Video Background Placeholder
            Container(
              color: Colors.grey[900],
              child: Center(
                child: Text(
                  item['title'] ?? 'ቪዲዮ',
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            
            // Remix Button Overlay
            Positioned(
              bottom: 30,
              right: 20,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PosterEditorScreen(
                        remixedTemplateData: item['template_data'],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome, color: Colors.black),
                label: const Text('Remix Template', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              ),
            ),
          ],
        );
      },
    );
  }
}
