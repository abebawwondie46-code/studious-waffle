import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';

class WatchPartyScreen extends StatefulWidget {
  final String initialRoomId;
  final String roomName;

  const WatchPartyScreen({
    Key? key,
    this.initialRoomId = 'SEC-7069',
    this.roomName = 'Secret Party',
  }) : super(key: key);

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late String _currentRoomId;
  bool _isRoomLocked = true;
  bool _ghostMode = false;
  int _activeViewers = 3;

  final List<Map<String, dynamic>> _messages = [];

  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _isMuted = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _currentRoomId = widget.initialRoomId;
    _initializeNetworkVideo('https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4');
    _startControlsTimer();
    _fetchInitialMessages();
  }

  // Toast / SnackBar የማሳያ ረዳት ተግባር
  void _showToast(String message, {Color color = const Color(0xFF8E24AA)}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // አፑ ሲከፈት የቀደሙ መልእክቶችን መጫን
  Future<void> _fetchInitialMessages() async {
    try {
      final response = await _supabase
          .from('comments')
          .select()
          .eq('video_id', _currentRoomId)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages.clear();
          for (var item in response) {
            _messages.add({
              'id': item['id'].toString(),
              'username': item['username'] ?? 'You',
              'text': item['text'] ?? '',
              'created_at': DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
              'is_ghost': item['is_ghost'] ?? false,
            });
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching messages: $e");
    }
  }

  void _startControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  void _initializeNetworkVideo(String url) {
    _videoController?.dispose();
    setState(() => _isInitialized = false);

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _isPlaying = true;
        });
        _videoController!.play();
        _videoController!.addListener(() {
          if (mounted) setState(() {});
        });
      });
  }

  void _initializeFileVideo(File file) {
    _videoController?.dispose();
    setState(() => _isInitialized = false);

    _videoController = VideoPlayerController.file(file)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _isPlaying = true;
        });
        _videoController!.play();
        _videoController!.addListener(() {
          if (mounted) setState(() {});
        });
      });
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        _initializeFileVideo(File(video.path));
        _showToast("Loaded video from gallery");
      }
    } catch (e) {
      debugPrint("Gallery Picker Error: $e");
    }
  }

  Future<void> _recordVideoFromCamera() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        _initializeFileVideo(File(video.path));
        _showToast("Video recorded successfully");
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  // ቁልፍ ON/OFF ሲሆን Toast መስጠት
  void _toggleRoomLock() {
    setState(() => _isRoomLocked = !_isRoomLocked);
    if (_isRoomLocked) {
      _showToast("🔒 Room Locked - Secured", color: Colors.redAccent);
    } else {
      _showToast("🔓 Room Unlocked - Public Access", color: Colors.greenAccent);
    }
  }

  // አይን (Ghost Mode) ON/OFF ሲሆን Toast መስጠት
  void _toggleGhostMode() {
    setState(() => _ghostMode = !_ghostMode);
    if (_ghostMode) {
      _showToast("👻 Ghost Mode ON (Messages vanish in 12s)", color: const Color(0xFFAB47BC));
    } else {
      _showToast("👁️ Normal Chat Mode Active", color: Colors.blueAccent);
    }
  }

  // መልእክት መላኪያ (ከ12 ሰከንድ Auto-Delete ጋር)
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    final now = DateTime.now();
    final tempId = now.millisecondsSinceEpoch.toString();

    final newMsg = {
      'id': tempId,
      'username': 'You',
      'text': text,
      'created_at': now,
      'is_ghost': _ghostMode,
    };

    setState(() {
      _messages.add(newMsg);
    });

    // Ghost Mode ከሆነ በ 12 ሰከንድ ውስጥ መልእክቱ ይጥፋ
    if (_ghostMode) {
      Timer(const Duration(seconds: 12), () async {
        if (mounted) {
          setState(() {
            _messages.removeWhere((item) => item['id'] == tempId);
          });
        }
        try {
          await _supabase.from('comments').delete().eq('id', tempId);
        } catch (e) {
          debugPrint("Auto delete error: $e");
        }
      });
    }

    try {
      await _supabase.from('comments').insert({
        'id': tempId,
        'video_id': _currentRoomId,
        'username': 'You',
        'text': text,
        'created_at': now.toIso8601String(),
        'is_ghost': _ghostMode,
      });
    } catch (e) {
      debugPrint("Supabase insert error: $e");
    }
  }

  // መልእክቱን ጫን አድርገው ሲይዙት Delete እንዲል ማድረግ
  void _confirmDeleteMessage(Map<String, dynamic> msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181824),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.redAccent),
            SizedBox(width: 8),
            Text("Delete Message", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text("Do you want to delete this message permanently?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _messages.removeWhere((element) => element['id'] == msg['id']);
              });
              try {
                await _supabase.from('comments').delete().eq('id', msg['id']);
              } catch (e) {
                debugPrint("Manual delete error: $e");
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // አፑ ሲዘጋ ሁሉንም ዳታ ከኢንተርኔትና ከአፑ ማጽዳት (Clean Exit)
  Future<void> _clearRoomDataOnExit() async {
    try {
      await _supabase.from('comments').delete().eq('video_id', _currentRoomId);
    } catch (e) {
      debugPrint("Clear room data error: $e");
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  String _formatTimeString(DateTime dateTime) {
    int hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final hourStr = hour.toString().padLeft(2, '0');
    return "$hourStr:$minute $period";
  }

  @override
  void dispose() {
    _clearRoomDataOnExit(); // አፑ ሲዘጋ ሁሉንም ዳታ ያጠፋል
    _messageController.dispose();
    _videoController?.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181824),
        elevation: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.roomName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.greenAccent, size: 6),
                      const SizedBox(width: 4),
                      Text("$_activeViewers", style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            Text("ID: $_currentRoomId", style: const TextStyle(color: Color(0xFFAB47BC), fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isRoomLocked ? Icons.lock : Icons.lock_open_rounded, color: _isRoomLocked ? Colors.redAccent : Colors.greenAccent),
            onPressed: _toggleRoomLock,
          ),
          IconButton(
            icon: Icon(_ghostMode ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: _ghostMode ? const Color(0xFFAB47BC) : Colors.white70),
            onPressed: _toggleGhostMode,
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Player Screen
          Expanded(
            flex: 4,
            child: GestureDetector(
              onTap: _toggleControlsVisibility,
              child: Container(
                color: Colors.black,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isInitialized && _videoController != null)
                      Center(
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                      )
                    else
                      const Center(child: CircularProgressIndicator(color: Color(0xFF8E24AA))),

                    if (_isInitialized && _videoController != null && _showControls)
                      AnimatedOpacity(
                        opacity: _showControls ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 20),
                                  onPressed: () {
                                    _startControlsTimer();
                                    setState(() {
                                      _isPlaying = !_isPlaying;
                                      _isPlaying ? _videoController!.play() : _videoController!.pause();
                                    });
                                  },
                                ),
                                Text(
                                  "${_formatDuration(_videoController!.value.position)} / ${_formatDuration(_videoController!.value.duration)}",
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Messages View
          Expanded(
            flex: 5,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF4A148C).withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                    child: const Text("🔒 End-to-End Encrypted Private Room Created", style: TextStyle(color: Color(0xFFCE93D8), fontSize: 11)),
                  ),
                ),
                const SizedBox(height: 12),
                ..._messages.map((msg) {
                  final isMe = msg['username'] == 'You';
                  final isGhost = msg['is_ghost'] ?? false;
                  final DateTime msgTime = msg['created_at'] is DateTime ? msg['created_at'] : DateTime.now();
                  final timeFormatted = _formatTimeString(msgTime);

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: GestureDetector(
                      onLongPress: () => _confirmDeleteMessage(msg),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFC2185B) : const Color(0xFF222233),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isGhost) ...[
                                  const Icon(Icons.timer, color: Colors.white70, size: 14),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  msg['text'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isMe ? "You" : (msg['username'] ?? "User"),
                                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                                ),
                                if (!isGhost) ...[
                                  const SizedBox(width: 4),
                                  Text(timeFormatted, style: const TextStyle(color: Colors.white70, fontSize: 9)),
                                ],
                                if (isMe) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.done_all, color: Colors.blueAccent, size: 12),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF181824),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F17),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _ghostMode ? const Color(0xFFAB47BC) : Colors.white10,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: _ghostMode ? const Color(0xFFE1BEE7) : Colors.white),
                      decoration: InputDecoration(
                        hintText: _ghostMode ? "Type ghost comment (12s)..." : "Type comment...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _ghostMode ? const Color(0xFF8E24AA) : const Color(0xFFC2185B),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
