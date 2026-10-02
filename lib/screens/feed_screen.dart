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
      final response = await supabase.from('videos').select(); // የጠረጴዛህን (Table) ስም እንደአስፈላጊነቱ አስተካክለው
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
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('VibeShare AI', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          centerTitle: true,
        ),
        body: const Center(
          child: Text('ምንም ማስታወቂያዎች ወይም ቪዲዮዎች የሉም።', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
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
                              
