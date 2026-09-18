import 'package:flutter/material.dart';

class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({super.key});

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  bool _isInRoom = false;
  String _activeRoomCode = "";

  // Chat messages state
  final List<Map<String, String>> _messages = [
    {"user": "አበበ", "text": "እንኳን ደህና መጣችሁ!"},
    {"user": "ሳራ", "text": "ቪዲዮው በጣም ደስ ይላል 🔥"},
  ];
  final TextEditingController _chatController = TextEditingController();

  void _createRoom() {
    String randomCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 899999)).toString();
    setState(() {
      _activeRoomCode = randomCode;
      _isInRoom = true;
    });
  }

  void _joinRoom() {
    if (_roomCodeController.text.trim().isNotEmpty) {
      setState(() {
        _activeRoomCode = _roomCodeController.text.trim();
        _isInRoom = true;
      });
    }
  }

  void _sendMessage() {
    if (_chatController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add({
          "user": "እኔ",
          "text": _chatController.text.trim(),
        });
        _chatController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121217),
      appBar: AppBar(
        title: Text(
          _isInRoom ? "Watch Party (Room: $_activeRoomCode)" : "Watch Party",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF121217),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: _isInRoom
            ? [
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      _isInRoom = false;
                    });
                  },
                )
              ]
            : null,
      ),
      body: _isInRoom ? _buildLiveRoom() : _buildLobby(),
    );
  }

  // Lobby (Room መፍጠሪያ ወይም ማስገቢያ)
  Widget _buildLobby() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups_rounded, size: 80, color: Colors.pinkAccent),
          const SizedBox(height: 16),
          const Text(
            "አብረው ይመልከቱ (Watch Party)",
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "ከጓደኞችዎ ጋር በጋራ ቪዲዮዎችን እያዩ በሪል-ታይም ይወያዩ",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),

          // Create Room Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              label: const Text("አዲስ Room ፍጠር (Create Room)",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: _createRoom,
            ),
          ),

          const SizedBox(height: 24),
          const Row(
            children: [
              Expanded(child: Divider(color: Colors.grey)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text("ወይም", style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 24),

          // Join Room Section
          TextField(
            controller: _roomCodeController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "የ Room Code ያስገቡ...",
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1E1E2C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E2C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text("Room ተቀላቀል (Join)",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: _joinRoom,
            ),
          ),
        ],
      ),
    );
  }

  // Live Room Screen (ቪዲዮ + Chat)
  Widget _buildLiveRoom() {
    return Column(
      children: [
        // Simulated Synced Video Player Box
        Container(
          height: 220,
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_fill, size: 60, color: Colors.pinkAccent),
                  SizedBox(height: 8),
                  Text("Live Synced Video Playing...",
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.white),
                      SizedBox(width: 4),
                      Text("SYNCED", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Live Chat Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: const Color(0xFF1E1E2C),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline, color: Colors.pinkAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                "Live Chat (Room Code: $_activeRoomCode)",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // Messages List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              bool isMe = msg['user'] == "እኔ";
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.pinkAccent : const Color(0xFF1E1E2C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAlignment.end : CrossAlignment.start,
                    children: [
                      Text(
                        msg['user']!,
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.pinkAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        msg['text']!,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Chat Input Bar
        Container(
          padding: const EdgeInsets.all(8),
          color: const Color(0xFF1E1E2C),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "አስተያየት ይፃፉ...",
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.pinkAccent),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
