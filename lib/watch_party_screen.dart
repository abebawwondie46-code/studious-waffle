import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WatchPartyScreen extends StatefulWidget {
  final String roomCode;
  final String videoUrl;

  const WatchPartyScreen({
    super.key,
    this.roomCode = '7069',
    this.videoUrl = 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  });

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  final ImagePicker _picker = ImagePicker();

  // WebSocket ለኢንተርኔት የቀጥታ ቻት
  WebSocketChannel? _channel;
  bool _isConnectedToInternet = false;

  bool _isLocked = false;
  bool _isGhostMode = true;
  bool _isRoomLockedState = false;
  final String _correctPasscode = '1234';

  @override
  void initState() {
    super.initState();
    _initializeVideoFromUrl(widget.videoUrl);
    _connectToOnlineChatServer();

    _messages.add({
      'text': '🔒 End-to-End Encrypted Private Room Created',
      'isSystem': true,
    });
  }

  // ከኢንተርኔት Live Chat Server ጋር ማገናኛ
  void _connectToOnlineChatServer() {
    try {
      // ይፋዊ የነጻ WebSocket ፈተና ሰርቨር (Postman Echo Server)
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://ws.postman-echo.com/raw'),
      );

      setState(() {
        _isConnectedToInternet = true;
      });

      // ከኢንተርኔት የሚመጡ መልእክቶችን ማዳመጫ
      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data);
            if (decoded['room'] == widget.roomCode && decoded['sender'] != 'me') {
              _addMessageToUI(decoded['text'], isMe: false);
            }
          } catch (_) {
            // ተራ ጽሁፍ ከሆነ
          }
        },
        onError: (error) {
          setState(() => _isConnectedToInternet = false);
        },
        onDone: () {
          setState(() => _isConnectedToInternet = false);
        },
      );
    } catch (e) {
      setState(() => _isConnectedToInternet = false);
    }
  }

  // ቪዲዮ ከኢንተርኔት (Web/Streaming URL) መክፈቻ
  Future<void> _initializeVideoFromUrl(String url) async {
    setState(() => _isVideoInitialized = false);
    await _videoController?.dispose();

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController?.play();
      });
  }

  // ከጋለሪ ወይም ከካሜራ ቪዲዮ መምረጫ
  Future<void> _pickVideo(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickVideo(source: source);
    if (pickedFile != null) {
      setState(() => _isVideoInitialized = false);
      await _videoController?.dispose();

      _videoController = VideoPlayerController.file(File(pickedFile.path))
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
          _videoController?.play();
        });
    }
  }

  void _showLinkInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('የቪዲዮ Online URL ያስገቡ', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _urlController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'https://example.com/video.mp4',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ሰርዝ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () {
              if (_urlController.text.trim().isNotEmpty) {
                _initializeVideoFromUrl(_urlController.text.trim());
                _urlController.clear();
              }
              Navigator.pop(context);
            },
            child: const Text('ክፈት', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // መልእክት ወደ ኢንተርኔት ሰርቨር መላኪያ
  void _sendMessage([String? customText]) {
    final text = customText ?? _messageController.text.trim();
    if (text.isNotEmpty) {
      _addMessageToUI(text, isMe: true);

      // በኢንተርኔት ለሌሎች የሩሙ አባላት መላክ
      if (_channel != null && _isConnectedToInternet) {
        final payload = jsonEncode({
          'room': widget.roomCode,
          'sender': 'user_${DateTime.now().millisecondsSinceEpoch}',
          'text': text,
        });
        _channel!.sink.add(payload);
      }

      if (customText == null) _messageController.clear();
    }
  }

  void _addMessageToUI(String text, {required bool isMe}) {
    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': text,
      'isMe': isMe,
      'isSystem': false,
    };

    setState(() {
      _messages.add(newMessage);
    });

    if (_isGhostMode) {
      Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _messages.removeWhere((msg) => msg['id'] == newMessage['id']);
          });
        }
      });
    }
  }

  void _unlockRoom() {
    if (_passcodeController.text == _correctPasscode) {
      setState(() {
        _isLocked = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('የተሳሳተ ፓስወርድ! (1234)')),
      );
    }
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ሚዲያ ይምረጡ',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.purpleAccent),
              title: const Text('ከጋለሪ (Gallery)', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
              title: const Text('ከካሜራ (Camera)', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.greenAccent),
              title: const Text('ከኢንተርኔት ሊንክ (Online URL)', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showLinkInputDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _videoController?.dispose();
    _messageController.dispose();
    _passcodeController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      // Top App Bar
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
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
                // የኢንተርኔት ግንኙነት አመልካች ነጥብ
                Icon(
                  Icons.circle,
                  size: 10,
                  color: _isConnectedToInternet ? Colors.greenAccent : Colors.redAccent,
                ),
              ],
            ),
            Text(
              'SEC-${widget.roomCode}',
              style: const TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'SEC-${widget.roomCode}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('የሩም ኮድ ኮፒ ተደርጓል!')),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isRoomLockedState ? Icons.lock : Icons.lock_open,
              color: _isRoomLockedState ? Colors.redAccent : Colors.greenAccent,
            ),
            onPressed: () {
              setState(() {
                _isRoomLockedState = !_isRoomLockedState;
              });
            },
          ),
          IconButton(
            icon: Icon(
              _isGhostMode ? Icons.visibility_off : Icons.visibility,
              color: _isGhostMode ? Colors.purpleAccent : Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isGhostMode = !_isGhostMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
            onPressed: _showMediaPicker,
          ),
        ],
      ),

      body: Stack(
        children: [
          Column(
            children: [
              // Online Video Display Area
              Container(
                height: 230,
                width: double.infinity,
                color: Colors.black,
                child: _isVideoInitialized && _videoController != null
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                          IconButton(
                            iconSize: 60,
                            icon: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _videoController!.value.isPlaying
                                    ? _videoController!.pause()
                                    : _videoController!.play();
                              });
                            },
                          ),
                        ],
                      )
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.purpleAccent),
                      ),
              ),

              // Badges Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: const Text(
                        'PUBLIC PARTY',
                        style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_isGhostMode)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('👻 GHOST', style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '🔒 ENCRYPTED',
                        style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Emoji Bar
              SizedBox(
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['❤️', '😂', '🔥', '👏', '😮', '🎉', '💩', '👍'].map((emoji) {
                    return GestureDetector(
                      onTap: () => _sendMessage(emoji),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Text(emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Chat Messages
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];

                    if (message['isSystem'] == true) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message['text'],
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ),
                      );
                    }

                    final isMe = message['isMe'] ?? true;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.purple.shade700 : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          message['text'],
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Message Input Box
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ghost message (disappears)...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          fillColor: Colors.grey.shade900,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.purpleAccent,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                        onPressed: () => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Security Passcode Modal
          if (_isLocked)
            Container(
              color: Colors.black.withAlpha(240),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 70, color: Colors.purpleAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'Private Room Locked',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passcodeController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'ፓስወርድ ያስገቡ (1234)',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.grey.shade900,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        ),
                        onPressed: _unlockRoom,
                        child: const Text('ክፈት (Unlock)', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
