import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class WatchPartyScreen extends StatefulWidget {
  final String roomId;

  const WatchPartyScreen({super.key, required this.roomId});

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  String? _currentVideoUrl;
  bool _isLoading = false;

  // Video Controllers
  VideoPlayerController? _videoPlayerController;
  YoutubePlayerController? _youtubePlayerController;

  @override
  void initState() {
    super.initState();
    _fetchCurrentRoomVideo();
  }

  // 1. የቪዲዮውን ዓይነት መለያ (YouTube ወይስ MP4 URL)
  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  // 2. ከ Supabase DB የአሁኑን የቪዲዮ URL ማምጫ
  Future<void> _fetchCurrentRoomVideo() async {
    try {
      final response = await supabase
          .from('rooms')
          .select('video_url')
          .eq('room_id', widget.roomId)
          .maybeSingle();

      if (response != null && response['video_url'] != null) {
        _initializeVideoPlayer(response['video_url']);
      }
    } catch (e) {
      debugPrint('Error fetching video URL: $e');
    }
  }

  // 3. እንደ ቪዲዮው ዓይነት Player ማዘጋጃ
  void _initializeVideoPlayer(String url) {
    _disposeControllers();

    setState(() {
      _currentVideoUrl = url;
    });

    if (_isYouTubeUrl(url)) {
      final videoId = YoutubePlayer.convertUrlToId(url);
      if (videoId != null) {
        _youtubePlayerController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            isLive: false,
          ),
        );
      }
    } else {
      // ለ Supabase Storage MP4 ቪዲዮዎች
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          setState(() {});
          _videoPlayerController!.play();
        });
    }
  }

  // 4. ከጋለሪ ቪዲዮ መርጦ ወደ Supabase Storage አፕሎድ ማድረጊያ
  Future<void> _pickAndUploadVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowCompression: true,
    );

    if (result == null || result.files.single.path == null) return;

    final File file = File(result.files.single.path!);
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';

    setState(() {
      _isLoading = true;
    });

    try {
      // ወደ 'room_videos' Storage Bucket አፕሎድ ማድረግ
      await supabase.storage.from('room_videos').upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // የቪዲዮውን Public URL ማግኘት
      final String publicUrl =
          supabase.storage.from('room_videos').getPublicUrl(fileName);

      // ዳታቤዝ ውስጥ የሩሙን video_url ማደስ
      await supabase
          .from('rooms')
          .update({'video_url': publicUrl})
          .eq('room_id', widget.roomId);

      // አዲሱን ቪዲዮ በ Player ማጫወት
      _initializeVideoPlayer(publicUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ቪዲዮው በስኬት ተጭኗል!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ቪዲዮውን አፕሎድ ማድረግ አልተቻለም: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _disposeControllers() {
    _videoPlayerController?.dispose();
    _youtubePlayerController?.dispose();
    _videoPlayerController = null;
    _youtubePlayerController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Secret Party (${widget.roomId})'),
        backgroundColor: Colors.grey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _pickAndUploadVideo,
          ),
        ],
      ),
      body: Column(
        children: [
          // ቪዲዮ ማጫወቻው ቦታ
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: _buildVideoWidget(),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white,
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Party'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.lock), label: 'Vault'),
        ],
      ),
    );
  }

  Widget _buildVideoWidget() {
    if (_currentVideoUrl == null) {
      return const Center(
        child: Text(
          'ምንም የተመረጠ ቪዲዮ የለም',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // YouTube ቪዲዮ ከሆነ
    if (_isYouTubeUrl(_currentVideoUrl!) && _youtubePlayerController != null) {
      return YoutubePlayer(
        controller: _youtubePlayerController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
      );
    }

    // ከ Supabase የተጫነ MP4 ቪዲዮ ከሆነ
    if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_videoPlayerController!),
          IconButton(
            iconSize: 50,
            icon: Icon(
              _videoPlayerController!.value.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _videoPlayerController!.value.isPlaying
                    ? _videoPlayerController!.pause()
                    : _videoPlayerController!.play();
              });
            },
          ),
        ],
      );
    }

    return const Center(child: CircularProgressIndicator());
  }
}
