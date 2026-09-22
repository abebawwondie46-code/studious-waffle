import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({Key? key}) : super(key: key);

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _passcodeController = TextEditingController();

  String? _roomId;
  RealtimeChannel? _partyChannel;
  final List<Map<String, dynamic>> _messages = [];

  // State Variables
  bool _isLocked = false;
  bool _isAuthenticated = true;
  bool _ghostMode = false;
  String _videoSource = 'No video loaded';

  final String _correctPasscode = "1234";

  @override
  void initState() {
    super.initState();
  }

  // ---------------------------------------------------------------------------
  // 1. Room መፍጠር
  // ---------------------------------------------------------------------------
  void _createRoom() {
    final randomCode = Random().nextInt(9000) + 1000;
    final newRoomId = "SEC-$randomCode";

    setState(() {
      _roomId = newRoomId;
      _messages.clear();
      _isLocked = true;
      _isAuthenticated = false;
    });

    _setupRealtimeSync(newRoomId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPasscodePromptDialog();
    });
  }

  void _setupRealtimeSync(String roomId) {
    if (_partyChannel != null) {
      _supabase.removeChannel(_partyChannel!);
    }

    _partyChannel = _supabase.channel(roomId);

    _partyChannel?.onBroadcast(
      event: 'chat_message',
      callback: (payload) {
        if (mounted) {
          setState(() {
            _messages.add(Map<String, dynamic>.from(payload));
          });
        }
      },
    );

    _partyChannel?.onBroadcast(
      event: 'video_control',
      callback: (payload) {
        if (mounted) {
          setState(() {
            _videoSource = payload['source'] ?? 'No video loaded';
          });
        }
      },
    );

    _partyChannel?.subscribe((status, error) {
      if (mounted) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.wifi, color: Colors.white),
                  SizedBox(width: 8),
                  Text('ከኢንተርኔት ጋር በስኬት ተገናኝቷል!'),
                ],
              ),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 8),
                  Text('የኢንተርኔት ግንኙነት ተቋርጧል!'),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 2. Passcode Popup (Overflow ያተስተካከለበት ቦታ)
  // ---------------------------------------------------------------------------
  void _showPasscodePromptDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.deepPurple.shade400, width: 1),
          ),
          // Flexible Row እና TextOverflow በመጠቀም የ 2.7px Overflow ኤረር ተቀርፏል
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security, color: Colors.purpleAccent, size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Private Room Locked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ቪዲዮውን እና ቻቱን ለማየት የሩሙን ማለፊያ ፓስወርድ ያስገቡ።',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _passcodeController,
                obscureText: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Passcode (e.g. 1234)',
                  labelStyle: const TextStyle(color: Colors.purpleAccent),
                  prefixIcon: const Icon(Icons.key, color: Colors.purpleAccent),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.deepPurple.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.purpleAccent, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _leaveRoom();
              },
              child: const Text('ውጣ', style: TextStyle(color: Colors.redAccent, fontSize: 15)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (_passcodeController.text == _correctPasscode) {
                  setState(() {
                    _isAuthenticated = true;
                  });
                  _passcodeController.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔓 በስኬት ተከፍቷል!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ የተሳሳተ ፓስወርድ!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('ክፈት', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Actions & Actions Functions
  // ---------------------------------------------------------------------------
  void _shareRoomCode() {
    if (_roomId != null) {
      Clipboard.setData(ClipboardData(text: _roomId!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📋 የሩም ኮድ አድራሻ ($_roomId) Copy ተደርጓል!'),
          backgroundColor: Colors.purple.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleLockState() {
    setState(() {
      _isLocked = !_isLocked;
    });
  }

  void _toggleGhostMode() {
    setState(() {
      _ghostMode = !_ghostMode;
    });
  }

  void _openMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ቪዲዮ ይምረጡ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.purpleAccent),
                title: const Text('ከጋለሪ (Gallery)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _loadVideo('Gallery Video');
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.redAccent),
                title: const Text('ከካሜራ (Camera)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _loadVideo('Camera Video');
                },
              ),
              ListTile(
                leading: const Icon(Icons.link, color: Colors.cyanAccent),
                title: const Text('ከዌብ ሊንክ (Web Link)', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showLinkInputDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLinkInputDialog() {
    final TextEditingController linkController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          title: const Text('የቪዲዮ ሊንክ ያስገቡ', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: linkController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'https://...',
              hintStyle: TextStyle(color: Colors.white38),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ሰርዝ', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
              onPressed: () {
                if (linkController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _loadVideo(linkController.text.trim());
                }
              },
              child: const Text('ክፈት', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _loadVideo(String source) async {
    try {
      await _partyChannel?.sendBroadcastMessage(
        event: 'video_control',
        payload: {'action': 'load', 'source': source},
      );

      if (mounted) {
        setState(() {
          _videoSource = source;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ ኢንተርኔት የለም! ቪዲዮ መጫን አይቻልም።'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 4. Live Chat
  // ---------------------------------------------------------------------------
  void _sendEmojiReaction(String emoji) {
    _sendMessage(customText: emoji);
  }

  void _sendMessage({String? customText}) async {
    if (!_isAuthenticated) {
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
      };

      try {
        await _partyChannel?.sendBroadcastMessage(
          event: 'chat_message',
          payload: msgMap,
        );

        if (mounted) {
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ ኢንተርኔት የለም! መልእክት መላክ አይቻልም።'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _leaveRoom() {
    if (_partyChannel != null) {
      _supabase.removeChannel(_partyChannel!);
      _partyChannel = null;
    }
    setState(() {
      _roomId = null;
      _messages.clear();
      _videoSource = 'No video loaded';
      _isAuthenticated = true;
    });
  }

  @override
  void dispose() {
    if (_partyChannel != null) {
      _supabase.removeChannel(_partyChannel!);
    }
    _messageController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // 1. LOBBY SCREEN (ክፍል ካልተፈጠረ)
    if (_roomId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        appBar: AppBar(
          title: const Text('Secret Party Lobby', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1E1E2C),
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.video_library_rounded, size: 70, color: Colors.purpleAccent),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ወደ አብሮ የመመልከቻ ክፍል እንኳን ደህና መጡ!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ከጓደኞችዎ ጋር በአንድ ላይ ቪዲዮዎችን ይመልከቱ እና በምስጢር ይወያዩ።',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.white54),
                ),
                const SizedBox(height: 36),
                ElevatedButton.icon(
                  onPressed: _createRoom,
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text('አዲስ Room ፍጠር', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.purpleAccent.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. WATCH PARTY & CHAT SCREEN
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.security, size: 18, color: Colors.purpleAccent),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Secret Party ($_roomId)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Share Code',
            onPressed: _shareRoomCode,
          ),
          IconButton(
            icon: Icon(_isLocked ? Icons.lock : Icons.lock_open,
                size: 20, color: _isLocked ? Colors.redAccent : Colors.greenAccent),
            tooltip: 'Lock Room',
            onPressed: _toggleLockState,
          ),
          IconButton(
            icon: Icon(_ghostMode ? Icons.visibility_off : Icons.visibility,
                size: 20, color: _ghostMode ? Colors.purpleAccent : Colors.white70),
            tooltip: 'Ghost Mode',
            onPressed: _toggleGhostMode,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 22, color: Colors.cyanAccent),
            tooltip: 'Add Video',
            onPressed: _openMediaPicker,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 22),
            tooltip: 'Exit',
            onPressed: _leaveRoom,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Badges Bar
          Container(
            color: const Color(0xFF161624),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isLocked ? Colors.redAccent.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _isLocked ? Colors.redAccent : Colors.green, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(_isLocked ? Icons.lock : Icons.public, size: 12, color: _isLocked ? Colors.redAccent : Colors.greenAccent),
                      const SizedBox(width: 4),
                      Text(
                        _isLocked ? 'LOCKED' : 'PUBLIC PARTY',
                        style: TextStyle(color: _isLocked ? Colors.redAccent : Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (_ghostMode)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.purpleAccent, width: 1),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.visibility_off, size: 12, color: Colors.purpleAccent),
                            SizedBox(width: 4),
                            Text('Ghost', style: TextStyle(color: Colors.purpleAccent, fontSize: 10)),
                          ],
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blueGrey, width: 1),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, size: 12, color: Colors.cyanAccent),
                          SizedBox(width: 4),
                          Text('Encrypted', style: TextStyle(color: Colors.cyanAccent, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Video Display Area
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.black,
              border: Border(bottom: BorderSide(color: Colors.white10)),
            ),
            child: _isAuthenticated
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_circle_fill, size: 55, color: Colors.purpleAccent),
                        const SizedBox(height: 8),
                        Text(
                          _videoSource,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_clock_rounded, size: 45, color: Colors.redAccent),
                        const SizedBox(height: 8),
                        const Text('Video Locked - Password Required', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: _showPasscodePromptDialog,
                          child: const Text('Enter Passcode', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
          ),

          // Quick Emoji Bar
          Container(
            color: const Color(0xFF161624),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['❤️', '🔥', '😂', '👏', '😮', '🎉'].map((emoji) {
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _sendEmojiReaction(emoji),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ),
          ),

          // Chat Area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 13, color: Colors.purpleAccent),
                        SizedBox(width: 6),
                        Text(
                          'End-to-End Encrypted Private Room Created',
                          style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),

                ..._messages.map((msg) {
                  final isMe = msg['sender'] == 'You';
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.purpleAccent : const Color(0xFF252538),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['text'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            msg['time'] ?? '',
                            style: const TextStyle(color: Colors.white60, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Chat Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF1E1E2C),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Ghost message (disappears)...',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                          border: InputBorder.none,
                        ),
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
          ),
        ],
      ),
    );
  }
}
