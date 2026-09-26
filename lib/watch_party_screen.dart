import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class WatchPartyScreen extends StatefulWidget {
  final String? roomId;

  const WatchPartyScreen({super.key, this.roomId});

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  String? _currentVideoUrl;
  bool _isLoading = false;
  VideoPlayerController? _videoPlayerController;

  String get effectiveRoomId => widget.roomId ?? 'SEC-7069';

  @override
  void initState() {
    super.initState();
    _fetchCurrentRoomVideo();
  }

  Future<void> _fetchCurrentRoomVideo() async {
    try {
      final response = await supabase
          .from('rooms')
          .select('video_url')
          .eq('room_id', effectiveRoomId)
          .maybeSingle();

      if (response != null && response['video_url'] != null) {
        _initializeVideoPlayer(response['video_url']);
      }
    } catch (e) {
      debugPrint('Error fetching video URL: $e');
    }
  }

  void _initializeVideoPlayer(String url) {
    _videoPlayerController?.dispose();

    setState(() {
      _currentVideoUrl = url;
    });

    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController!.play();
      });
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      // platform ሳይፈለግ በቀጥታ በ FilePicker መምረጥ
      final dynamic result = await FilePicker.pickFiles(
        type: FileType.video,
      );

      if (result == null) return;

      String? filePath;
      if (result.files != null && result.files.isNotEmpty) {
        filePath = result.files.first.path;
      } else if (result.path != null) {
        filePath = result.path;
      }

      if (filePath == null) return;

      final File file = File(filePath);
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';

      setState(() {
        _isLoading = true;
      });

      await supabase.storage.from('room_videos').upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl =
          supabase.storage.from('room_videos').getPublicUrl(fileName);

      await supabase
          .from('rooms')
          .update({'video_url': publicUrl})
          .eq('room_id', effectiveRoomId);

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

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Secret Party ($effectiveRoomId)'),
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

    if (_videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized) {
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
