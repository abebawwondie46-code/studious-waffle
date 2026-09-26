import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class WatchPartyScreen extends StatefulWidget {
  final String roomCode;

  const WatchPartyScreen({
    super.key,
    this.roomCode = '7069',
  });

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;

  bool _isYoutube = false;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  bool _isUploading = false;
  String _errorMessage = '';
  final ImagePicker _picker = ImagePicker();

  bool _isLocked = true;
  bool _isGhostMode = false;
  bool _isRoomLockedState = true;
  bool _isMuted = false;
  final String _correctPasscode = '1234';

  @override
  void initState() {
    super.initState();
    _fetchVideoFromSupabase();
  }

  // 1. የቪዲዮ ሊንክ ከ Supabase መውሰጃ
  Future<void> _fetchVideoFromSupabase() async {
    try {
      final String currentRoom = widget.roomCode.toString().trim();

      final response = await _supabase
          .from('videos')
          .select()
          .eq('room_id', currentRoom)
          .order('created_at', ascending: true);

      if (response != null && response is List && response.isNotEmpty) {
        String cleanUrl = response.last['video_url'].toString().trim();
        _loadVideo(cleanUrl);
      } else {
        if (mounted) {
          setState(() {
            _hasVideoError = true;
            _errorMessage = 'ለዚህ ሩም የተመደበ ቪዲዮ አልተገኘም';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasVideoError = true;
          _errorMessage = 'ከ Supabase ጋር መገናኘት አልተቻለም፦ $e';
        });
      }
    }
  }

  // 2. MP4 ወይም YouTube መሆኑን ለይቶ ማጫወቻ
  Future<void> _loadVideo(String url) async {
    if (url.isEmpty) return;

    if (mounted) {
      setState(() {
        _isVideoInitialized = false;
        _hasVideoError = false;
      });
    }

    // የነበሩትን ኮንትሮለሮች ማፅዳት
    await _videoController?.dispose();
    _youtubeController?.dispose();
    _videoController = null;
    _youtubeController = null;

    // YouTube መሆኑን ማረጋገጫ
    String? youtubeId = YoutubePlayer.convertUrlToId(url);

    if (youtubeId != null) {
      // ቪዲዮው የ YouTube ከሆነ
      _isYoutube = true;
      _youtubeController = YoutubePlayerController(
        initialVideoId: youtubeId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
        ),
      );
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } else {
      // ቪዲዮው Direct MP4 ከሆነ
      _isYoutube = false;
      try {
        final uri = Uri.parse(url);
        _videoController = VideoPlayerController.networkUrl(uri);
        await _videoController!.initialize();

        _videoController!.addListener(() {
          if (mounted) setState(() {});
        });

        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController?.play();
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasVideoError = true;
            _errorMessage = 'ቪዲዮውን መጫን አልተቻለም';
          });
        }
      }
    }
  }

  // 3. ከጋለሪ መርጦ ወደ Supabase Storage አፕሎድ ማድረጊያ
  Future<void> _pickAndUploadVideo(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(source: source);
      if (pickedFile == null) return;

      setState(() {
        _isUploading = true;
      });

      final file = File(pickedFile.path);
      final fileExt = pickedFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'videos/$fileName';

      // ወደ Supabase Storage 'room_videos' Bucket አፕሎድ ማድረግ
      await _supabase.storage.from('room_videos').upload(filePath, file);

      // Public URL ማውጣት
      final String publicUrl =
          _supabase.storage.from('room_videos').getPublicUrl(filePath);

      // በ Database ውስጥ መመዝገብ
      await _updateVideoUrlInSupabase(publicUrl);

      setState(() {
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ቪዲዮውን አፕሎድ ማድረግ አልተቻለም፦ $e')),
        );
      }
    }
  }

  // 4. URL ወደ Database መላኪያ
  Future<void> _updateVideoUrlInSupabase(String url) async {
    try {
      await _supabase.from('videos').insert({
        'video_url': url.trim(),
        'room_id': widget.roomCode.toString().trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      await _fetchVideoFromSupabase();
    } catch (e) {
      debugPrint('Error inserting video: $e');
    }
  }

  void _showLinkInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('የቪዲዮ / YouTube URL ያስገቡ', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _urlController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'https://youtu.be/... ወይም .mp4',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ሰርዝ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () {
              if (_urlController.text.trim().isNotEmpty) {
                _updateVideoUrlInSupabase(_urlController.text.trim());
                _urlController.clear();
              }
              Navigator.pop(context);
            },
            child: const Text('ክፈት', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.purpleAccent),
              title: const Text('ከጋለሪ (Gallery)', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadVideo(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.greenAccent),
              title: const Text('የ YouTube / MP4 Link', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showLinkInputDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _youtubeController?.dispose();
    _messageController.dispose();
    _passcodeController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Secret Party (SEC-${widget.roomCode})', style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showMediaPicker,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 240,
            width: double.infinity,
            color: Colors.grey.shade900,
            child: _isUploading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.purpleAccent),
                        SizedBox(height: 10),
                        Text('ቪዲዮው ወደ Supabase እየተጫነ ነው...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  )
                : _hasVideoError
                    ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.white70)))
                    : _isVideoInitialized
                        ? _isYoutube
                            ? YoutubePlayer(controller: _youtubeController!)
                            : AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                        : const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('comments')
                  .stream(primaryKey: ['id'])
                  .eq('room_id', widget.roomCode.toString().trim())
                  .order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(messages[index]['text'] ?? '', style: const TextStyle(color: Colors.white)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
