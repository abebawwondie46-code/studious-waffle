import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class WatchPartyScreen extends StatefulWidget {
  final String roomCode;

  const WatchPartyScreen({
    super.key,
    this.roomCode = '7069',
  });

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  String _errorMessage = '';
  final ImagePicker _picker = ImagePicker();

  bool _isLocked = true;
  bool _isGhostMode = false;
  bool _isRoomLockedState = true;
  bool _isMuted = false;
  final String _correctPasscode = '1234';

  @override
  void initState() {
    super.initState();
    _fetchVideoFromSupabase();
  }

  // 1. ከ Supabase በ room_id ተለይቶ ቪዲዮ መከታተያ (NULL ያልሆኑትን ብቻ ይወስዳል)
  void _fetchVideoFromSupabase() {
    _supabase
        .from('videos')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomCode)
        .listen((data) {
      if (data.isNotEmpty) {
        final validVideos = data.where((item) => 
          item['video_url'] != null && 
          item['video_url'].toString().startsWith('http')
        ).toList();

        if (validVideos.isNotEmpty) {
          String videoUrl = validVideos.last['video_url'];
          _initializeVideoFromUrl(videoUrl);
        }
      }
    }, onError: (error) {
      setState(() {
        _hasVideoError = true;
        _errorMessage = 'ከኢንተርኔት ጋር መገናኘት አልተቻለም';
      });
    });
  }

  // ቪዲዮውን ከኢንተርኔት ጫኖ የማዘጋጀት ስራ
  Future<void> _initializeVideoFromUrl(String url) async {
    if (url.isEmpty) return;
    
    setState(() {
      _isVideoInitialized = false;
      _hasVideoError = false;
    });

    await _videoController?.dispose();

    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      
      await _videoController!.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('የኢንተርኔት ኮኔክሽን ዘገምተኛ ነው ወይም ቪዲዮው አልተገኘም');
        },
      );

      _videoController!.addListener(() {
        if (_videoController!.value.hasError) {
          setState(() {
            _hasVideoError = true;
            _errorMessage = 'ቪዲዮውን ማጫወት አልተቻለም';
          });
        }
        setState(() {}); 
      });

      setState(() {
        _isVideoInitialized = true;
        _hasVideoError = false;
      });
      _videoController?.play();
    } catch (e) {
      setState(() {
        _hasVideoError = true;
        _errorMessage = 'ቪዲዮውን መጫን አልተቻለም፦ ኢንተርኔትዎን ወይም ሊንኩን ያረጋግጡ';
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickVideo(source: source);
    if (pickedFile != null) {
      setState(() {
        _isVideoInitialized = false;
        _hasVideoError = false;
      });
      await _videoController?.dispose();

      try {
        _videoController = VideoPlayerController.file(File(pickedFile.path));
        await _videoController!.initialize();
        _videoController!.addListener(() {
          setState(() {});
        });
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController?.play();
      } catch (e) {
        setState(() {
          _hasVideoError = true;
          _errorMessage = 'ፋይሉን ማጫወት አልተቻለም';
        });
      }
    }
  }

  // 2. room_id ሁልጊዜ '7069' ሆኖ እንዲገባ ማስተካከያ
  Future<void> _updateVideoUrlInSupabase(String url) async {
    try {
      await _supabase.from('videos').insert({
        'video_url': url,
        'room_id': widget.roomCode, // NULL እንዳይሆን በትክክል roomCode ይልካል
      });
    } catch (e) {
      debugPrint('Error inserting video: $e');
    }
  }

  void _showLinkInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('የቪዲዮ URL ያስገቡ', style: TextStyle(color: Colors.white)),
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
                _updateVideoUrlInSupabase(_urlController.text.trim());
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

  Future<void> _sendMessage([String? customText]) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isNotEmpty) {
      if (customText == null) _messageController.clear();

      final response = await _supabase.from('comments').insert({
        'text': text,
        'room_id': widget.roomCode,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (_isGhostMode && response.isNotEmpty) {
        final String msgId = response.first['id'].toString();
        Timer(const Duration(seconds: 10), () async {
          await _supabase.from('comments').delete().eq('id', msgId);
        });
      }
    }
  }

  void _confirmDeleteMessage(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('መልእክት አጥፋ', style: TextStyle(color: Colors.white)),
        content: const Text('ይህንን መልእክት ማጥፋት እርግጠኛ ነዎት?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('አይ'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _supabase.from('comments').delete().eq('id', id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('መልእክቱ ተጠፍቷል')),
              );
            },
            child: const Text('አጥፋ', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _unlockRoom() {
    if (_passcodeController.text == _correctPasscode) {
      setState(() {
        _isLocked = false;
      });
      _passcodeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('የተሳሳተ ፓስወርድ! (ትክክለኛው: 1234)')),
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
              leading: const Icon(Icons.link, color: Colors.greenAccent),
              title: const Text('ከSupabase / Web URL', style: TextStyle(color: Colors.white)),
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Secret Party',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                SnackBar(content: Text('የሩም መግቢያ ኮድ SEC-${widget.roomCode} ኮፒ ተደርጓል!')),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isGhostMode ? 'Ghost Mode ተበርቷል (መልእክት ከ10 ሰከንድ በኋላ ይጠፋል)' : 'Ghost Mode ተጠፍቷል'),
                  duration: const Duration(seconds: 2),
                ),
              );
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
              Container(
                height: 240,
                width: double.infinity,
                color: Colors.grey.shade900,
                child: _hasVideoError
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 40),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
                            onPressed: _showLinkInputDialog,
                            icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                            label: const Text('አዲስ ቪዲዮ/ሊንክ አስገባ', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      )
                    : _isVideoInitialized && _videoController != null
                        ? Column(
                            children: [
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AspectRatio(
                                      aspectRatio: _videoController!.value.aspectRatio,
                                      child: VideoPlayer(_videoController!),
                                    ),
                                    IconButton(
                                      iconSize: 55,
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
                                    Positioned(
                                      right: 10,
                                      top: 10,
                                      child: IconButton(
                                        icon: Icon(
                                          _isMuted ? Icons.volume_off : Icons.volume_up,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isMuted = !_isMuted;
                                            _videoController!.setVolume(_isMuted ? 0 : 1);
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  children: [
                                    Text(
                                      _formatDuration(_videoController!.value.position),
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                    Expanded(
                                      child: SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                          trackHeight: 3,
                                        ),
                                        child: Slider(
                                          value: _videoController!.value.position.inSeconds.toDouble(),
                                          max: _videoController!.value.duration.inSeconds.toDouble() > 0
                                              ? _videoController!.value.duration.inSeconds.toDouble()
                                              : 1.0,
                                          activeColor: Colors.purpleAccent,
                                          inactiveColor: Colors.white24,
                                          onChanged: (value) {
                                            _videoController!.seekTo(Duration(seconds: value.toInt()));
                                          },
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_videoController!.value.duration),
                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.purpleAccent),
                                SizedBox(height: 10),
                                Text(
                                  'ቪዲዮው ከኢንተርኔት እየተጫነ ነው...',
                                  style: TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isRoomLockedState ? Colors.red.withAlpha(40) : Colors.green.withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _isRoomLockedState ? Colors.redAccent : Colors.greenAccent),
                        ),
                        child: Text(
                          _isRoomLockedState ? '🔒 LOCKED ROOM' : '🌐 PUBLIC PARTY',
                          style: TextStyle(
                            color: _isRoomLockedState ? Colors.redAccent : Colors.greenAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isGhostMode)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purpleAccent),
                          ),
                          child: const Text(
                            '👻 GHOST MODE',
                            style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (_isGhostMode) const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueAccent),
                        ),
                        child: const Text(
                          '🔐 ENCRYPTED',
                          style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase
                      .from('comments')
                      .stream(primaryKey: ['id'])
                      .eq('room_id', widget.roomCode)
                      .order('created_at', ascending: true),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                    }

                    final messages = snapshot.data!;

                    return ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '🔒 End-to-End Encrypted Private Room Created',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ),
                        ),
                        ...messages.map((msg) {
                          final String text = msg['text'] ?? '';
                          final String id = msg['id'].toString();

                          return GestureDetector(
                            onLongPress: () => _confirmDeleteMessage(id),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isGhostMode ? Colors.purple.shade900 : Colors.purple.shade700,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  text,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _isGhostMode ? 'Ghost message (disappears)...' : 'Type a message...',
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

          if (_isLocked)
            Container(
              color: Colors.black.withAlpha(245),
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
                      const SizedBox(height: 8),
                      const Text(
                        'ቪዲዮውን እና ቻቱን ለማየት ይለፍ ቃል ያስገቡ',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passcodeController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'ፓስወርድ (1234)',
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
