import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({super.key});

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();
  
  final List<Map<String, String>> _messages = [
    {'sender': 'System', 'text': '🔒 End-to-End Encrypted Private Room Created', 'time': '12:00 PM'},
  ];
  
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;
  String _selectedFileName = "No Content Loaded";
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isLocked = true;
  bool _ghostMode = false;
  
  final String _roomId = "SEC-7069";
  String _roomPasscode = "1234";

  @override
  void dispose() {
    _videoController?.dispose();
    _messageController.dispose();
    _urlController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  // Pick Video from Gallery
  Future<void> _pickFromGallery() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _loadLocalVideo(File(video.path), video.name);
    }
  }

  // Record Video with Camera
  Future<void> _recordWithCamera() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      _loadLocalVideo(File(video.path), "Camera Recording");
    }
  }

  // Play Network Video
  void _playNetworkUrl(String url) {
    if (url.trim().isEmpty) return;
    _videoController?.dispose();
    setState(() {
      _isInitialized = false;
      _selectedFileName = "Encrypted Stream";
    });

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url.trim()))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _videoController!.play();
        });
      }).catchError((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load stream link")),
        );
      });
  }

  void _loadLocalVideo(File file, String name) {
    _videoController?.dispose();
    setState(() {
      _isInitialized = false;
      _selectedFileName = name;
    });

    _videoController = VideoPlayerController.file(file)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _videoController!.play();
        });
      });
  }

  void _sendMessage({String? customText}) {
    final textToSend = customText ?? _messageController.text.trim();
    if (textToSend.isNotEmpty) {
      final now = DateTime.now();
      final timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
      final msgMap = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'sender': 'You',
        'text': textToSend,
        'time': timeStr,
        'isGhost': _ghostMode ? 'true' : 'false',
      };

      setState(() {
        _messages.add(msgMap);
        if (customText == null) _messageController.clear();
      });

      // Ghost mode auto-delete after 15 seconds
      if (_ghostMode) {
        Timer(const Duration(seconds: 15), () {
          if (mounted) {
            setState(() {
              _messages.removeWhere((m) => m['id'] == msgMap['id']);
            });
          }
        });
      }
    }
  }

  void _toggleRoomLock() {
    setState(() {
      _isLocked = !_isLocked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLocked ? "Room Locked 🔒 Passcode Required" : "Room Unlocked 🔓 Public Access"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181824),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 15),
              const Text("Secret Media Source", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF2A2A3D), child: Icon(Icons.folder_special, color: Colors.purpleAccent)),
                title: const Text("Private Gallery Video", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text("Play video from phone storage", style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF2A2A3D), child: Icon(Icons.videocam, color: Colors.purpleAccent)),
                title: const Text("Live Camera Stream", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text("Record & broadcast instantly", style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _recordWithCamera();
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF2A2A3D), child: Icon(Icons.security, color: Colors.purpleAccent)),
                title: const Text("Encrypted Web Link", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text("Stream direct HTTPS video URL", style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _showUrlInputDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUrlInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181824),
        title: const Text("Enter Video Stream URL", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _urlController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "https://site.com/video.mp4",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () {
              Navigator.pop(context);
              _playNetworkUrl(_urlController.text);
            },
            child: const Text("Play Stream"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181824),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.vpn_key_rounded, color: Colors.purpleAccent, size: 22),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Secret Watch Party", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("Room: $_roomId", style: const TextStyle(fontSize: 11, color: Colors.purpleAccent)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isLocked ? Icons.lock : Icons.lock_open, color: _isLocked ? Colors.redAccent : Colors.greenAccent),
            onPressed: _toggleRoomLock,
          ),
          IconButton(
            icon: Icon(Icons.visibility_off, color: _ghostMode ? Colors.purpleAccent : Colors.white54),
            onPressed: () {
              setState(() {
                _ghostMode = !_ghostMode;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_ghostMode ? "Ghost Mode ON 👻 Messages disappear in 15s" : "Ghost Mode OFF"),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_to_photos, color: Colors.purpleAccent),
            onPressed: _showMediaPicker,
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Player Area
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            child: Container(
              height: 230,
              width: double.infinity,
              color: Colors.black,
              child: _buildScreenContent(),
            ),
          ),

          // Secret Room Status Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: const Color(0xFF181824),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.purpleAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(
                      _isLocked ? "PRIVATE ENCRYPTED" : "PUBLIC PARTY",
                      style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_ghostMode)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Text("👻 Ghost Chat", style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 12, color: Colors.purpleAccent),
                          SizedBox(width: 4),
                          Text("Protected", style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick Emoji Bar
          Container(
            height: 44,
            color: const Color(0xFF12121D),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              children: ['🤫', '🔒', '🔥', '😂', '👏', '🎉', '👻', '❤️'].map((emoji) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _sendMessage(customText: emoji),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF222233), borderRadius: BorderRadius.circular(20)),
                      child: Text(emoji, style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['sender'] == 'You';
                final isSystem = msg['sender'] == 'System';
                final isGhost = msg['isGhost'] == 'true';

                if (isSystem) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF181824), borderRadius: BorderRadius.circular(10)),
                      child: Text(msg['text'] ?? '', style: const TextStyle(color: Colors.purpleAccent, fontSize: 11)),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.purpleAccent,
                          child: Icon(Icons.person, size: 16, color: Colors.white),
                        ),
                      if (!isMe) const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? (isGhost ? Colors.purple.shade900 : Colors.purpleAccent)
                                    : const Color(0xFF222233),
                                border: isGhost ? Border.all(color: Colors.purpleAccent, width: 1) : null,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 2),
                                  bottomRight: Radius.circular(isMe ? 2 : 16),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isGhost) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.timer, size: 14, color: Colors.white70)),
                                  Text(
                                    msg['text'] ?? '',
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(msg['time'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF181824),
              boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F17),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _ghostMode ? Colors.purpleAccent : Colors.transparent),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _ghostMode ? "Ghost message (disappears)..." : "Type secret message...",
                        hintStyle: TextStyle(color: _ghostMode ? Colors.purpleAccent.withOpacity(0.7) : Colors.grey, fontSize: 13),
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

  Widget _buildScreenContent() {
    if (_isInitialized && _videoController != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          if (_showControls)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: Colors.black54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                        child: Text(_selectedFileName, style: const TextStyle(color: Colors.purpleAccent, fontSize: 11)),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.replay_10, color: Colors.white),
                        onPressed: () {
                          final current = _videoController!.value.position;
                          _videoController!.seekTo(current - const Duration(seconds: 10));
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        iconSize: 56,
                        icon: Icon(
                          _videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.purpleAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                          });
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.forward_10, color: Colors.white),
                        onPressed: () {
                          final current = _videoController!.value.position;
                          _videoController!.seekTo(current + const Duration(seconds: 10));
                        },
                      ),
                    ],
                  ),
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.purpleAccent,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.15), shape: BoxShape.circle),
              child: const Icon(Icons.security, size: 48, color: Colors.purpleAccent),
            ),
            const SizedBox(height: 12),
            Text(_selectedFileName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showMediaPicker,
              icon: const Icon(Icons.lock_open, size: 18),
              label: const Text("Load Private Content"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            )
          ],
        ),
      );
    }
  }
}
