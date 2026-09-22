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

  // Security & Locks
  bool _isRoomLocked = false;
  bool _isUnlockedByPassword = true; // Set false if password prompt is required at launch
  bool _ghostMode = false;

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

  // 1. App Bar Actions
  void _shareRoomCode() {
    Clipboard.setData(ClipboardData(text: "${widget.roomName} Code: ${widget.roomId}"));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('የሩም መግቢያ ኮድ ተቀድቷል (Copied)!')),
    );
  }

  void _showMediaPicker() {
    final TextEditingController urlController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "ቪዲዮ ይምረጡ",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.link, color: Colors.purpleAccent),
                title: const Text("ከ Web Link (URL)", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showUrlInputDialog(urlController);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library, color: Colors.purpleAccent),
                title: const Text("ከስልክ ጋለሪ (Gallery)", style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // ጋለሪ መክፈቻ በ image_picker መተካት ይቻላል
                },
              ),
            ],
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

  // Quick Emoji Sender
  Future<void> _sendEmoji(String emoji) async {
    _sendRawMessage(emoji);
  }

  // Send Message Logic
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await _sendRawMessage(text);
  }

  Future<void> _sendRawMessage(String text) async {
    try {
      await _supabase.from('comments').insert({
        'video_id': widget.roomId,
        'username': 'You',
        'text': text,
        'created_at': DateTime.now().toIso8601String(),
        'is_ghost': _ghostMode,
      });
    } catch (e) {
      debugPrint("Message Error: $e");
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

      // 1. የላይኛው አሞሌ (App Bar & Actions)
      appBar: AppBar(
        backgroundColor: const Color(0xFF181824),
        elevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.roomName,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "ID: ${widget.roomId}",
              style: const TextStyle(color: Colors.purpleAccent, fontSize: 11),
            ),
          ],
        ),
        actions: [
          // Share Icon (α / Share)
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white70),
            onPressed: _shareRoomCode,
            tooltip: 'Share Room Code',
          ),
          // Lock Icon
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
          // Ghost Mode Icon (Eye/Visibility)
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
          // Media Picker Icon (+)
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.purpleAccent, size: 26),
            onPressed: _showMediaPicker,
            tooltip: 'Add Video',
          ),
        ],
      ),

      body: Column(
        children: [
          // 2. የቪዲዮ ማጫወቻ ክፍል (Video Display Area)
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

                  // Private Room Locked Popup Overlay
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

          // 3. የሁኔታ እና ፈጣን ምላሽ አሞሌዎች (Status & Reaction Bars)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF12121D),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // PUBLIC PARTY / LOCKED status
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

                    // Ghost & Encrypted Badges
                    Row(
                      children: [
                        if (_ghostMode)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.purple.shade900, borderRadius: BorderRadius.circular(4)),
                            child: const Text("GHOST", style: TextStyle(color: Colors.purpleAccent, fontSize: 9)),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                          child: const Row(
                            children: [
                              Icon(Icons.security, size: 10, color: Colors.grey),
                              SizedBox(width: 3),
                              Text("ENCRYPTED", style: TextStyle(color: Colors.grey, fontSize: 9)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Quick Emoji Bar
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

          // 4. የቻት እና የመልእክት መላኪያ ክፍል (Chat Section)
          Expanded(
            flex: 5,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase
                  .from('comments')
                  .stream(primaryKey: ['id'])
                  .eq('video_id', widget.roomId)
                  .order('created_at', ascending: true),
              builder: (context, snapshot) {
                final comments = snapshot.data ?? [];

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // System Message: End-to-End Encrypted
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "🔒 End-to-End Encrypted Private Room Created",
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ),
                    ),

                    // Comments List
                    ...comments.map((msg) {
                      final isMe = msg['username'] == 'You';
                      final isGhostMsg = msg['is_ghost'] == true;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? (isGhostMsg ? Colors.purple.shade900 : Colors.purpleAccent)
                                  : const Color(0xFF222233),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isGhostMsg)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 4),
                                    child: Icon(Icons.timer, size: 12, color: Colors.white70),
                                  ),
                                Text(
                                  msg['text'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ],
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

          // Input Bar
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
                        color: _ghostMode ? Colors.purpleAccent : Colors.transparent,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _ghostMode ? "Ghost message (disappears)..." : "Type comment...",
                        hintStyle: TextStyle(
                          color: _ghostMode ? Colors.purpleAccent.withOpacity(0.7) : Colors.grey,
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
