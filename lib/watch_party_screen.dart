import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';

class SecretPartyScreen extends StatefulWidget {
  const SecretPartyScreen({Key? key}) : super(key: key);

  @override
  State<SecretPartyScreen> createState() => _SecretPartyScreenState();
}

class _SecretPartyScreenState extends State<SecretPartyScreen> {
  // State Variables
  bool _isLocked = true;
  bool _isAuthenticated = false;
  String _roomPasscode = "1234";
  bool _ghostMode = false;
  bool _isRecordingAudio = false;
  int _audioRecordDuration = 0;
  Timer? _audioTimer;
  String? _currentlyPlayingAudioId;

  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  String _selectedFileName = "No Content Loaded";

  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _setPasscodeController = TextEditingController();

  final List<Map<String, String>> _messages = [
    {
      'id': '1',
      'sender': 'System',
      'text': 'End-to-End Encrypted Private Room Created',
      'time': '17:48',
      'isGhost': 'false',
      'isAudio': 'false',
    }
  ];

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    _audioTimer?.cancel();
    _messageController.dispose();
    _passcodeController.dispose();
    _setPasscodeController.dispose();
    super.dispose();
  }

  // Passcode Dialog
  void _showPasscodePromptDialog() {
    _passcodeController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181824),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_rounded, color: Colors.purpleAccent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text("Private Room Locked", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Enter room passcode to access video stream.",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passcodeController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 8,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "Enter Passcode",
                  hintStyle: const TextStyle(color: Colors.grey),
                  fillColor: const Color(0xFF0F0F17),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (_passcodeController.text.trim() == _roomPasscode) {
                setState(() {
                  _isAuthenticated = true;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Access Granted")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Incorrect Passcode")),
                );
              }
            },
            child: const Text("Unlock Access", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Audio Recording Toggle
  void _toggleAudioRecording() {
    if (_isLocked && !_isAuthenticated) {
      _showPasscodePromptDialog();
      return;
    }

    if (_isRecordingAudio) {
      _audioTimer?.cancel();
      final durationStr = "${_audioRecordDuration}s";
      _sendVoiceMessage(durationStr);

      setState(() {
        _isRecordingAudio = false;
        _audioRecordDuration = 0;
      });
    } else {
      setState(() {
        _isRecordingAudio = true;
        _audioRecordDuration = 0;
      });

      _audioTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _audioRecordDuration++;
        });
      });
    }
  }

  void _sendVoiceMessage(String duration) {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final msgMap = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'sender': 'You',
      'text': 'Voice Note ($duration)',
      'time': timeStr,
      'isGhost': _ghostMode ? 'true' : 'false',
      'isAudio': 'true',
    };

    setState(() {
      _messages.add(msgMap);
    });

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

  // Play / Pause Voice Message
  Future<void> _togglePlayVoiceNote(String id, String audioPath) async {
    try {
      if (_currentlyPlayingAudioId == id) {
        await _audioPlayer.stop();
        setState(() {
          _currentlyPlayingAudioId = null;
        });
        return;
      }

      await _audioPlayer.stop();
      if (audioPath.isNotEmpty) {
        await _audioPlayer.setUrl(audioPath);
      }

      setState(() {
        _currentlyPlayingAudioId = id;
      });

      await _audioPlayer.play();

      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() {
              _currentlyPlayingAudioId = null;
            });
          }
        }
      });
    } catch (e) {
      debugPrint("Error playing audio: $e");
      if (mounted) {
        setState(() {
          _currentlyPlayingAudioId = null;
        });
      }
    }
  }

  // Set & Change Passcode Dialog
  void _showSetPasscodeDialog() {
    _setPasscodeController.text = _roomPasscode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181824),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Change Room Passcode", style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter a new passcode",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _setPasscodeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "New Passcode",
                  hintStyle: const TextStyle(color: Colors.grey),
                  fillColor: const Color(0xFF0F0F17),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () {
              final newPin = _setPasscodeController.text.trim();
              if (newPin.isNotEmpty) {
                setState(() {
                  _roomPasscode = newPin;
                  _isLocked = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Passcode Updated Successfully")),
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Save Passcode", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _toggleRoomLock() {
    setState(() {
      _isLocked = !_isLocked;
      if (!_isLocked) {
        _isAuthenticated = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLocked ? "Room Locked" : "Room Unlocked"),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _loadLocalVideo(File(video.path), video.name);
    }
  }

  Future<void> _recordWithCamera() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      _loadLocalVideo(File(video.path), "Camera Recording");
    }
  }

  void _playNetworkUrl(String url) {
    if (url.trim().isEmpty) return;
    _videoController?.dispose();
    setState(() {
      _isInitialized = false;
      _selectedFileName = "Encrypted Stream";
    });

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _videoController!.play();
        });
      }).catchError((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to load video stream")),
          );
        }
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
    if (_isLocked && !_isAuthenticated) {
      _showPasscodePromptDialog();
      return;
    }

    final textToSend = customText ?? _messageController.text.trim();
    if (textToSend.isNotEmpty) {
      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      final msgMap = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'sender': 'You',
        'text': textToSend,
        'time': timeStr,
        'isGhost': _ghostMode ? 'true' : 'false',
        'isAudio': 'false',
      };

      setState(() {
        _messages.add(msgMap);
        _messageController.clear();
      });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F17),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Secret Party", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text("SEC-7069", style: TextStyle(color: Colors.purpleAccent, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.grey),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(
              _isLocked ? Icons.lock : Icons.lock_open,
              color: _isLocked ? Colors.redAccent : Colors.green,
            ),
            onPressed: _toggleRoomLock,
          ),
          IconButton(
            icon: Icon(
              _ghostMode ? Icons.visibility_off : Icons.visibility,
              color: _ghostMode ? Colors.purpleAccent : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _ghostMode = !_ghostMode;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_box_rounded, color: Colors.purpleAccent),
            onPressed: () {
              _showPickerMenu(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Player / Lock Screen Area
          Container(
            height: 220,
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF181824),
              borderRadius: BorderRadius.circular(16),
            ),
            child: (_isLocked && !_isAuthenticated)
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF281834),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield, color: Colors.purpleAccent, size: 40),
                      ),
                      const SizedBox(height: 12),
                      Text(_selectedFileName, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: _showPasscodePromptDialog,
                        icon: const Icon(Icons.lock_outline, color: Colors.white),
                        label: const Text("Load Private Content", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                : (_isInitialized && _videoController != null)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                      )
                    : const Center(
                        child: Text("No Video Loaded", style: TextStyle(color: Colors.grey)),
                      ),
          ),

          // Passcode Status Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _showSetPasscodeDialog,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isLocked ? Colors.redAccent : Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isLocked ? "LOCKED (PIN: $_roomPasscode)" : "UNLOCKED",
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, color: Colors.grey, size: 14),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF241830),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.purpleAccent, size: 14),
                      SizedBox(width: 4),
                      Text("Encrypted", style: TextStyle(color: Colors.purpleAccent, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Emoji Quick Reactions Bar
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildEmojiBtn("😳"),
                _buildEmojiBtn("🔒"),
                _buildEmojiBtn("🔥"),
                _buildEmojiBtn("😂"),
                _buildEmojiBtn("👏"),
                _buildEmojiBtn("🎉"),
                _buildEmojiBtn("👻"),
                _buildEmojiBtn("❤️"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isSystem = msg['sender'] == 'System';
                final isAudio = msg['isAudio'] == 'true';

                if (isSystem) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B1B26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock, color: Colors.amber, size: 14),
                          const SizedBox(width: 6),
                          Text(msg['text']!, style: const TextStyle(color: Colors.purpleAccent, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }

                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD633E6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isAudio)
                          GestureDetector(
                            onTap: () => _togglePlayVoiceNote(msg['id']!, ""),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _currentlyPlayingAudioId == msg['id']
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.graphic_eq, color: Colors.white70, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  msg['text']!,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            msg['text']!,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          msg['time']!,
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Message Input Field
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF0F0F17),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isRecordingAudio
                          ? "Recording... (${_audioRecordDuration}s)"
                          : "Type secret message...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      fillColor: const Color(0xFF181824),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_messageController.text.trim().isNotEmpty) {
                      _sendMessage();
                    } else {
                      _toggleAudioRecording();
                    }
                  },
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.purpleAccent,
                    child: Icon(
                      _messageController.text.trim().isNotEmpty
                          ? Icons.send
                          : (_isRecordingAudio ? Icons.stop : Icons.mic),
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F0F17),
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.style), label: "Feed"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "Upload"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Party"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Analytics"),
          BottomNavigationBarItem(icon: Icon(Icons.lock), label: "Vault"),
        ],
      ),
    );
  }

  Widget _buildEmojiBtn(String emoji) {
    return GestureDetector(
      onTap: () => _sendMessage(customText: emoji),
      child: Container(
        margin: const EdgeInsets.horizontal(4),
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFF181824),
          shape: BoxShape.circle,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  void _showPickerMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181824),
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.purpleAccent),
            title: const Text('Pick from Gallery', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _pickFromGallery();
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Colors.purpleAccent),
            title: const Text('Record with Camera', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _recordWithCamera();
            },
          ),
        ],
      ),
    );
  }
}
