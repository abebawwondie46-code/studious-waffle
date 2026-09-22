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
  bool _isLocked = true;
  bool _isAuthenticated = true;
  bool _ghostMode = false;
  String _videoSource = 'No Content Loaded';
  final String _correctPasscode = "1234";

  @override
  void initState() {
    super.initState();
  }

  // ---------------------------------------------------------------------------
  // Realtime Sync & Room Setup
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
            _videoSource = payload['source'] ?? 'No Content Loaded';
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
                  Text('ከኢንተርኔት ጋር ተገናኝቷል!'),
                ],
              ),
              backgroundColor: const Color(0xFF8A2BE2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            ),
          );
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Action Handlers
  // ---------------------------------------------------------------------------
  void _shareRoomCode() {
    if (_roomId != null) {
      Clipboard.setData(ClipboardData(text: _roomId!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📋 የሩም ኮድ አድራሻ ($_roomId) Copy ተደርጓል!'),
          backgroundColor: const Color(0xFFD800A6),
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
      backgroundColor: const Color(0xFF141221),
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
                leading: const Icon(Icons.photo_library, color: Color(0xFFE040FB)),
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
          backgroundColor: const Color(0xFF141221),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD800A6)),
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

  void _showPasscodePromptDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141221),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF8A2BE2), width: 1),
          ),
          title: const Row(
            children: [
              Icon(Icons.security, color: Color(0xFFE040FB), size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Private Room Locked',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 16),
              TextField(
                controller: _passcodeController,
                obscureText: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Enter Passcode (e.g. 1234)',
                  labelStyle: const TextStyle(color: Color(0xFFE040FB)),
                  filled: true,
                  fillColor: Colors.black38,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF8A2BE2)),
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
              child: const Text('ውጣ', style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD800A6)),
              onPressed: () {
                if (_passcodeController.text == _correctPasscode) {
                  setState(() {
                    _isAuthenticated = true;
                  });
                  _passcodeController.clear();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ የተሳሳተ ፓስወርድ!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('ክፈት', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

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
      _videoSource = 'No Content Loaded';
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
  // UI Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_roomId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0914),
        appBar: AppBar(
          title: const Text('Secret Party Lobby', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF141221),
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1A34),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD800A6), width: 2),
                ),
                child: const Icon(Icons.vpn_key_rounded, size: 60, color: Color(0xFFE040FB)),
              ),
              const SizedBox(height: 20),
              const Text(
                'ወደ አብሮ የመመልከቻ ክፍል እንኳን ደህና መጡ!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _createRoom,
                icon: const Icon(Icons.add_rounded),
                label: const Text('አዲስ Room ፍጠር'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD800A6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0914),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141221),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.vpn_key_rounded, color: Color(0xFFE040FB), size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Secret Party', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(_roomId ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFFE040FB))),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white70, size: 20),
            onPressed: _shareRoomCode,
          ),
          IconButton(
            icon: Icon(_isLocked ? Icons.lock : Icons.lock_open,
                color: _isLocked ? const Color(0xFFFF5252) : Colors.greenAccent, size: 20),
            onPressed: _toggleLockState,
          ),
          IconButton(
            icon: Icon(_ghostMode ? Icons.visibility_off : Icons.visibility,
                color: _ghostMode ? const Color(0xFFE040FB) : Colors.white70, size: 20),
            onPressed: _toggleGhostMode,
          ),
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Color(0xFFE040FB), size: 22),
            onPressed: _openMediaPicker,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 22),
            onPressed: _leaveRoom,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Media Player Display Area
          Container(
            height: 210,
            width: double.infinity,
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF201B35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, size: 48, color: Color(0xFFE040FB)),
                ),
                const SizedBox(height: 12),
                Text(_videoSource, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: _openMediaPicker,
                  icon: const Icon(Icons.lock_open_rounded, size: 16),
                  label: const Text('Load Private Content', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD800A6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  ),
                ),
              ],
            ),
          ),

          // 2. Status Bar & Badges
          Container(
            color: const Color(0xFF141221),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
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
                    const SizedBox(width: 6),
                    Text(
                      _isLocked ? 'LOCKED (PIN: 1234)' : 'PUBLIC PARTY',
                      style: TextStyle(
                        color: _isLocked ? const Color(0xFFFF5252) : Colors.greenAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 12, color: Colors.white38),
                  ],
                ),
                const Spacer(),
                if (_ghostMode)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D1B4E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.visibility_off, size: 12, color: Color(0xFFE040FB)),
                        SizedBox(width: 4),
                        Text('Ghost', style: TextStyle(color: Color(0xFFE040FB), fontSize: 10)),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2638),
                    borderRadius: BorderRadius.circular(12),
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
          ),

          // 3. Quick Emoji Reaction Bar
          Container(
            color: const Color(0xFF100E1B),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['😮', '🔒', '🔥', '😂', '👏', '🎉', '👻'].map((emoji) {
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _sendEmojiReaction(emoji),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1C1A2E),
                      shape: BoxShape.circle,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 16)),
                  ),
                );
              }).toList(),
            ),
          ),

          // 4. Chat Messages Area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF231238),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF8A2BE2).withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 12, color: Color(0xFFE040FB)),
                        SizedBox(width: 6),
                        Text(
                          'End-to-End Encrypted Private Room Created',
                          style: TextStyle(color: Color(0xFFE040FB), fontSize: 11),
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
                        color: isMe ? const Color(0xFFD800A6) : const Color(0xFF1C1A2E),
                        borderRadius: BorderRadius.circular(16),
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

          // 5. Styled Chat Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFF141221),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0914),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: const Color(0xFF8A2BE2), width: 1.5),
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
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD800A6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
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
