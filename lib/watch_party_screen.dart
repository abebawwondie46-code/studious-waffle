import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

// እነዚህ 4 ኢምፖርቶች መኖራቸውን እርግጠኛ ሁን
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({super.key});

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _setPasscodeController = TextEditingController();

  final List<Map<String, String>> _messages = [
    {'id': '1', 'sender': 'System', 'text': '🔒 End-to-End Encrypted Private Room Created', 'time': '12:00 PM', 'isGhost': 'false', 'isAudio': 'false', 'audioPath': ''},
  ];

  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;
  String _selectedFileName = "No Content Loaded";
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isFullScreen = false;

  // Real Audio Recording & Playback
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecordingAudio = false;
  int _audioRecordDuration = 0;
  Timer? _audioTimer;
  String? _currentlyPlayingAudioId;
  String? _currentRecordingPath;

  // Security & Authentication States
  bool _isLocked = true;
  bool _isAuthenticated = false;
  bool _ghostMode = false;
  bool _obscurePasscode = true;

  final String _roomId = "SEC-7069";
  String _roomPasscode = "1234";

  final List<String> _emojiList = [
    '🤫', '🔒', '🔥', '😂', '👏', '🎉', '👻', '❤️',
    '🥳', '👍', '💯', '😎', '👀', '🚀', '✨', '🍿',
    '🙌', '😍', '🤔', '🤝', '🤡', '🙈', '💀', '💩'
  ];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {});
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _currentlyPlayingAudioId = null;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isLocked && !_isAuthenticated) {
        _showPasscodePromptDialog();
      }
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _messageController.dispose();
    _urlController.dispose();
    _passcodeController.dispose();
    _setPasscodeController.dispose();
    _audioTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showPasscodePromptDialog() {
    _passcodeController.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              backgroundColor: const Color(0xFF181824),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_rounded, color: Colors.purpleAccent, size: 28),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text("Private Room Locked", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Enter room passcode to access video stream and encrypted chat.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purpleAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.purpleAccent),
                          const SizedBox(width: 8),
                          Text(
                            "Passcode: $_roomPasscode",
                            style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passcodeController,
                      obscureText: _obscurePasscode,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, letterSpacing: 3, fontSize: 18),
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "Enter Passcode",
                        hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 1, fontSize: 14),
                        fillColor: const Color(0xFF0F0F17),
                        filled: true,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePasscode ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _obscurePasscode = !_obscurePasscode;
                            });
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.purpleAccent)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.purpleAccent)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.purpleAccent, width: 2)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_passcodeController.text.trim() == _roomPasscode) {
                      setState(() {
                        _isAuthenticated = true;
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Access Granted 🔓 Welcome to Secret Watch Party!")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Incorrect Passcode! Please try again."), backgroundColor: Colors.redAccent),
                      );
                    }
                  },
                  child: const Text("Unlock Access", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleAudioRecording() async {
    if (_isLocked && !_isAuthenticated) {
      _showPasscodePromptDialog();
      return;
    }

    if (_isRecordingAudio) {
      _audioTimer?.cancel();
      final path = await _audioRecorder.stop();
      
      setState(() {
        _isRecordingAudio = false;
      });

      if (path != null) {
        final durationStr = "${_audioRecordDuration}s";
        _sendVoiceMessage(durationStr, path);
      }
      _audioRecordDuration = 0;
    } else {
      var status = await Permission.microphone.request();
      if (status.isGranted) {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getApplicationDocumentsDirectory();
          _currentRecordingPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

          // const የሚለው እዚህ ጋር ተወግዷል
          await _audioRecorder.start(
            RecordConfig(encoder: AudioEncoder.aacLc),
            path: _currentRecordingPath!,
          );

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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Microphone permission is required to record voice notes.")),
        );
      }
    }
  }

  void _sendVoiceMessage(String duration, String filePath) {
    final now = DateTime.now();
    final timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
    final msgMap = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'sender': 'You',
      'text': 'Voice Note ($duration)',
      'time': timeStr,
      'isGhost': _ghostMode ? 'true' : 'false',
      'isAudio': 'true',
      'audioPath': filePath,
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

  Future<void> _togglePlayVoiceNote(String id, String audioPath) async {
    if (audioPath.isEmpty || !File(audioPath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Audio file not found or corrupted.")),
      );
      return;
    }

    if (_currentlyPlayingAudioId == id) {
      await _audioPlayer.pause();
      setState(() {
        _currentlyPlayingAudioId = null;
      });
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(audioPath));
      setState(() {
        _currentlyPlayingAudioId = id;
      });
    }
  }

  void _showSetPasscodeDialog() {
    _setPasscodeController.text = _roomPasscode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181824),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Change Room Passcode", style: TextStyle(color: Colors.white, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Enter a new passcode for this private room:", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 15),
              TextField(
                controller: _setPasscodeController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: "New Passcode",
                  hintStyle: const TextStyle(color: Colors.grey),
                  fillColor: const Color(0xFF0F0F17),
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.purpleAccent)),
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
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Passcode changed to: $_roomPasscode")),
                );
              }
            },
            child: const Text("Save Passcode"),
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
        content: Text(_isLocked ? "Room Locked 🔒 (PIN: $_roomPasscode)" : "Room Unlocked 🔓 Public Party"),
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
      _loadLocalVideo(File(video.path), "Camera Stream");
    }
  }

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
    if (_isLocked && !_isAuthenticated) {
      _showPasscodePromptDialog();
      return;
    }

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
        'isAudio': 'false',
        'audioPath': '',
      };

      setState(() {
        _messages.add(msgMap);
        if (customText == null) _messageController.clear();
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

  void _deleteMessageDialog(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181824),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Message?", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text("This message will be removed for everyone in this room.", style: TextStyle(color: Colors.grey, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                _messages.removeWhere((m) => m['id'] == messageId);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Message deleted")),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showMediaPicker() {
    if (_isLocked && !_isAuthenticated) {
      _showPasscodePromptDialog();
      return;
    }

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

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F17),
      appBar: _isFullScreen
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF181824),
              elevation: 0,
              titleSpacing: 0,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 10),
                  const Icon(Icons.vpn_key_rounded, color: Colors.purpleAccent, size: 20),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Secret Party",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          _roomId,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: Colors.purpleAccent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  icon: const Icon(Icons.share, color: Colors.white70, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: "Join Secret Watch Party!\nRoom ID: $_roomId\nPasscode: $_roomPasscode"));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Room Code & Passcode copied to clipboard!")),
                    );
                  },
                ),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  icon: Icon(
                    _isLocked ? Icons.lock : Icons.lock_open,
                    color: _isLocked ? Colors.redAccent : Colors.greenAccent,
                    size: 20,
                  ),
                  onPressed: _toggleRoomLock,
                  onLongPress: _showSetPasscodeDialog,
                ),
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  icon: Icon(
                    _ghostMode ? Icons.visibility : Icons.visibility_off,
                    color: _ghostMode ? Colors.purpleAccent : Colors.white54,
                    size: 20,
                  ),
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
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.only(left: 6, right: 12),
                  icon: const Icon(Icons.add_to_photos, color: Colors.purpleAccent, size: 20),
                  onPressed: _showMediaPicker,
                ),
              ],
            ),
      body: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
            child: ClipRect(
              child: Container(
                height: _isFullScreen ? MediaQuery.of(context).size.height : 230,
                width: double.infinity,
                color: Colors.black,
                child: _buildScreenContent(),
              ),
            ),
          ),

          if (!_isFullScreen) ...[
            GestureDetector(
              onTap: _showSetPasscodeDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: const Color(0xFF181824),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isLocked ? Colors.redAccent : Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isLocked ? "LOCKED (PIN: $_roomPasscode)" : "PUBLIC PARTY",
                          style: TextStyle(
                            color: _isLocked ? Colors.redAccent : Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 12, color: Colors.grey),
                      ],
                    ),
                    Row(
                      children: [
                        if (_ghostMode)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Text("👻 Ghost", style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            children: [
                              Icon(Icons.shield_outlined, size: 12, color: Colors.purpleAccent),
                              SizedBox(width: 4),
                              Text("Encrypted", style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Container(
              height: 48,
              color: const Color(0xFF12121D),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                itemCount: _emojiList.length,
                itemBuilder: (context, index) {
                  final emoji = _emojiList[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _sendMessage(customText: emoji),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF222233), borderRadius: BorderRadius.circular(20)),
                        child: Text(emoji, style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                  );
                },
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['sender'] == 'You';
                  final isSystem = msg['sender'] == 'System';
                  final isGhost = msg['isGhost'] == 'true';
                  final isAudio = msg['isAudio'] == 'true';
                  final isPlayingThisAudio = _currentlyPlayingAudioId == msg['id'];

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

                  return GestureDetector(
                    onLongPress: () => _deleteMessageDialog(msg['id']!),
                    child: Padding(
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                  child: isAudio
                                      ? InkWell(
                                          onTap: () => _togglePlayVoiceNote(msg['id']!, msg['audioPath'] ?? ''),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isPlayingThisAudio ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.graphic_eq,
                                                size: 20,
                                                color: isPlayingThisAudio ? Colors.greenAccent : Colors.white70,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                msg['text'] ?? '',
                                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Row(
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
                    ),
                  );
                },
              ),
            ),

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
                        border: Border.all(color: _isRecordingAudio ? Colors.redAccent : (_ghostMode ? Colors.purpleAccent : Colors.transparent)),
                      ),
                      child: _isRecordingAudio
                          ? Row(
                              children: [
                                const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 16),
                                const SizedBox(width: 8),
                                Text("Recording... ${_audioRecordDuration}s", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              ],
                            )
                          : TextField(
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
                    backgroundColor: _isRecordingAudio ? Colors.redAccent : Colors.purpleAccent,
                    child: IconButton(
                      icon: Icon(
                        _messageController.text.trim().isNotEmpty
                            ? Icons.send_rounded
                            : (_isRecordingAudio ? Icons.stop_rounded : Icons.mic_rounded),
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () {
                        if (_messageController.text.trim().isNotEmpty) {
                          _sendMessage();
                        } else {
                          _toggleAudioRecording();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScreenContent() {
    if (_isInitialized && _videoController != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
          if (_showControls)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: Colors.black54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                          child: Text(_selectedFileName, style: const TextStyle(color: Colors.purpleAccent, fontSize: 11)),
                        ),
                        IconButton(
                          icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white),
                          onPressed: _toggleFullScreen,
                        ),
                      ],
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
