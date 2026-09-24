import 'package:flutter/material.dart';

class WatchPartyScreen extends StatefulWidget {
  final String roomCode;
  final String videoUrl;

  const WatchPartyScreen({
    super.key,
    required this.roomCode,
    required this.videoUrl,
  });

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  // መልእክት መላክ (Live Chat)
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({
          'text': text,
          'isMe': true,
          'time': DateTime.now(),
        });
      });
      _messageController.clear();
    }
  }

  // ከ Room መውጣት (ወደ Lobby መመለስ)
  void _exitRoom() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ከ Room መውጣት'),
        content: const Text('እርግጠኛ ነዎት ከዚህ Room መውጣት ይፈልጋሉ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('አይ'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); // Dialog መዝጋት
              Navigator.pop(context); // ወደ Main/Lobby Screen መመለስ
            },
            child: const Text('ውጣ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // የ Room Code ከላይ በ App Bar ላይ እንዲታይ
        title: Text('Room Code: ${widget.roomCode}'),
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false, // ነባሪውን የጀርባ ፍላጻ ለማጥፋት
        actions: [
          // የቀይ መውጫ ቁልፍ (Exit Icon)
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
            tooltip: 'ከ Room ውጣ',
            onPressed: _exitRoom,
          ),
        ],
      ),
      body: Column(
        children: [
          // የቪዲዮ ማጫወቻ ቦታ
          Container(
            height: 220,
            color: Colors.black,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_fill, size: 60, color: Colors.white),
                  SizedBox(height: 8),
                  Text('ቪዲዮ እየተጫወተ ነው...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),

          // የ Chat ርዕስ እና የ Room Code ማሳያ
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.deepPurple.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  'የውይይት ክፍል (Room: ${widget.roomCode})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // የመልእክቶች ዝርዝር ማሳያ (Live Chat)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['isMe'] ?? true;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.deepPurple : Colors.grey.shade300,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(isMe ? 12 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 12),
                      ),
                    ),
                    child: Text(
                      message['text'],
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // የታችኛው የጽሁፍ ሳጥን እና የላኪያ ቁልፍ
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'መልእክት ይጻፉ...',
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
