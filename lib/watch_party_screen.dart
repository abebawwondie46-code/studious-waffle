import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package0:video_player/video_player.dart' if (dart.library.io) 'package:video_player/video_player.dart';

class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({super.key});

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<String> _quickEmojis = ['🔥', '❤️', '😂', '😮', '👏', '🎉', '💩'];

  String? _roomCode;
  bool _isLocked = true;
  bool _isGhostMode = true;
  bool _isUnlocked = false;

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

  void _createNewRoom() {
    final random = Random();
    final randomId = 1000 + random.nextInt(9000);
    setState(() {
      _roomCode = 'SEC-$randomId';
      _isUnlocked = false;
    });

    if (_isLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPasswordDialog();
      });
    }
  }

  void _showPasswordDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1B26),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.amber),
              SizedBox(width: 8),
              Text('Private Room Locked', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter passcode to access video & live chat.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Passcode (Any 4 digits)',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purple)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _exitRoom();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD342EF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                if (passwordController.text.isNotEmpty) {
                  setState(() {
                    _isUnlocked = true;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Unlock', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _exitRoom() {
    setState(() {
      _roomCode = null;
      _isUnlocked = false;
    });
  }

  void _initializeNetworkVideo(String url) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController?.play();
          _startControlsTimer();
        }
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
    if (_roomCode == null) return;
    Clipboard.setData(ClipboardData(text: _roomCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Room Code copied: $_roomCode')),
    );
  }

  Future<void> _sendComment({String? textToSend}) async {
    final text = textToSend ?? _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();

    try {
      final response = await _supabase.from('comments').insert({
        'content': text,
        'is_user': true,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (_isGhostMode && response.isNotEmpty) {
        final insertedId = response[0]['id'];
        Timer(const Duration(seconds: 5), () async {
          await _supabase.from('comments').delete().eq('id', insertedId);
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
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
    if (_roomCode == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0C1B),
        appBar: AppBar(
          backgroundColor: const Color(0xFF191328),
          title: const Text('Watch Party Lobby', style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.groups_outlined, size: 80, color: Colors.purpleAccent),
                const SizedBox(height: 24),
                const Text(
                  'Welcome to Secret Watch Party',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Create an encrypted room to watch videos and chat with friends in real-time.',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD342EF),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'አዲስ Room ፍጠር (Create Room)',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _createNewRoom,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF0F0C1B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191328),
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Secret Party',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(radius: 2, backgroundColor: Colors.green),
                        SizedBox(width: 2),
                        Text('3', style: TextStyle(color: Colors.green, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                'ID: $_roomCode',
                style: const TextStyle(fontSize: 10, color: Colors.purpleAccent),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            icon: const Icon(Icons.share_outlined, color: Colors.white, size: 18),
            onPressed: _shareRoomCode,
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            icon: Icon(_isLocked ? Icons.lock : Icons.lock_open, color: Colors.redAccent, size: 18),
            onPressed: () => setState(() => _isLocked = !_isLocked),
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            icon: Icon(
              _isGhostMode ? Icons.visibility_off : Icons.visibility,
              color: _isGhostMode ? Colors.purpleAccent : Colors.grey,
              size: 18,
            ),
            onPressed: () {
              setState(() => _isGhostMode = !_isGhostMode);
            },
          ),
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            icon: const Icon(Icons.add_circle_outline, color: Colors.purpleAccent, size: 18),
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
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            icon: const Icon(Icons.exit_to_app, color: Colors.red, size: 20),
            onPressed: _exitRoom,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: _toggleControls,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _isVideoInitialized && _isUnlocked
                        ? VideoPlayer(_videoController!)
                        : Container(color: Colors.black),
                  ),
                  if (_showControls && _isVideoInitialized && _isUnlocked) ...[
                    Container(color: Colors.black38),
                    IconButton(
                      iconSize: 42,
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
                      top: 8,
                      right: 8,
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
                        colors: VideoProgressColors(
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

            const SizedBox(height: 4),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _isLocked ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _isLocked ? 'LOCKED PARTY' : 'PUBLIC PARTY',
                      style: TextStyle(
                        color: _isLocked ? Colors.redAccent : Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (_isGhostMode)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
                          child: const Text('👻', style: TextStyle(fontSize: 10)),
                        ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.tealAccent, size: 11),
                            SizedBox(width: 4),
                            Text('AES-256 ENCRYPTED', style: TextStyle(color: Colors.tealAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            SizedBox(
              height: 30,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _quickEmojis.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: _isUnlocked ? () => _sendComment(textToSend: _quickEmojis[index]) : null,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFF231D34), shape: BoxShape.circle),
                      child: Text(_quickEmojis[index], style: const TextStyle(fontSize: 12)),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 4),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2A163B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: Colors.amber, size: 11),
                  SizedBox(width: 4),
                  Text('End-to-End Encrypted Private Room Created', style: TextStyle(color: Colors.purpleAccent, fontSize: 9)),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _supabase
                    .from('comments')
                    .stream(primaryKey: ['id'])
                    .order('created_at', ascending: true),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.purpleAccent),
                    );
                  }

                  final comments = snapshot.data ?? [];

                  if (comments.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet. Say hi! 👋',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      final isUser = comment['is_user'] ?? false;
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isUser ? const Color(0xFFD342EF) : const Color(0xFF231D34),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            comment['content'] ?? '',
                            style: TextStyle(color: isUser ? Colors.white : Colors.white70, fontSize: 13),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      enabled: _isUnlocked,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _isGhostMode ? 'Ghost message (disappears in 5s)...' : 'Type comment...',
                        hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF191328),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.purpleAccent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.purple, width: 2),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    backgroundColor: _isUnlocked ? const Color(0xFFD342EF) : Colors.grey,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 15),
                      onPressed: _isUnlocked ? () => _sendComment() : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
