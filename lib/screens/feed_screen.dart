import 'dart:async';
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

  // የአሁኑ ተጠቃሚ ፕሮፋይል መረጃ
  String _profileName = 'Community Creator';
  String _profileAvatar = '';
  String _creatorId = '';

  @override
  void initState() {
    super.initState();
    _fetchProfileAndAds();
  }

  Future<void> _fetchProfileAndAds() async {
    try {
      try {
        final profileRes = await supabase
            .from('profiles')
            .select('id, full_name, avatar_url')
            .maybeSingle();
        
        if (profileRes != null) {
          setState(() {
            _creatorId = profileRes['id']?.toString() ?? '';
            _profileName = profileRes['full_name'] ?? 'Community Creator';
            _profileAvatar = profileRes['avatar_url'] ?? '';
          });
        }
      } catch (_) {}

      final response = await supabase.from('videos').select();
      
      List<Map<String, dynamic>> fetchedAds = List<Map<String, dynamic>>.from(response);

      // ዳታቤዙ ባዶ ከሆነ 1 ካርድ እንፈጥራለን
      if (fetchedAds.isEmpty) {
        fetchedAds = [
          {
            'id': 'dummy_chat_card',
          }
        ];
      }

      setState(() {
        _ads = fetchedAds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _ads = [
          {
            'id': 'dummy_chat_card',
          }
        ];
        _isLoading = false;
      });
      debugPrint('Failed to load data: $e');
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false, // 🛑 የግራውን አዶ ሙሉ በሙሉ አጥፍተነዋል
        title: const Text(
          'kuanyngne',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: const [], // 🛑 የሰርች አዝራሩን ሙሉ በሙሉ አጥፍተነዋል
      ),
      body: _ads.isEmpty
          ? AdVideoItem(
              userAvatar: _profileAvatar,
              userName: _profileName,
              creatorId: _creatorId,
            )
          : PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: _ads.length,
              itemBuilder: (context, index) {
                return AdVideoItem(
                  userAvatar: _profileAvatar,
                  userName: _profileName,
                  creatorId: _creatorId,
                );
              },
            ),
    );
  }
}
