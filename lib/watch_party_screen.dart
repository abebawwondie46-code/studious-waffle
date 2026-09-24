import 'dart0:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

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
  bool _isVideoInitialized = false;
  final ImagePicker _picker = ImagePicker();

  bool _isLocked = false;
  bool _isGhostMode = false;
  bool _isRoomLockedState = false;
  final String _correctPasscode = '1234';

  @override
  void initState() {
    super.initState();
    _fetchVideoFromSupabase();
  }

  // 1. ከ Supabase Database የቪዲዮውን ሊንክ በ Real-time መውሰጃ
  void _fetchVideoFromSupabase() {
    _supabase
        .from('videos')
        .stream(primaryKey: ['id'])
        .listen((data) {
      if (data.isNotEmpty && data.last['video_link'] != null) {
        String videoUrl = data.last['video_link'];
        _initializeVideoFromUrl(videoUrl);
      }
    });
  }

  // ቪዲዮውን ማጫወት
  Future<void> _initializeVideoFromUrl(String url) async {
    if (url.isEmpty) return;
    setState(() => _isVideoInitialized = false);
    await _videoController?.dispose();

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController?.play();
      });
  }

  // 2. ከጋለሪ ወይም ከካሜራ ቪዲዮ መምረጫ
  Future<void> _pickVideo(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickVideo(source: source);
    if (pickedFile != null) {
      setState(() => _isVideoInitialized = false);
      await _videoController?.dispose();

      _videoController = VideoPlayerController.file(File(pickedFile.path))
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController?.play();
        });
    }
  }

  // 3. አዲስ የቪዲዮ URL ወደ Supabase መላኪያ/መቀየሪያ
  Future<void> _updateVideoUrlInSupabase(String url) async {
    try {
      await _supabase.from('videos').insert({'video_link': url});
    } catch (e) {
      // ስህተት ካለ
    }
  }

  void _showLinkInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('የቪዲዮ URL ያስገቡ', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _urlController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'https://example.com/video.mp4',
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

  // 4. መልእክት ወደ Supabase Database መላኪያ
  Future<void> _sendMessage([String? customText]) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isNotEmpty) {
      if (customText == null) _messageController.clear();

      await _supabase.from('comments').insert({
        'content': text,
        'room_code': widget.roomCode,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  void _unlockRoom() {
    if (_passcodeController.text == _correctPasscode) {
      setState(() {
        _isLocked = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('የተሳሳተ ፓስወርድ! (1234)')),
      );
    }
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
            const Text(
              'ሚዲያ ይምረጡ',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.purpleAccent),
              title: const Text('ከጋለሪ (Gallery)', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
              title: const Text('ከካሜራ (Camera)', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.greenAccent),
              title: const Text('ከSupabase / Web URL', style: TextStyle(color: Colors.white)),
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
    _messageController.dispose();
    _passcodeController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      // Top App Bar
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Secret Party',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'SEC-${widget.roomCode}',
              style: const TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'SEC-${widget.roomCode}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('የሩም ኮድ ኮፒ ተደርጓል!')),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isRoomLockedState ? Icons.lock : Icons.lock_open,
              color: _isRoomLockedState ? Colors.redAccent : Colors.greenAccent,
            ),
            onPressed: () {
              setState(() {
                _isRoomLockedState = !_isRoomLockedState;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _isGhostMode ? Icons.visibility_off : Icons.visibility,
              color: _isGhostMode ? Colors.purpleAccent : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isGhostMode = !_isGhostMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: _showMediaPicker,
          ),
        ],
      ),

      body: Stack(
        children: [
          Column(
            children: [
              // የቪዲዮ ማጫወቻ
              Container(
                height: 230,
                width: double.infinity,
                color: Colors.black,
                child: _isVideoInitialized && _videoController != null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                          IconButton(
                            iconSize: 60,
                            icon: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _videoController!.value.isPlaying
                                    ? _videoController!.pause()
                                    : _videoController!.play();
                              });
                            },
                          ),
                        ],
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.purpleAccent),
                      ),
              ),

              // Badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: const Text(
                        'SUPABASE CONNECTED',
                        style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isGhostMode)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('👻 GHOST', style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),

              // Emoji Bar
              SizedBox(
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['❤️', '😂', '🔥', '👏', '😮', '🎉', '💩', '👍'].map((emoji) {
                    return GestureDetector(
                      onTap: () => _sendMessage(emoji),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // 5. ከ Supabase `comments` Table መልእክቶችን በ Real-time ማሳያ
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase
                      .from('comments')
                      .stream(primaryKey: ['id'])
                      .order('created_at', ascending: true),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                    }

                    final messages = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final text = msg['content'] ?? '';

                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade700,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              text,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Message Input Field
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          fillColor: Colors.grey.shade900,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.purpleAccent,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                        onPressed: () => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Security Modal
          if (_isLocked)
            Container(
              color: Colors.black.withAlpha(240),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 70, color: Colors.purpleAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'Private Room Locked',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passcodeController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'ፓስወርድ ያስገቡ (1234)',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.grey.shade900,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        ),
                        onPressed: _unlockRoom,
                        child: const Text('ክፈት (Unlock)', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
