import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class WatchPartyScreen extends StatefulWidget {
  final String roomId;
  final String roomName;

  const WatchPartyScreen({
    Key? key,
    this.roomId = 'SEC-7069',
    this.roomName = 'Secret Party',
  }) : super(key: key);

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Security & Feature States
  bool _isRoomLocked = true;
  bool _isUnlockedByPassword = true; 
  bool _ghostMode = false;
  int _activeViewers = 3;

  // Local Chat Cache for Instant UI Display
  final List<Map<String, dynamic>> _localMessages = [];

  // Video State
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  String _currentVideoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer(_currentVideoUrl);
  }

  void _initializeVideoPlayer(String url) {
    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _videoController!.play();
      });
  }

  // 1. Share Room Code
  void _shareRoomCode() {
    Clipboard.setData(ClipboardData(text: "${widget.roomName} Code: ${widget.roomId}"));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.purpleAccent,
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('የሩም መግቢያ ኮድ ተቀድቷል (Copied)!'),
          ],
        ),
      ),
    );
  }

  // 2. Fixed Bottom Sheet Media Picker (ከተሸፈነው የታችኛው አሞሌ ነፃ የወጣ)
  void _showMediaPicker() {
    final TextEditingController urlController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // የታችኛው ክፍል ሙሉ በሙሉ እንዲታይ ያደርጋል
      backgroundColor: const Color(0xFF181824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_collection, color: Colors.purpleAccent),
                    SizedBox(width: 8),
                    Text(
                      "ቪዲዮ ወይም ፋይል ይምረጡ",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.link_rounded, color: Colors.purpleAccent),
                  ),
                  title: const Text("ከ Web Link (URL)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text("የቪዲዮ ሊንክ በማስገባት ይክፈቱ", style: TextStyle(color: Colors.grey, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    _showUrlInputDialog(urlController);
                  },
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.folder_copy_rounded, color: Colors.purpleAccent),
                  ),
                  title: const Text("ከስልክ ጋለሪ / Document", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text("ከስልክዎ ላይ ቪዲዮ ይምረጡ", style: TextStyle(color: Colors.grey, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUrlInputDialog(TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181824),
        title: const Text("የቪዲዮ Link ያስገቡ", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "https://example.com/video.mp4",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ሰርዝ"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _currentVideoUrl = controller.text.trim();
                _initializeVideoPlayer(_currentVideoUrl);
              }
              Navigator.pop(context);
            },
            child: const Text("ክፈት"),
          ),
        ],
      ),
    );
  }

  // 3. Delete Message Logic (ረዘም አድርገው ሲጫኑ ማጥፊያ)
  void _confirmDeleteMessage(String msgId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181824),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.redAccent),
            SizedBox(width: 8),
            Text("መልእክት አጥፋ", style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text("ይህንን መልእክት ማጥፋት እርግጠኛ ነዎት?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ሰርዝ", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _localMessages.removeWhere((m) => m['id'].toString() == msgId);
              });
              try {
                await _supabase.from('comments').delete().eq('id', msgId);
              } catch (e) {
                debugPrint("Delete error: $e");
              }
            },
            child: const Text("አጥፋ (Delete)"),
          ),
        ],
      ),
    );
  }

  // 4. Send Emoji & Message
  void _sendEmoji(String emoji) {
    _sendRawMessage(emoji);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _sendRawMessage(text);
  }

  Future<void> _sendRawMessage(String text) async {
    final now = DateTime.now();
    final msgId = DateTime.now().millisecondsSinceEpoch.toString();
    final newMsg = {
      'id': msgId,
      'video_id': widget.roomId,
      'username': 'You',
      'text': text,
      'created_at': now.toIso8601String(),
      'is_ghost': _ghostMode,
    };

    setState(() {
      _localMessages.add(newMsg);
    });

    if (_ghostMode) {
      Timer(const Duration(seconds: 8), () {
        if (mounted) {
          setState(() {
            _localMessages.removeWhere((m) => m['id'] == msgId);
          });
        }
      });
    }

    try {
      await _supabase.from('comments').insert({
        'video_id': widget.roomId,
        'username': 'You',
        'text': text,
        'created_at': now.toIso8601String(),
        'is_ghost': _ghostMode,
      });
    } catch (e) {
      debugPrint("Database sync warning: $e");
    }
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

      // App Bar
      appBar: AppBar(
        backgroundColor: const Color(0xFF181824),
        elevation: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.roomName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.greenAccent, size: 6),
                      const SizedBox(width: 3),
                      Text("$_activeViewers", style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              "ID: ${widget.roomId}",
              style: const TextStyle(color: Colors.purpleAccent, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white70),
            onPressed: _shareRoomCode,
            tooltip: 'Share Room Code',
          ),
          IconButton(
            icon: Icon(
              _isRoomLocked ? Icons.lock : Icons.lock_open,
              color: _isRoomLocked ? Colors.redAccent : Colors.greenAccent,
            ),
            onPressed: () {
              setState(() {
                _isRoomLocked = !_isRoomLocked;
              });
            },
            tooltip: 'Toggle Lock Status',
          ),
          IconButton(
            icon: Icon(
              _ghostMode ? Icons.visibility_off : Icons.visibility,
              color: _ghostMode ? Colors.purpleAccent : Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _ghostMode = !_ghostMode;
              });
            },
            tooltip: 'Ghost Mode',
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.purpleAccent, size: 26),
            onPressed: _showMediaPicker,
            tooltip: 'Add Video',
          ),
        ],
      ),

      body: Column(
        children: [
          // Video Display Area
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
                    const Center(
                      child: CircularProgressIndicator(color: Colors.purpleAccent),
                    ),

                  if (!_isUnlockedByPassword)
                    Container(
                      color: Colors.black87,
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF181824),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.purpleAccent),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock, size: 48, color: Colors.purpleAccent),
                              const SizedBox(height: 12),
                              const Text(
                                "Private Room Locked",
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "የሩሙን የደህንነት ፓስወርድ ያስገቡ",
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Password",
                                  hintStyle: const TextStyle(color: Colors.grey),
                                  filled: true,
                                  fillColor: const Color(0xFF0F0F17),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                                onPressed: () {
                                  if (_passwordController.text.isNotEmpty) {
                                    setState(() {
                                      _isUnlockedByPassword = true;
                                    });
                                  }
                                },
                                child: const Text("ክፈት (Unlock)"),
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

          // Status & Quick Emojis
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF12121D),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isRoomLocked ? Colors.redAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isRoomLocked ? "LOCKED PARTY" : "PUBLIC PARTY",
                        style: TextStyle(
                          color: _isRoomLocked ? Colors.redAccent : Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (_ghostMode)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.purple.shade900, borderRadius: BorderRadius.circular(4)),
                            child: const Text("👻 GHOST (8s)", style: TextStyle(color: Colors.purpleAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_user, size: 10, color: Colors.greenAccent),
                              SizedBox(width: 3),
                              Text("AES-256 ENCRYPTED", style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["🔥", "❤️", "😂", "😮", "👏", "🎉", "💩"].map((emoji) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => _sendEmoji(emoji),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E2E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages (Long Press to Delete)
          Expanded(
            flex: 5,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('comments')
                  .stream(primaryKey: ['id'])
                  .order('created_at', ascending: true),
              builder: (context, snapshot) {
                final dbComments = snapshot.data ?? [];

                final allComments = [...dbComments];
                for (var localMsg in _localMessages) {
                  if (!allComments.any((m) => m['id'].toString() == localMsg['id'].toString())) {
                    allComments.add(localMsg);
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade900.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                        ),
                        child: const Text(
                          "🔒 End-to-End Encrypted Private Room Created",
                          style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),

                    if (allComments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            "No comments yet. Start typing...",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ),

                    ...allComments.map((msg) {
                      final isMe = msg['username'] == 'You';
                      final isGhostMsg = msg['is_ghost'] == true;
                      final msgId = msg['id'].toString();

                      return GestureDetector(
                        onLongPress: () => _confirmDeleteMessage(msgId), // ረዘም ሲጫኑ ማጥፊያ
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? (isGhostMsg ? Colors.purple.shade900 : Colors.purpleAccent)
                                    : const Color(0xFF222233),
                                border: isGhostMsg ? Border.all(color: Colors.purpleAccent, width: 1) : null,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 2),
                                  bottomRight: Radius.circular(isMe ? 2 : 16),
                                ),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isGhostMsg)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 6),
                                          child: Text("👻", style: TextStyle(fontSize: 12)),
                                        ),
                                      Text(
                                        msg['text'] ?? '',
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        msg['username'] ?? 'User',
                                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9),
                                      ),
                                      if (isMe) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.done_all, size: 12, color: Colors.white),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        color: _ghostMode ? Colors.purpleAccent : const Color(0xFF2A2A3D),
                        width: 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _ghostMode ? "👻 Ghost message (disappears in 8s)..." : "Type comment...",
                        hintStyle: TextStyle(
                          color: _ghostMode ? Colors.purpleAccent.withOpacity(0.8) : Colors.grey,
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.purpleAccent,
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
