import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/ad_video_item.dart';

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
          title: const Text('KuanYngne Ads', style: TextStyle(fontWeight: FontWeight.bold)),
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
