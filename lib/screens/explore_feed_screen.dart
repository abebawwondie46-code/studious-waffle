import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExploreFeedScreen extends StatefulWidget {
  const ExploreFeedScreen({Key? key}) : super(key: key);

  @override
  State<ExploreFeedScreen> createState() => _ExploreFeedScreenState();
}

class _ExploreFeedScreenState extends State<ExploreFeedScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  // Fetch posts from Supabase table
  Future<void> _fetchPosts() async {
    try {
      final response = await supabase
          .from('videos')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _posts = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading feed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Explore Feed',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : _posts.isEmpty
              ? const Center(
                  child: Text(
                    'No posts available yet!',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    final caption = post['caption'] ?? 'No caption';

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User header info
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: const [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.redAccent,
                                  child: Icon(Icons.person, color: Colors.white, size: 20),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Creator',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),

                          // Media Display Container
                          Container(
                            height: 300,
                            width: double.infinity,
                            color: Colors.black54,
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_filled_rounded,
                                color: Colors.redAccent,
                                size: 64,
                              ),
                            ),
                          ),

                          // Actions (Like, Comment, Share)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: const [
                                Icon(Icons.favorite_border, color: Colors.white, size: 26),
                                SizedBox(width: 16),
                                Icon(Icons.comment_outlined, color: Colors.white, size: 24),
                                SizedBox(width: 16),
                                Icon(Icons.share_outlined, color: Colors.white, size: 24),
                              ],
                            ),
                          ),

                          // Caption Text
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            child: Text(
                              caption,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
