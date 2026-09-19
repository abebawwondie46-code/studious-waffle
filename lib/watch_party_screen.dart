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
  final List<Map<String, String>> _messages = [
    {'sender': 'System', 'text': 'Welcome to Watch Party Room #7069! 🎉', 'time': '12:00 PM'},
    {'sender': 'Alex', 'text': 'Hey everyone! What are we watching today?', 'time': '12:01 PM'},
  ];
  
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;
  String _selectedFileName = "No Content Loaded";
  bool _isInitialized = false;
  bool _showControls = true;
  final String _roomId = "7069";

  @override
  void dispose() {
    _videoController?.dispose();
    _messageController.dispose();
    _urlController.dispose();
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
      _loadLocalVideo(File(video.path), "Recorded Video");
    }
  }

  // Play Network Video URL
  void _playNetworkUrl(String url) {
    if (url.trim().isEmpty) return;
    _videoController?.dispose();
    setState(() {
      _isInitialized = false;
      _selectedFileName = "Online Video Stream";
    });

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url.trim()))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _videoController!.play();
        });
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load video URL")),
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
      setState(() {
        _messages.add({
          'sender': 'You',
          'text': textToSend,
          'time': timeStr,
        });
        if (customText == null) _messageController.clear();
      });
    }
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Choose Media Source",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2C2C3E),
                  child: Icon(Icons.photo_library, color: Colors.pinkAccent),
                ),
                title: const Text("Choose from Gallery", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text("Select MP4/MKV video from phone storage", style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2C2C3E),
                  child: Icon(Icons.videocam, color: Colors.pinkAccent),
                ),
                title: const Text("Record with Camera", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text("Record video live and share", style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _recordWithCamera();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2C2C3E),
                  child: Icon(Icons.link, color: Colors.pinkAccent),
                ),
                title: const Text("Play from Web URL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: const Text("Stream direct video link (http/https)", style: TextStyle(color: Colors.grey, fontSize: 12)),
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
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text("Enter Video URL", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _urlController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "https://example.com/video.mp4",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.pinkAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.groups, color: Colors.pinkAccent),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Watch Party", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Room ID: $_roomId", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white70),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: "Join my Watch Party Room ID: $_roomId"));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Room code copied to clipboard!")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.video_call, color: Colors.pinkAccent, size: 28),
            onPressed: _showMediaPicker,
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Player Screen Box
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            child: Container(
              height: 240,
              width: double.infinity,
              color: Colors.black,
              child: _buildScreenContent(),
            ),
          ),

          // Sync & Status Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: const Color(0xFF1E1E2C),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "SYNC ACTIVE",
                      style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.pinkAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.person, size: 12, color: Colors.pinkAccent),
                      SizedBox(width: 4),
                      Text("3 Watching", style: TextStyle(color: Colors.pinkAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quick Emoji Bar
          Container(
            height: 45,
            color: const Color(0xFF161622),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              children: ['❤️', '🔥', '😂', '👏', '🎉', '😮', '👍'].map((emoji) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _sendMessage(customText: emoji),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C3E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Chat Messages List
          Expanded(
            child: Container(
              color: const Color(0xFF121212),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['sender'] == 'You';
                  final isSystem = msg['sender'] == 'System';

                  if (isSystem) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
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
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.pinkAccent,
                            child: Text(
                              msg['sender']![0],
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (!isMe) const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAlignment.end : CrossAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.pinkAccent : const Color(0xFF2C2C3E),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isMe ? 16 : 2),
                                    bottomRight: Radius.circular(isMe ? 2 : 16),
                                  ),
                                ),
                                child: Text(
                                  msg['text'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                msg['time'] ?? '',
                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2C),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.pinkAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
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
              color: Colors.black45,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedFileName,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
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
                          color: Colors.pinkAccent,
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
                      playedColor: Colors.pinkAccent,
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
              decoration: BoxDecoration(
                color: Colors.pinkAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_circle_outline, size: 50, color: Colors.pinkAccent),
            ),
            const SizedBox(height: 12),
            Text(_selectedFileName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showMediaPicker,
              icon: const Icon(Icons.add_to_photos, size: 18),
              label: const Text("Select Video to Stream"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
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
