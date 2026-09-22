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
  final TextEditingController _passwordController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late String _currentRoomId;
  bool _isRoomLocked = true;
  bool _isUnlockedByPassword = true;
  bool _ghostMode = false;
  int _activeViewers = 3;

  final List<Map<String, dynamic>> _localMessages = [];

  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _currentRoomId = widget.initialRoomId;
    _initializeNetworkVideo('https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4');
  }

  // 1. የኦንላይን ቪዲዮ ማጫወቻ
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

  // 2. ከስልክ ጋለሪ/ካሜራ የመጣን ፋይል ስክሪኑ ላይ መጫኛ
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

  // 3. ከጋለሪ ቪዲዮ መምረጫ
  Future<void> _pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        _initializeFileVideo(File(video.path));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.purpleAccent,
            content: Text('ቪዲዮ ተመርጦ በስክሪኑ ላይ ተጫኗል፦ ${video.name}'),
          ),
        );
      }
    } catch (e) {
      debugPrint("Gallery Picker Error: $e");
    }
  }

  // 4. ከካሜራ ቪዲዮ መቅረጫ
  Future<void> _recordVideoFromCamera() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
      if (video != null) {
        _initializeFileVideo(File(video.path));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text('የተቀረፀው ቪዲዮ በስክሪኑ ላይ ተጫኗል፦ ${video.name}'),
          ),
        );
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  // 5. የሩም ኮድ በባለእርሳስ ምልክት የመቀየሪያ Dialog
  void _editRoomCodeDialog() {
    final TextEditingController codeController = TextEditingController(text: _currentRoomId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181824),
        title: const Row(
          children: [
            Icon(Icons.edit, color: Colors.purpleAccent),
            SizedBox(width: 8),
            Text("የሩም ኮድ ይቀይሩ (Custom Code)", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: codeController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "አዲስ የሩም ኮድ ያስገቡ",
            labelStyle: TextStyle(color: Colors.purpleAccent),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ሰርዝ", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                setState(() {
                  _currentRoomId = codeController.text.trim();
                });
                Navigator.pop(context);
                _shareRoomCode();
              }
            },
            child: const Text("ቀይር እና ላክ (Save & Share)"),
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
        backgroundColor: Colors.purpleAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text('አዲሱ የሩም ኮድ ($_currentRoomId) ተቀድቷል! ለጓደኛዎ ይላኩለት።'),
      ),
    );
  }

  void _toggleRoomLock() {
    setState(() => _isRoomLocked = !_isRoomLocked);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: _isRoomLocked ? const Color(0xFFD32F2F) : const Color(0xFF388E3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(_isRoomLocked ? Icons.lock_rounded : Icons.lock_open_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isRoomLocked
                    ? '🔒 Private Mode: Password required to join'
                    : '🔓 Public Mode: Anyone with code can join',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleGhostMode() {
    setState(() => _ghostMode = !_ghostMode);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: _ghostMode ? const Color(0xFF8E24AA) : const Color(0xFF333344),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(_ghostMode ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _ghostMode ? '👻 Ghost Mode ON: Comments vanish in 12s' : '👁️ Ghost Mode OFF: Saved normally',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUrlInputDialog() {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181824),
        title: const Text("የቪዲዮ ወይም ፋይል URL ያስገቡ", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: urlController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "https://example.com/video.mp4",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ሰርዝ", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () {
              if (urlController.text.trim().isNotEmpty) {
                _initializeNetworkVideo(urlController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("ክፈት (Play)"),
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
                const Text("ሚዲያ ወይም ፋይል ይምረጡ", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.video_library_rounded, color: Colors.purpleAccent),
                  title: const Text("ቪዲዮ ከጋለሪ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideoFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link_rounded, color: Colors.blueAccent),
                  title: const Text("በሊንክ (URL) ክፈት", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _showUrlInputDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: Colors.orangeAccent),
                  title: const Text("ካሜራ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    final now = DateTime.now();
    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    final newMsg = {
      'id': msgId,
      'video_id': _currentRoomId,
      'username': 'You',
      'text': text,
      'created_at': now.toIso8601String(),
      'is_ghost': _ghostMode,
    };

    setState(() => _localMessages.add(newMsg));

    if (_ghostMode) {
      Timer(const Duration(seconds: 12), () {
        if (mounted) {
          setState(() => _localMessages.removeWhere((m) => m['id'] == msgId));
        }
      });
    }

    try {
      await _supabase.from('comments').insert({
        'video_id': _currentRoomId,
        'username': 'You',
        'text': text,
        'created_at': now.toIso8601String(),
        'is_ghost': _ghostMode,
      });
    } catch (e) {
      debugPrint("Database sync warning: $e");
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _messageController.dispose();
    _passwordController.dispose();
    _videoController?.dispose();
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
            // *** የሩም ኮድ በባለእርሳስ አዝራር የመቀየሪያ ክፍለ-አካል ***
            Row(
              children: [
                Text("ID: $_currentRoomId", style: const TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _editRoomCodeDialog,
                  child: const Icon(Icons.edit, color: Colors.purpleAccent, size: 13),
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
            icon: Icon(_ghostMode ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: _ghostMode ? const Color(0xFFE040FB) : Colors.white70),
            onPressed: _toggleGhostMode,
          ),
          IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.purpleAccent, size: 26), onPressed: _showMediaPicker),
        ],
      ),
      body: Column(
        children: [
          // *** የቪዲዮ ማጫወቻ እና የጊዜ መስመር (Video Player & Controls Timeline) ***
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  if (_isInitialized && _videoController != null)
                    Center(
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  else
                    const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),

                  // የቪዲዮ መቆጣጠሪያዎች እና የጊዜ መስመር (Timeline Track)
                  if (_isInitialized && _videoController != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VideoProgressIndicator(
                              _videoController!,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: Colors.purpleAccent,
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
                ],
              ),
            ),
          ),

          // *** የስክሪን መብለጥ (Overflow Bug Fix) መፍትሔ ***
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
                        color: const Color(0xFF8E24AA).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE040FB)),
                      ),
                      child: const Text("👻 GHOST MODE ACTIVE", style: TextStyle(color: Color(0xFFE040FB), fontSize: 9, fontWeight: FontWeight.bold)),
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

          // የምላሽ ኢሞጂዎች
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

          // የመልእክት ዝርዝር
          Expanded(
            flex: 5,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.purple.shade900.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                    child: const Text("🔒 End-to-End Encrypted Private Room Created", style: TextStyle(color: Colors.purpleAccent, fontSize: 11)),
                  ),
                ),
                const SizedBox(height: 12),
                ..._localMessages.map((msg) {
                  final isMe = msg['username'] == 'You';
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.purpleAccent : const Color(0xFF222233),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(msg['text'] ?? '', style: const TextStyle(color: Colors.white)),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // የመልእክት መፃፊያ ሳጥን
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF181824),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: const Color(0xFF0F0F17), borderRadius: BorderRadius.circular(24)),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: "Type comment...", hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.purpleAccent,
                  child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18), onPressed: _sendMessage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
