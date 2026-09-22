import 'async' show Timer;
import 'dart:math';
import 'package:flutter/material.dart';
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

  bool _isLocked = false;
  bool _isAuthenticated = true;
  bool _ghostMode = false;

  @override
  void initState() {
    super.initState();
  }

  // ---------------------------------------------------------------------------
  // 1. Room መፍጠር (Create Room) & Supabase Realtime ማገናኘት
  // ---------------------------------------------------------------------------
  void _createRoom() {
    // በዘፈቀደ (Randomly) የተፈጠረ የ Room Code ቁጥር (ምሳሌ: SEC-8492)
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

    // የሚመጡ የቻት መልእክቶችን ማዳመጥ (Listen)
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

    // ቻናሉን Subscribe ማድረግ እና የኔትወርክ ሁኔታን መከታተል
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
  // 2. Room የተቀላቀሉ አባላት ውይይት (Live Chat)
  // ---------------------------------------------------------------------------
  void _sendMessage({String? customText}) async {
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
      };

      try {
        // መልእክቱን በ Supabase Realtime መላክ
        await _partyChannel?.send(
          type: 'broadcast',
          event: 'chat_message',
          payload: msgMap,
        );

        // በስኬት ከተላከ ብቻ UI ላይ መጨመር
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
        // ኢንተርኔት ከሌለ ማስጠንቀቂያ ማሳየት
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

  // ---------------------------------------------------------------------------
  // 3. ከ Room መውጣት (Exit Room / Leave Room)
  // ---------------------------------------------------------------------------
  void _leaveRoom() {
    if (_partyChannel != null) {
      _supabase.removeChannel(_partyChannel!);
      _partyChannel = null;
    }
    setState(() {
      _roomId = null;
      _messages.clear();
    });
  }

  void _showPasscodePromptDialog() {
    // ላክ የታለፈ ማለፊያ ቃል ካስፈለገ
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
    // Room ካልተፈጠረ Lobby ገጽ ያሳያል
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
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Room ከተፈጠረ በኋላ የሚታይ Live Watch Party & Chat ገጽ
    return Scaffold(
      appBar: AppBar(
        title: Text('Secret Party ($_roomId)'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            tooltip: 'ከ Room ውጣ',
            onPressed: _leaveRoom,
          ),
        ],
      ),
      body: Column(
        children: [
          // ቪዲዮ መመልከቻ ቦታ (Placeholder)
          Container(
            height: 220,
            width: double.infinity,
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.play_circle_fill, size: 60, color: Colors.white54),
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
                          isMe ? CrossAlignment.end : CrossAlignment.start,
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

          // የጽሁፍ ማስገቢያ እና መላኪያ ቦታ (Chat Input Field)
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
