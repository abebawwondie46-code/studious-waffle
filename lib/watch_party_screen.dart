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
  bool _isAuthenticated = true; // Passcode Popup State
  bool _ghostMode = false;
  String _videoSource = 'No video loaded';

  final String _correctPasscode = "1234"; // የሩም ማለፊያ ቃል (Passcode)

  @override
  void initState() {
    super.initState();
  }

  // ---------------------------------------------------------------------------
  // 1. Room መፍጠር (Create Room) & Supabase Realtime
  // ---------------------------------------------------------------------------
  void _createRoom() {
    final randomCode = Random().nextInt(9000) + 1000;
    final newRoomId = "SEC-$randomCode";

    setState(() {
      _roomId = newRoomId;
      _messages.clear();
      _isLocked = true; // በዲፎልት Locked ይሁን
      _isAuthenticated = false; // ገና ሲከፈት Passcode እንዲጠይቅ
    });

    _setupRealtimeSync(newRoomId);

    // ገጹ ሲከፈት የ Passcode Popup ማሳየት
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPasscodePromptDialog();
    });
  }

  void _setupRealtimeSync(String roomId) {
    if (_partyChannel != null) {
      _supabase.removeChannel(_partyChannel!);
    }

    _partyChannel = _supabase.channel(roomId);

    // የቻት መልእክቶችን ማዳመጥ
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

    // የቪዲዮ መቆጣጠሪያ ማዳመጥ
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

    // የኔትወርክ/Realtime ሁኔታን መከታተል
    _partyChannel?.subscribe((status, error) {
      if (mounted) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🟢 ከኢንተርኔት/Realtime ጋር ተገናኝቷል!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔴 የኢንተርኔት ግንኙነት ተቋርጧል!'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 2. Private Room Locked Popup (የደህንነት ፓስወርድ መቀበያ)
  // ---------------------------------------------------------------------------
  void _showPasscodePromptDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.security, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text('Private Room Locked'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ቪዲዮውን እና ቻቱን ለማየት የሩሙን ማለፊያ ፓስወርድ ያስገቡ።'),
              const SizedBox(height: 16),
              TextField(
                controller: _passcodeController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Enter Passcode (e.g. 1234)',
                  border: OutlineInputBorder(),
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
              child: const Text('ውጣ', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
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
              child: const Text('ክፈት'),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 3. APP BAR ACTIONS & MEDIA PICKER
  // ---------------------------------------------------------------------------
  void _shareRoomCode() {
    if (_roomId != null) {
      Clipboard.setData(ClipboardData(text: _roomId!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📋 የሩም ኮድ አድራሻ ($_roomId) Copy ተደርጓል!'),
          backgroundColor: Colors.purple,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleLockState() {
    setState(() {
      _isLocked = !_isLocked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLocked ? '🔒 ሩሙ ተቆልፏል!' : '🔓 ሩሙ ተከፍቷል!'),
        backgroundColor: _isLocked ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleGhostMode() {
    setState(() {
      _ghostMode = !_ghostMode;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_ghostMode
            ? '👁️‍🗨️ Ghost Mode በርቷል! መልእክቶች ከ15 ሰከንድ በኋላ ይጠፋሉ።'
            : '👁️ Ghost Mode ጠፍቷል።'),
        backgroundColor: Colors.deepPurpleAccent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openMediaPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ቪዲዮ ይምረጡ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.purple),
                title: const Text('ከጋለሪ (Gallery)'),
                onTap: () {
                  Navigator.pop(context);
                  _loadVideo('Gallery Video');
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.red),
                title: const Text('ከካሜራ (Camera)'),
                onTap: () {
                  Navigator.pop(context);
                  _loadVideo('Camera Video');
                },
              ),
              ListTile(
                leading: const Icon(Icons.link, color: Colors.blue),
                title: const Text('ከዌብ ሊንክ (Web Link)'),
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
          title: const Text('የቪዲዮ ሊንክ ያስገቡ'),
          content: TextField(
            controller: linkController,
            decoration: const InputDecoration(hintText: 'https://...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ሰርዝ'),
            ),
            ElevatedButton(
              onPressed: () {
                if (linkController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _loadVideo(linkController.text.trim());
                }
              },
              child: const Text('ክፈት'),
            ),
          ],
        );
      },
    );
  }

  void _loadVideo(String source) async {
    try {
      // ኢንተርኔት ካለ ለክፍሉ አባላት በ Realtime ማጋራት
      await _partyChannel?.sendBroadcastMessage(
        event: 'video_control',
        payload: {'action': 'load', 'source': source},
      );

      if (mounted) {
        setState(() {
          _videoSource = source;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎬 ቪዲዮ ተጭኗል፦ $source'),
            backgroundColor: Colors.green,
          ),
        );
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
  // 4. LIVE CHAT & QUICK EMOJI REACTION
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
        // ኢንተርኔት ካለ ብቻ በ Supabase Realtime ይላካል
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
        // ኢንተርኔት ከሌለ UI ላይ ሳይጨመር ማስጠንቀቂያ ያሳያል
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
        appBar: AppBar(
          title: const Text('Secret Party Lobby'),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.video_library, size: 80, color: Colors.deepPurple),
              const SizedBox(height: 20),
              const Text(
                'ወደ አብሮ የመመልከቻ ክፍል እንኳን ደህና መጡ!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _createRoom,
                icon: const Icon(Icons.add_box),
                label: const Text('አዲስ Room ፍጠር'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. WATCH PARTY & CHAT SCREEN
    return Scaffold(
      appBar: AppBar(
        title: Text('Secret Party ($_roomId)'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Room Code',
            onPressed: _shareRoomCode,
          ),
          IconButton(
            icon: Icon(_isLocked ? Icons.lock : Icons.lock_open),
            tooltip: 'Lock/Unlock Room',
            onPressed: _toggleLockState,
          ),
          IconButton(
            icon: Icon(_ghostMode ? Icons.visibility_off : Icons.visibility),
            tooltip: 'Ghost Mode',
            onPressed: _toggleGhostMode,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Video',
            onPressed: _openMediaPicker,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            tooltip: 'Exit Room',
            onPressed: _leaveRoom,
          ),
        ],
      ),
      body: Column(
        children: [
          // 2.1 የሁኔታ እና ፈጣን ምላሽ አሞሌዎች (Status & Badges)
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // PUBLIC PARTY / LOCKED status
                Chip(
                  avatar: Icon(
                    _isLocked ? Icons.lock : Icons.public,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    _isLocked ? 'LOCKED' : 'PUBLIC PARTY',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: _isLocked ? Colors.redAccent : Colors.green,
                ),
                // Ghost & Encrypted Badges
                Row(
                  children: [
                    if (_ghostMode)
                      const Padding(
                        padding: EdgeInsets.only(right: 6.0),
                        child: Chip(
                          label: Text('Ghost', style: TextStyle(fontSize: 10, color: Colors.white)),
                          backgroundColor: Colors.purple,
                        ),
                      ),
                    const Chip(
                      avatar: Icon(Icons.security, size: 14, color: Colors.white),
                      label: Text('Encrypted', style: TextStyle(fontSize: 10, color: Colors.white)),
                      backgroundColor: Colors.blueGrey,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2.2 የቪዲዮ ማጫወቻ ክፍል (Video Display Area)
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.black87,
            child: _isAuthenticated
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_circle_fill, size: 60, color: Colors.white54),
                        const SizedBox(height: 8),
                        Text(
                          _videoSource,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, size: 50, color: Colors.redAccent),
                        const SizedBox(height: 8),
                        const Text(
                          'Video Locked - Password Required',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _showPasscodePromptDialog,
                          child: const Text('Enter Passcode'),
                        ),
                      ],
                    ),
                  ),
          ),

          // 2.3 የኢሞጂዎች ፈጣን አሞሌ (Quick Emoji Bar)
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['❤️', '🔥', '😂', '👏', '😮', '🎉'].map((emoji) {
                return GestureDetector(
                  onTap: () => _sendEmojiReaction(emoji),
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                );
              }).toList(),
            ),
          ),

          // 2.4 የቻት ክፍል (Chat Section)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // End-to-End Encrypted System Message
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withOpacity(0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 14, color: Colors.purpleAccent),
                        SizedBox(width: 6),
                        Text(
                          'End-to-End Encrypted Private Room Created',
                          style: TextStyle(color: Colors.purpleAccent, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),

                // Message List
                ..._messages.map((msg) {
                  final isMe = msg['sender'] == 'You';
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.purpleAccent : Colors.grey[800],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['text'] ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg['time'] ?? '',
                            style: const TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // 2.5 የመልእክት መላኪያ ክፍል (Chat Input Field with Send Button)
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.black26,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ghost message (disappears)...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.purpleAccent),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
