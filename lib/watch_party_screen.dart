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

  // የአካባቢ መልእክቶች ዝርዝር (ወዲያውኑ ስክሪን ላይ እንዲታዩ)
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

  // ከSupabase መልእክቶችን መጫን
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
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  void _editRoomCodeDialog() {
    final TextEditingController codeController = TextEditingController(text: _currentRoomId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181824),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Color(0xFF8E24AA)),
            SizedBox(width: 8),
            Text("Edit Room Code", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: codeController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Enter Custom Room ID",
            labelStyle: TextStyle(color: Color(0xFFAB47BC)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8E24AA))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A1B9A)),
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                setState(() {
                  _currentRoomId = codeController.text.trim();
                });
                Navigator.pop(context);
                _shareRoomCode();
              }
            },
            child: const Text("Save & Share"),
          ),
        ],
      ),
    );
  }

  void _shareRoomCode() {
    Clipboard.setData(ClipboardData(text: "${widget.roomName} Code: $_currentRoomId"));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF6A1B9A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('Room code ($_currentRoomId) copied to clipboard!'),
      ),
    );
  }

  void _toggleRoomLock() {
    setState(() => _isRoomLocked = !_isRoomLocked);
  }

  void _toggleGhostMode() {
    setState(() => _ghostMode = !_ghostMode);
  }

  void _showUrlInputDialog() {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181824),
        title: const Text("Enter Video URL", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: urlController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "https://example.com/video.mp4",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8E24AA))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A1B9A)),
            onPressed: () {
              if (urlController.text.trim().isNotEmpty) {
                _initializeNetworkVideo(urlController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Play"),
          ),
        ],
      ),
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181824),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade600, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text("Select Media Source", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.video_library_rounded, color: Color(0xFFAB47BC)),
                  title: const Text("Gallery Video", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideoFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link_rounded, color: Colors.blueAccent),
                  title: const Text("Network URL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _showUrlInputDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: Colors.orangeAccent),
                  title: const Text("Camera", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _recordVideoFromCamera();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // መልእክት የመላክ ተግባር (ስክሪኑ ላይ ወዲያውኑ ይታያል + Supabase ውስጥ ይገባል)
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

    try {
      await _supabase.from('comments').insert({
        'video_id': _currentRoomId,
        'username': 'You',
        'text': text,
        'created_at': now.toIso8601String(),
        'is_ghost': _ghostMode,
      });
    } catch (e) {
      debugPrint("Supabase insert note: $e");
    }
  }

  // መልእክቱን ጫን አድርገው ሲይዙት የሚመጣ የDelete ማረጋገጫ dialog
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
        content: const Text("Do you want to delete this message?", style: TextStyle(color: Colors.white70)),
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
                debugPrint("Delete error: $e");
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
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
            Row(
              children: [
                Text("ID: $_currentRoomId", style: const TextStyle(color: Color(0xFFAB47BC), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _editRoomCodeDialog,
                  child: const Icon(Icons.edit, color: Color(0xFFAB47BC), size: 13),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share_rounded, color: Colors.white70), onPressed: _shareRoomCode),
          IconButton(
            icon: Icon(_isRoomLocked ? Icons.lock : Icons.lock_open_rounded, color: _isRoomLocked ? Colors.redAccent : Colors.greenAccent),
            onPressed: _toggleRoomLock,
          ),
          IconButton(
            icon: Icon(_ghostMode ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: _ghostMode ? const Color(0xFFAB47BC) : Colors.white70),
            onPressed: _toggleGhostMode,
          ),
          IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFFAB47BC), size: 26), onPressed: _showMediaPicker),
        ],
      ),
      body: Column(
        children: [
          // Video Player
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                VideoProgressIndicator(
                                  _videoController!,
                                  allowScrubbing: true,
                                  colors: const VideoProgressColors(
                                    playedColor: Color(0xFFAB47BC),
                                    bufferedColor: Colors.white24,
                                    backgroundColor: Colors.white10,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
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
                                    IconButton(
                                      icon: Icon(_isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Colors.white, size: 18),
                                      onPressed: () {
                                        _startControlsTimer();
                                        setState(() {
                                          _isMuted = !_isMuted;
                                          _videoController!.setVolume(_isMuted ? 0 : 1);
                                        });
                                      },
                                    ),
                                  ],
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

          // Status Badges
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF12121D),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isRoomLocked ? Colors.redAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _isRoomLocked ? Colors.redAccent : Colors.greenAccent),
                    ),
                    child: Text(_isRoomLocked ? "LOCKED PARTY" : "PUBLIC PARTY", style: TextStyle(color: _isRoomLocked ? Colors.redAccent : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  if (_ghostMode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A148C).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFAB47BC)),
                      ),
                      child: const Text("👻 GHOST MODE ACTIVE", style: TextStyle(color: Color(0xFFE1BEE7), fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  if (_ghostMode) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                    child: const Text("✓ AES-256 ENCRYPTED", style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),

          // Emojis Bar
          Container(
            color: const Color(0xFF12121D),
            padding: const EdgeInsets.only(bottom: 6, left: 12, right: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["🔥", "❤️", "😂", "😮", "👏", "🎉", "💩"].map((emoji) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () => _messageController.text = emoji,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(16)),
                        child: Text(emoji, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Messages List View
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
                      // መልእክቱን ጫን አድርገው ሲይዙት (Long Press) Delete እንዲል
                      onLongPress: () => _confirmDeleteMessage(msg),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFC2185B) : const Color(0xFF222233), // deep pink/purple bubble
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
                                  const Icon(Icons.access_time_filled, color: Colors.white70, size: 14),
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

          // Comment Input Field
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF181824),
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F17),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _ghostMode ? const Color(0xFFAB47BC) : Colors.white10,
                        width: _ghostMode ? 1.5 : 1.0,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(color: _ghostMode ? const Color(0xFFE1BEE7) : Colors.white),
                      decoration: InputDecoration(
                        hintText: _ghostMode ? "Type ghost comment..." : "Type comment...",
                        hintStyle: TextStyle(color: _ghostMode ? const Color(0xFFE1BEE7).withOpacity(0.6) : Colors.grey),
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
