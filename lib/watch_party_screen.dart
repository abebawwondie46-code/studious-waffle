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

  String? _roomId;
  RealtimeChannel? _partyChannel;
  final List<Map<String, dynamic>> _messages = [];

  // State Variables
  bool _isLocked = false;
  bool _ghostMode = false;
  String _videoSource = 'No video loaded';

  @override
  void initState() {
    super.initState();
  }

  // ---------------------------------------------------------------------------
  // 1. Room መፍጠር (Create Room)
  // ---------------------------------------------------------------------------
  void _createRoom() {
    final randomCode = Random().nextInt(9000) + 1000;
    final newRoomId = "SEC-$randomCode";

    setState(() {
      _roomId = newRoomId;
      _messages.clear();
    });

    _setupRealtimeSync(newRoomId);
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
  // APP BAR ACTION FUNCTIONS
  // ---------------------------------------------------------------------------

  // 1. Share Icon Action: የሩሙን ኮድ ክሊፕቦርድ ላይ Copy በማድረግ ማጋራት
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

  // 2. Lock Icon Action: የሩሙን ክፍት/የተቆለፈ ሁኔታ መቀየር
  void _toggleLockState() {
    setState(() {
      _isLocked = !_isLocked;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLocked
            ? '🔒 ሩሙ ተቆልፏል! አዲስ አባላት አይቀላቀሉም።'
            : '🔓 ሩሙ ተከፍቷል!'),
        backgroundColor: _isLocked ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 3. Ghost Mode Icon Action: የይለፍ መልእክቶች ከ15 ሰከንድ በኋላ እንዲጠፉ ማብራት/ማጥፋት
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

  // 4. Media Picker (+ Icon) Action: ቪዲዮ ከጋለሪ፣ ከካሜራ ወይም ከዌብ ሊንክ መምረጫ BottomSheet
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
      // ለክፍሉ አባላት ቪዲዮ መጫኑን በ Realtime መላክ
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
  // Live Chat Function
  // ---------------------------------------------------------------------------
  void _sendMessage({String? customText}) async {
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
    });
  }

  @override
  void dispose() {
    if (_partyChannel != null) {
      _supabase.removeChannel(_partyChannel!);
    }
    _messageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Secret Party ($_roomId)'),
        backgroundColor: Colors.deepPurple,
        actions: [
          // 1. Share Icon (የሩሙን ኮድ ለማጋራት)
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Room Code',
            onPressed: _shareRoomCode,
          ),
          // 2. Lock Icon (ሩሙን ለመቆለፍ/ለመክፈት)
          IconButton(
            icon: Icon(_isLocked ? Icons.lock : Icons.lock_open),
            tooltip: 'Lock/Unlock Room',
            onPressed: _toggleLockState,
          ),
          // 3. Ghost Mode Icon (ለይለፍ መልእክቶች ማብሪያ/ማጥፊያ)
          IconButton(
            icon: Icon(_ghostMode ? Icons.visibility_off : Icons.visibility),
            tooltip: 'Ghost Mode',
            onPressed: _toggleGhostMode,
          ),
          // 4. Media Picker Icon (+) (ቪዲዮ መምረጫ)
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Video',
            onPressed: _openMediaPicker,
          ),
          // 5. Exit Icon (ከሩም መውጫ)
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            tooltip: 'Exit Room',
            onPressed: _leaveRoom,
          ),
        ],
      ),
      body: Column(
        children: [
          // ቪዲዮ መመልከቻ ቦታ
          Container(
            height: 220,
            width: double.infinity,
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill, size: 60, color: Colors.white54),
                  const SizedBox(height: 10),
                  Text(
                    _videoSource,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          // የቻት መልእክቶች ዝርዝር
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
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
              },
            ),
          ),

          // የጽሁፍ ማስገቢያ እና መላኪያ ቦታ (Chat Input)
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.black26,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type secret message...',
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
