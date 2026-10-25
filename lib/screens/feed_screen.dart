import 'dart:async';
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

  // የአሁኑ ተጠቃሚ ፕሮፋይል መረጃ (ፎቶ እና ስም)
  String _profileName = 'Community Creator';
  String _profileAvatar = '';

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
            .select('full_name, avatar_url')
            .maybeSingle();
        
        if (profileRes != null) {
          setState(() {
            _profileName = profileRes['full_name'] ?? 'Community Creator';
            _profileAvatar = profileRes['avatar_url'] ?? '';
          });
        }
      } catch (_) {}

      // የቪዲዮዎች ዝርዝር ከሰርቨር ማምጣት
      final response = await supabase.from('videos').select();
      
      List<Map<String, dynamic>> fetchedAds = List<Map<String, dynamic>>.from(response);

      // 🛑 ዳታቤዙ ባዶ ከሆነ (ቪዲዮ ከሌለ) አፑ እንዳይዘጋ 1 ነባር (Static) ዱሚ ካርድ እንፈጥራለን
      if (fetchedAds.isEmpty) {
        fetchedAds = [
          {
            'id': 'dummy_chat_card',
            'caption': 'እንኳን ደህና መጡ! ወደ ቻት ለመግባት በግራ በኩል ያለውን የአሻራ ቁልፍ ይጫኑ።',
            'video_url': '',
            'template_json': {},
          }
        ];
      }

      setState(() {
        _ads = fetchedAds;
        _isLoading = false;
      });
    } catch (e) {
      // ስህተት ቢኖርም እንኳን ዱሚ ካርዱን በመፍጠር አፑ እንዳይበላሽ እናደርጋለን
      setState(() {
        _ads = [
          {
            'id': 'dummy_chat_card',
            'caption': 'ወደ ቻት ለመግባት በግራ በኩል ያለውን የአሻራ ቁልፍ ይጫኑ።',
            'video_url': '',
            'template_json': {},
          }
        ];
        _isLoading = false;
      });
      debugPrint('Failed to load data: $e');
    }
  }

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

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(videoResults);
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
                      caption: ad['caption'] ?? '',
                      videoUrl: ad['video_url'] ?? '',
                      templateJson: ad['template_json'] ?? {},
                      videoId: ad['id']?.toString(),
                      userAvatar: _profileAvatar,
                      userName: _profileName,
                    );
                  },
                ),
    );
  }
}
