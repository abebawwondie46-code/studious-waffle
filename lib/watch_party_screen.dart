import 'package:flutter/material.dart';
import 'dart:math';

// መልእክቶች ከሩም ወጥተህ ስትመለስ እንዳይጠፉ በState ደረጃ መቀመጥ አለባቸው
List<Map<String, String>> _globalMessages = [];
String? _activeRoomCode;

class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({super.key});

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  bool _isPlaying = true;

  void _createRoom() {
    final randomCode = (100000 + Random().nextInt(900000)).toString();
    setState(() {
      _activeRoomCode = randomCode;
      _globalMessages = [
        {'id': '1', 'sender': 'System', 'text': 'Room created! Share code: $randomCode'},
      ];
    });
  }

  void _joinRoom() {
    final inputCode = _roomCodeController.text.trim();
    if (inputCode.isNotEmpty) {
      setState(() {
        _activeRoomCode = inputCode;
        if (_globalMessages.isEmpty) {
          _globalMessages.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'sender': 'System',
            'text': 'Joined Room: $inputCode',
          });
        }
      });
      _roomCodeController.clear();
    }
  }

  void _leaveRoom() {
    setState(() {
      _activeRoomCode = null;
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _globalMessages.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'sender': 'You',
          'text': text,
        });
        _messageController.clear();
      });
      _scrollToBottom();
    }
  }

  void _deleteMessage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('Delete Message', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this message?',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _globalMessages.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      appBar: AppBar(
        title: Text(
          _activeRoomCode == null
              ? 'Watch Party'
              : 'Watch Party (Room: $_activeRoomCode)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E1E2C),
        elevation: 0,
        actions: _activeRoomCode != null
            ? [
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.pinkAccent),
                  onPressed: _leaveRoom,
                  tooltip: 'Leave Room',
                )
              ]
            : null,
      ),
      body: SafeArea(
        child: _activeRoomCode == null ? _buildLobbyUI() : _buildActiveRoomUI(),
      ),
    );
  }

  Widget _buildLobbyUI() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.groups_rounded,
            size: 80,
            color: Colors.pinkAccent,
          ),
          const SizedBox(height: 20),
          const Text(
            'Watch Party',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Watch videos together in sync and chat with friends in real-time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 36),
          ElevatedButton.icon(
            onPressed: _createRoom,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Create Room'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: const [
              Expanded(child: Divider(color: Colors.white24)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              Expanded(child: Divider(color: Colors.white24)),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _roomCodeController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: 'Enter Room Code...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1E1E2C),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _joinRoom,
            icon: const Icon(Icons.login),
            label: const Text('Join Room'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1E2C),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRoomUI() {
    return Column(
      children: [
        // Video Viewport Area
        Container(
          width: double.infinity,
          height: 220,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 56,
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: Colors.pinkAccent,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPlaying = !_isPlaying;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPlaying
                        ? 'Live Synced Video Playing...'
                        : 'Video Paused',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '● SYNCED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Live Chat Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF1E1E2C),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  color: Colors.pinkAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Live Chat (Room Code: $_activeRoomCode)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Chat Messages List
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _globalMessages.length,
            itemBuilder: (context, index) {
              final msg = _globalMessages[index];
              final isMe = msg['sender'] == 'You';
              final isSystem = msg['sender'] == 'System';

              if (isSystem) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['text']!,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                );
              }

              return GestureDetector(
                onLongPress: () => _deleteMessage(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['sender']!,
                        style: TextStyle(
                          color: isMe ? Colors.pinkAccent : Colors.amberAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.pinkAccent.withOpacity(0.2)
                              : const Color(0xFF1E1E2C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          msg['text']!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Input Field Area
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF1E1E2C),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onSubmitted: (_) => _sendMessage(),
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
