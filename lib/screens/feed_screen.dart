import 'package:flutter/material.dart';
import '../widgets/ad_video_item.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // 🛑 ምንም አይነት የሰርቨር ጥያቄ (Network request) የለም!
  final String _profileName = 'Community Creator';
  final String _profileAvatar = '';
  final String _creatorId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        title: const Text(
          'kuanyngne',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: AdVideoItem(
        userAvatar: _profileAvatar,
        userName: _profileName,
        creatorId: _creatorId,
      ),
    );
  }
}
