import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({super.key});

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<String> _quickEmojis = ['🔥', '❤️', '😂', '😮', '👏', '🎉', '💩'];

  String _roomCode = 'SEC-7069';
  bool _isLocked = true;
  bool _isGhostMode = true;

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  bool _showControls = true;
  Timer? _controlsTimer;

  bool _isMuted = false;

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initializeNetworkVideo(
        'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4');
  }

  void _initializeNetworkVideo(String url) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController?.play();
        _startControlsTimer();
      });

    _videoController?.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _pickVideoFromGallery() async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _videoController?.dispose();
      setState(() {
        _isVideoInitialized = false;
      });
      _videoController = VideoPlayerController.file(File(video.path))
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController?.play();
          _startControlsTimer();
        });
    }
  }

  Future<void> _recordVideoFromCamera() async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      _videoController?.dispose();
      setState(() {
        _isVideoInitialized = false;
      });
      _videoController = VideoPlayerController.file(File(video.path))
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController?.play();
          _startControlsTimer();
        });
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _videoController != null && _videoController!.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _shareRoomCode() {
    Clipboard.setData(ClipboardData(text: _roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Room Code copied: $_roomCode')),
    );
  }

  void _editRoomCodeDialog() {
    final controller = TextEditingController(text: _roomCode);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1B26),
          title: const Text('Edit Room Code', TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purple)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
              onPressed: () {
                setState(() {
                  _roomCode = controller.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();

    await _supabase.from('comments').insert({
      'content': text,
      'is_user': true,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _videoController?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191328),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Secret Party',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(radius: 3, backgroundColor: Colors.green),
                      SizedBox(width: 4),
                      Text('3', style: TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _editRoomCodeDialog,
              child: Text(
                'ID: $_roomCode',
                style: const TextStyle(fontSize: 11, color: Colors.purpleAccent),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: _shareRoomCode,
          ),
          IconButton(
            icon: Icon(_isLocked ? Icons.lock : Icons.lock_open, color: Colors.redAccent),
            onPressed: () => setState(() => _isLocked = !_isLocked),
          ),
          IconButton(
            icon: Icon(_isGhostMode ? Icons.visibility_off : Icons.visibility, color: Colors.purpleAccent),
            onPressed: () => setState(() => _isGhostMode = !_isGhostMode),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.purpleAccent),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1E1B26),
                builder: (context) => Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library, color: Colors.purpleAccent),
                      title: const Text('Pick from Gallery', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        _pickVideoFromGallery();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.videocam, color: Colors.purpleAccent),
                      title: const Text('Record Video', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        _recordVideoFromCamera();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Player Section
          GestureDetector(
            onTap: _toggleControls,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _isVideoInitialized
                      ? VideoPlayer(_videoController!)
                      : Container(color: Colors.black),
                ),
                if (_showControls && _isVideoInitialized) ...[
                  Container(color: Colors.black38),
                  IconButton(
                    iconSize: 50,
                    icon: Icon(
                      _videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _videoController!.value.isPlaying
                            ? _videoController!.pause()
                            : _videoController!.play();
                      });
                      _startControlsTimer();
                    },
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _isMuted = !_isMuted;
                          _videoController!.setVolume(_isMuted ? 0 : 1);
                        });
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: VideoProgressIndicator(
                      _videoController!,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: Colors.purpleAccent,
                        bufferedColor: Colors.grey,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Badges Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('LOCKED PARTY', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
                      child: const Text('👻', style: TextStyle(fontSize: 10)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.tealAccent, size: 12),
                          SizedBox(width: 4),
                          Text('AES-256 ENCRYPTED', style: TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Emoji Selector
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickEmojis.length,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _commentController.text += _quickEmojis[index];
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFF231D34), shape: BoxShape.circle),
                    child: Text(_quickEmojis[index], style: const TextStyle(fontSize: 16)),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Encryption Notice Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2A163B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, color: Colors.amber, size: 14),
                SizedBox(width: 6),
                Text('End-to-End Encrypted Private Room Created', style: TextStyle(color: Colors.purpleAccent, fontSize: 11)),
              ],
            ),
          ),

          // Realtime Comments List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from('comments').stream(primaryKey: ['id']).order('created_at', ascending: true),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                }
                final comments = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isUser = comment['is_user'] ?? false;
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isUser ? const Color(0xFFD342EF) : const Color(0xFF231D34),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          comment['content'] ?? '',
                          style: TextStyle(color: isUser ? Colors.white : Colors.white70),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Bottom Input Field
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type comment...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF191328),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.purpleAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.purple, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFD342EF),
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendComment,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF130F21),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        items: const [
          BottomNavigationBarViewItem(icon: Icon(Icons.style), label: 'Feed'),
          BottomNavigationBarViewItem(icon: Icon(Icons.add_circle), label: 'Upload'),
          BottomNavigationBarViewItem(icon: Icon(Icons.groups), label: 'Party'),
          BottomNavigationBarViewItem(icon: Icon(Icons.bar_chart), label: 'Analytics'),
          BottomNavigationBarViewItem(icon: Icon(Icons.lock), label: 'Vault'),
        ],
      ),
    );
  }
}

class BottomNavigationBarViewItem extends BottomNavigationBarItem {
  const BottomNavigationBarViewItem({required Widget icon, required String label})
      : super(icon: icon, label: label);
}
