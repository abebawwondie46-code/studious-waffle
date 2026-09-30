import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yszkonhhprwtavxywchz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlzemtvbmhocHJ3dGF2eHl3Y2h6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3NjQxNDksImV4cCI6MjEwNjM0MDE0OX0.TXL0yzOlI3Kx5CyW6CvOsWMMc_wRafTVt7CcTxYev7E',
  );

  runApp(const KuanYngneApp());
}

class KuanYngneApp extends StatelessWidget {
  const KuanYngneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KuanYngne',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const VideoFeedScreen(),
    );
  }
}

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> videos = [];
  bool isLoading = true;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    try {
      final response = await supabase.from('videos').select().order('id', ascending: false);
      setState(() {
        videos = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ከስልክ ቪዲዮ መርጦ ወደ Supabase Storage እና Database መጫኛ ፋንክሽን
  Future<void> _pickAndUploadVideo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? videoFile = await picker.pickVideo(source: ImageSource.gallery);

    if (videoFile == null) return;

    final TextEditingController titleController = TextEditingController();

    if (!mounted) return;

    // የቪዲዮ ርዕስ መቀበያ Dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('የቪዲዮ ርዕስ ያስገቡ'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: 'ርዕስ...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ሰርዝ'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _uploadToSupabase(File(videoFile.path), titleController.text.trim());
            },
            child: const Text('አፕሎድ አድርግ'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadToSupabase(File file, String title) async {
    setState(() {
      isUploading = true;
    });

    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      // 1. Storage Bucket ውስጥ መጫን
      await supabase.storage.from('videos').upload(fileName, file);

      // 2. የቪዲዮውን Public URL ማግኘት
      final videoUrl = supabase.storage.from('videos').getPublicUrl(fileName);

      // 3. Database Table ውስጥ ማስመዝገብ
      await supabase.from('videos').insert({
        'title': title.isEmpty ? 'ያለ ርዕስ' : title,
        'video_url': videoUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ቪዲዮው በትክክል ተጭኗል!')),
        );
      }

      _fetchVideos(); // ዝርዝሩን ማደስ
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('አፕሎድ ማድረግ አልተቻለም: $e')),
        );
      }
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.redAccent,
        onPressed: isUploading ? null : _pickAndUploadVideo,
        child: isUploading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add, size: 30, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : videos.isEmpty
              ? const Center(child: Text('ምንም ቪዲዮ አልተገኘም። (+) ተጭነው ቪዲዮ ይጫኑ!'))
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return VideoCard(videoData: video);
                  },
                ),
    );
  }
}

class VideoCard extends StatefulWidget {
  final dynamic videoData;
  const VideoCard({super.key, required this.videoData});

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final videoUrl = widget.videoData['video_url'] ?? '';
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showCommentsBottomSheet(BuildContext context, int videoId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return CommentsWidget(videoId: videoId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final videoId = widget.videoData['id'];
    final title = widget.videoData['title'] ?? '';

    return Stack(
      children: [
        Positioned.fill(
          child: _isInitialized
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _controller.value.isPlaying ? _controller.pause() : _controller.play();
                    });
                  },
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
        Positioned(
          bottom: 30,
          left: 20,
          right: 80,
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Positioned(
          bottom: 40,
          right: 20,
          child: Column(
            children: [
              IconButton(
                icon: const Icon(Icons.comment, color: Colors.white, size: 35),
                onPressed: () {
                  if (videoId != null) {
                    _showCommentsBottomSheet(context, videoId);
                  }
                },
              ),
              const Text('Comments', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}

class CommentsWidget extends StatefulWidget {
  final int videoId;
  const CommentsWidget({super.key, required this.videoId});

  @override
  State<CommentsWidget> createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  final supabase = Supabase.instance.client;
  final TextEditingController _commentController = TextEditingController();
  List<dynamic> comments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    try {
      final response = await supabase
          .from('comments')
          .select()
          .eq('video_id', widget.videoId)
          .order('created_at', ascending: false);

      setState(() {
        comments = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();

    try {
      await supabase.from('comments').insert({
        'video_id': widget.videoId,
        'comment_text': text,
        'user_name': 'Guest User',
      });

      _fetchComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('አስተያየት መላክ አልተቻለም: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: 450,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Divider(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : comments.isEmpty
                      ? const Center(child: Text('ምንም አስተያየት የለም። የመጀመሪያው ይሁኑ!', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(comment['user_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              subtitle: Text(comment['comment_text'] ?? '', style: const TextStyle(color: Colors.white70)),
                            );
                          },
                        ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'አስተያየት ይፃፉ...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _addComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
