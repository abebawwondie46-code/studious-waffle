import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final TextEditingController _passcodeController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  bool _isLocked = true; // Private Room Locked Popup ማሳያ
  bool _isGhostMode = false; // Ghost Mode ማብሪያ/ማጥፊያ
  bool _isRoomLockedState = true; // የሩሙ ክፍት/የተቆለፈ ሁኔታ
  final String _correctPasscode = '1234'; // ነባሪ የደህንነት ፓስወርድ

  @override
  void initState() {
    super.initState();
    // ቻቱ ሲጀመር የሚመጣ የስርዓት መልእክት
    _messages.add({
      'text': '🔒 End-to-End Encrypted Private Room Created',
      'isSystem': true,
    });
  }

  // መልእክት መላክ (Ghost Mode ሲበራ ከተወሰነ ሰከንድ በኋላ ይጠፋል)
  void _sendMessage([String? customText]) {
    final text = customText ?? _messageController.text.trim();
    if (text.isNotEmpty) {
      final newMessage = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': text,
        'isMe': true,
        'isSystem': false,
      };

      setState(() {
        _messages.add(newMessage);
      });

      if (customText == null) _messageController.clear();

      // Ghost Mode ሲበራ መልእክቱ ከ5 ሰከንድ በኋላ በራሱ ይጠፋል
      if (_isGhostMode) {
        Timer(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _messages.removeWhere((msg) => msg['id'] == newMessage['id']);
            });
          }
        });
      }
    }
  }

  // የይለፍ ቃል ማረጋገጫ (Unlock Popup)
  void _unlockRoom() {
    if (_passcodeController.text == _correctPasscode) {
      setState(() {
        _isLocked = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('የተሳሳተ ፓስወርድ! (ነባሪ: 1234)')),
      );
    }
  }

  // Media Picker Popup (+ ቁልፍ)
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
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blueAccent),
              title: const Text('ከካሜራ (Camera)', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.link, color: Colors.greenAccent),
              title: const Text('ከዌብ ሊንክ (Web Link)', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _passcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      
      // 1. የላይኛው አሞሌ (App Bar & Actions)
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Secret Party',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'SEC-${widget.roomCode}',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ],
        ),
        actions: [
          // የማጋሪያ አይኮን (Share Icon)
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Share Room Code',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'SEC-${widget.roomCode}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('የሩም ኮድ ኮፒ ተደርጓል!')),
              );
            },
          ),
          // የቁልፍ አይኮን (Lock Icon)
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
          // የዓይን አይኮን (Ghost Mode Icon)
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
                  content: Text(
                    _isGhostMode
                        ? 'Ghost Mode ተበራ (መልእክቶች ከ5 ሰከንድ በኋላ ይጠፋሉ)'
                        : 'Ghost Mode ጠፋ',
                  ),
                ),
              );
            },
          ),
          // የፕላስ አይኮን (Media Picker - +)
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
              // 2. የቪዲዮ ማጫወቻ ክፍል (Video Display Area)
              Container(
                height: 220,
                width: double.infinity,
                color: Colors.black,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_outline, size: 65, color: Colors.white70),
                      SizedBox(height: 8),
                      Text('የተመረጠው ቪዲዮ ማጫወቻ', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
              ),

              // 3. የሁኔታ እና ፈጣን ምላሽ አሞሌዎች (Status & Reaction Bars)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: Colors.grey.shade900,
                child: Row(
                  children: [
                    // PUBLIC PARTY / LOCKED ባጅ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isRoomLockedState ? Colors.red.withAlpha(50) : Colors.green.withAlpha(50),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isRoomLockedState ? Colors.redAccent : Colors.greenAccent,
                        ),
                      ),
                      child: Text(
                        _isRoomLockedState ? 'LOCKED' : 'PUBLIC PARTY',
                        style: TextStyle(
                          color: _isRoomLockedState ? Colors.redAccent : Colors.greenAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    
                    // Ghost & Encrypted ባጆች
                    if (_isGhostMode)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withAlpha(50),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '👻 GHOST',
                          style: TextStyle(color: Colors.purpleAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(50),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '🔒 ENCRYPTED',
                        style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // ኢሞጂዎች (Quick Emoji Bar)
              Container(
                height: 45,
                color: Colors.grey.shade900,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: ['❤️', '😂', '🔥', '👏', '😮', '🎉', '💩', '👍'].map((emoji) {
                    return GestureDetector(
                      onTap: () => _sendMessage(emoji),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Text(emoji, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(height: 1, color: Colors.white12),

              // 4. የቻት እና የመልእክት መላኪያ ክፍል (Chat Section)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];

                    // የሲስተም መልእክት ማሳያ
                    if (message['isSystem'] == true) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            message['text'],
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ),
                      );
                    }

                    final isMe = message['isMe'] ?? true;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.purple.shade700 : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          message['text'],
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // የመልእክት መላኪያ ሳጥን እና የላክ አዝራር (Send Button - >)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.grey.shade900,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _isGhostMode
                              ? 'Ghost message (disappears)...'
                              : 'መልእክት ይጻፉ...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          fillColor: Colors.black,
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      backgroundColor: Colors.purpleAccent,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18), // Send Button ( > )
                        onPressed: () => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Private Room Locked Popup (ደህንነት መስኮት)
          if (_isLocked)
            Container(
              color: Colors.black.withAlpha(230),
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
                        'ቪዲዮውን እና ቻቱን ለማየት የክፍሉን ፓስወርድ ያስገቡ።',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passcodeController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'ፓስወርድ ያስገቡ (ነባሪ: 1234)',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.grey.shade900,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.purpleAccent),
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
                        child: const Text('ክፈት (Unlock)', style: TextStyle(color: Colors.white, fontSize: 16)),
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
