import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';

class WatchPartyMainScreen extends StatefulWidget {
  final String initialRoomId;
  final String roomName;

  const WatchPartyMainScreen({
    Key? key,
    this.initialRoomId = 'SEC-7069',
    this.roomName = 'Secret Party',
  }) : super(key: key);

  @override
  State<WatchPartyMainScreen> createState() => _WatchPartyMainScreenState();
}

class _WatchPartyMainScreenState extends State<WatchPartyMainScreen> {
  int _currentIndex = 2; // Default selected tab is "Party"

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const Center(child: Text("Feed Page", style: TextStyle(color: Colors.white, fontSize: 18))),
      const Center(child: Text("Upload Page", style: TextStyle(color: Colors.white, fontSize: 18))),
      WatchPartyContentScreen(
        initialRoomId: widget.initialRoomId,
        roomName: widget.roomName,
      ),
      const Center(child: Text("Analytics Page", style: TextStyle(color: Colors.white, fontSize: 18))),
      const Center(child: Text("Vault Page", style: TextStyle(color: Colors.white, fontSize: 18))),
    ];
  }

  void _showUploadOptions() {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              const ListTile(
                title: Text(
                  "Select Video Source",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFFE040FB)),
                title: const Text("Choose from Gallery", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
                  if (video != null) {
                    // ቪዲዮው ሲመረጥ የሚደረግ ተግባር
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFFE040FB)),
                title: const Text("Record Video from Camera", style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? video = await picker.pickVideo(source: ImageSource.camera);
                  if (video != null) {
                    // ቪዲዮው ሲቀረጽ የሚደረግ ተግባር
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D15),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            _showUploadOptions();
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF12121C),
        selectedItemColor: const Color(0xFFFFB74D), // Gold/Orange accent
        unselectedItemColor: Colors.white54,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.style_outlined),
            activeIcon: Icon(Icons.style),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, size: 20),
            ),
            label: 'Upload',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: 'Party',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined),
            activeIcon: Icon(Icons.insert_chart),
            label: 'Analytics',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.lock_outline),
            activeIcon: Icon(Icons.lock),
            label: 'Vault',
          ),
        ],
      ),
    );
  }
}

class WatchPartyContentScreen extends StatefulWidget {
  final String initialRoomId;
  final String roomName;

  const WatchPartyContentScreen({
    Key? key,
    required this.initialRoomId,
    required this.roomName,
  }) : super(key: key);

  @override
  State<WatchPartyContentScreen> createState() => _WatchPartyContentScreenState();
}

class _WatchPartyContentScreenState extends State<WatchPartyContentScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();

  late String _currentRoomId;
  bool _isRoomLocked = true;
  bool _ghostMode = true;
  int _activeViewers = 3;

  final List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'username': 'You',
      'text': 'ሰ',
      'created_at': DateTime.now(),
      'is_ghost': false,
    },
    {
      'id': '2',
      'username': 'You',
      'text': 'ሰ',
      'created_at': DateTime.now(),
      'is_ghost': true,
    }
  ];

  VideoPlayerController? _videoController;
  bool _isInitialized = false;

  final List<String> _emojis = ['🔥', '❤️', '😂', '😮', '👏', '🎉', '💩'];

  @override
  void initState() {
    super.initState();
    _currentRoomId = widget.initialRoomId;
    _initializeNetworkVideo('https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4');
  }

  void _showToast(String message, {Color color = const Color(0xFFAB47BC)}) {
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

  void _initializeNetworkVideo(String url) {
    _videoController?.dispose();
    setState(() => _isInitialized = false);

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _videoController!.play();
        _videoController!.setLooping(true);
      });
  }

  void _toggleRoomLock() {
    setState(() => _isRoomLocked = !_isRoomLocked);
    if (_isRoomLocked) {
      _showToast("🔒 Room Locked - Secure", color: const Color(0xFFE53935));
    } else {
      _showToast("🔓 Room Unlocked", color: const Color(0xFF43A047));
    }
  }

  void _toggleGhostMode() {
    setState(() => _ghostMode = !_ghostMode);
    if (_ghostMode) {
      _showToast("👻 Ghost Mode ON (12s Auto-Delete)", color: const Color(0xFFAB47BC));
    } else {
      _showToast("👁️ Ghost Mode OFF", color: Colors.blueAccent);
    }
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;
    if (customText == null) _messageController.clear();

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

  @override
  void dispose() {
    _messageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top Header (AppBar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF141420),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.roomName,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.tealAccent.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, color: Colors.tealAccent, size: 6),
                              const SizedBox(width: 4),
                              Text("$_activeViewers", style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text("ID: $_currentRoomId", style: const TextStyle(color: Color(0xFFE040FB), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: Colors.white70, size: 22),
                      onPressed: () => _showToast("Room Link Copied!"),
                    ),
                    IconButton(
                      icon: Icon(_isRoomLocked ? Icons.lock : Icons.lock_open, color: _isRoomLocked ? const Color(0xFFFF5252) : Colors.greenAccent, size: 22),
                      onPressed: _toggleRoomLock,
                    ),
                    IconButton(
                      icon: Icon(_ghostMode ? Icons.visibility_off : Icons.visibility, color: _ghostMode ? const Color(0xFFE040FB) : Colors.white70, size: 22),
                      onPressed: _toggleGhostMode,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFFE040FB), size: 24),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Video View
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: _isInitialized && _videoController != null
                  ? AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    )
                  : const Center(child: CircularProgressIndicator(color: Color(0xFFE040FB))),
            ),
          ),

          // Status & Encryption Badges Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF0D0D15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3E101D),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                  ),
                  child: const Text("LOCKED PARTY", style: TextStyle(color: Color(0xFFFF5252), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Color(0xFF38006B), shape: BoxShape.circle),
                  child: const Icon(Icons.ghost_mode, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2E23),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.tealAccent, size: 12),
                      SizedBox(width: 4),
                      Text("AES-256 ENCRYPTED", style: TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Emoji Reactions Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: const Color(0xFF0D0D15),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: _emojis.map((emoji) {
                  return GestureDetector(
                    onTap: () => _sendMessage(emoji),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1E2C),
                        shape: BoxShape.circle,
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 18)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Main Chat Area
          Expanded(
            flex: 5,
            child: Container(
              color: const Color(0xFF0D0D15),
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF231233),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF8E24AA).withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, color: Colors.amber, size: 13),
                          SizedBox(width: 6),
                          Text(
                            "End-to-End Encrypted Private Room Created",
                            style: TextStyle(color: Color(0xFFE1BEE7), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._messages.map((msg) {
                    final isMe = msg['username'] == 'You';
                    final isGhost = msg['is_ghost'] ?? false;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE040FB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isGhost) ...[
                                  const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  msg['text'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("You", style: TextStyle(color: Colors.white70, fontSize: 10)),
                                SizedBox(width: 2),
                                Icon(Icons.done_all, color: Colors.white70, size: 12),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: const Color(0xFF141420),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D15),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE040FB)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Type comment...",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFE040FB),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () => _sendMessage(),
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
