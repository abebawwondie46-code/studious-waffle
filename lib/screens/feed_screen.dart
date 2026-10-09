import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/ad_video_item.dart';
import 'explore_feed_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _ads = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = true;
  bool _isLoadingSearch = false;
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAdsWithProfiles();
  }

  // ቪዲዮዎችን ከ profiles ቴብል ጋር (Join በማድረግ) ስም እና ፎቶ አብሮ ማምጣት
  Future<void> _fetchAdsWithProfiles() async {
    try {
      final response = await supabase.from('videos').select();
      
      // የፕሮፋይል መረጃዎችን (ስም እና ፎቶ) ከ profiles ቴብል ማምጣት
      Map<String, dynamic> profileData = {};
      try {
        final profileRes = await supabase
            .from('profiles')
            .select('full_name, avatar_url')
            .maybeSingle();
        if (profileRes != null) {
          profileData = profileRes;
        }
      } catch (_) {}

      // እያንዳንዱን ቪዲዮ ከፕሮፋይል መረጃ ጋር ማቀናጀት
      List<Map<String, dynamic>> enrichedAds = [];
      for (var ad in List<Map<String, dynamic>>.from(response)) {
        enrichedAds.add({
          ...ad,
          'user_name': profileData['full_name'] ?? ad['username'] ?? 'kuanyngne',
          'user_avatar': profileData['avatar_url'] ?? '',
        });
      }

      setState(() {
        _ads = enrichedAds;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Failed to load videos: $e');
    }
  }

  // ቪዲዮዎችን እና ተጠቃሚዎችን መፈለጊያ
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoadingSearch = false;
      });
      return;
    }

    setState(() {
      _isLoadingSearch = true;
    });

    try {
      final videoResults = await supabase
          .from('videos')
          .select()
          .ilike('caption', '%${query.trim()}%');

      List<Map<String, dynamic>> userResults = [];
      try {
        final profileQuery = await supabase
            .from('profiles')
            .select()
            .ilike('full_name', '%${query.trim()}%');
        userResults = List<Map<String, dynamic>>.from(profileQuery);
      } catch (_) {}

      setState(() {
        _searchResults = [
          ...List<Map<String, dynamic>>.from(videoResults),
          ...userResults,
        ];
        _isLoadingSearch = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSearch = false;
      });
      debugPrint('Search error: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    final displayList = _isSearchActive ? _searchResults : _ads;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: _isSearchActive
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isSearchActive = false;
                    _searchController.clear();
                    _searchResults = [];
                  });
                },
              )
            : IconButton(
                icon: const Icon(Icons.dynamic_feed_rounded, color: Colors.redAccent),
                tooltip: 'Feed',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ExploreFeedScreen(),
                    ),
                  );
                },
              ),
        title: _isSearchActive
            ? Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onChanged: (value) {
                    _performSearch(value);
                  },
                ),
              )
            : const Text(
                'kuanyngne',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
        centerTitle: !_isSearchActive,
        actions: _isSearchActive
            ? []
            : [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  tooltip: 'Search',
                  onPressed: () {
                    setState(() {
                      _isSearchActive = true;
                    });
                  },
                ),
              ],
      ),
      body: _isLoadingSearch
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : displayList.isEmpty
              ? const Center(
                  child: Text(
                    'No found.',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final ad = displayList[index];
                    return AdVideoItem(
                      key: ValueKey(ad['id'] ?? index),
                      caption: ad['caption'] ?? ad['user_name'] ?? '',
                      videoUrl: ad['video_url'] ?? '',
                      templateJson: ad['template_json'] ?? {},
                      videoId: ad['id']?.toString(),
                    );
                  },
                ),
    );
  }
}
