import 'package:flutter/material.dart';
import 'dart:math';

final Map<String, List<Map<String, String>>> _activeRooms = {};
String? _activeRoomCode;

class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({super.key});

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  final TextEditingController _createRoomController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  bool _isPlaying = true;
  String _currentContentTitle = 'Sample Live Stream Video';
  String _contentType = 'video'; // 'video' ወይም 'document'

  void _showCreateRoomDialog() {
    _createRoomController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          'Create a Room',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a room name or code:',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _createRoomController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Room Name or Code (e.g. Abebe, 1234)',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0D0F14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final customInput = _createRoomController.text.trim();
              final finalCode = customInput.isNotEmpty
                  ? customInput
                  : (1000 + Random().nextInt(9000)).toString();

              setState(() {
                _activeRoomCode = finalCode;
                _activeRooms[finalCode] = [
                  {
                    'id': '1',
                    'sender': 'System',
                    'text': 'Room created! Share Code/Name: $finalCode'
                  },
                ];
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _joinRoom() {
    final inputCode = _roomCodeController.text.trim();

    if (inputCode.isEmpty) {
      _showErrorSnackBar('Please enter a room code or name.');
      return;
    }

    if (_activeRooms.containsKey(inputCode)) {
      setState(() {
        _activeRoomCode = inputCode;
        _activeRooms[inputCode]!.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'sender': 'System',
          'text': 'A user joined Room: $inputCode',
        });
      });
      _roomCodeController.clear();
    } else {
      _showErrorSnackBar('Invalid Room Code! Please enter a valid room code.');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSelectMediaDialog() {
    _videoUrlController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Select Video or Document',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose media to watch or study together:',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              
              // 1. Choose Local Video
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0F14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(Icons.video_file_outlined, color: Colors.pinkAccent),
                  title: const Text('Choose Local Video', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('From your phone storage', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _contentType = 'video';
                      _currentContentTitle = 'Local Video Selected';
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),

              // 2. Choose Document / PDF for Study
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0F14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined, color: Colors.amberAccent),
                  title: const Text('Upload Document / PDF', style: TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: const Text('Study and discuss with friends', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _contentType = 'document';
                      _currentContentTitle = 'Study Document Selected';
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Or Paste Online Link:',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),

              // 3. Online Link Input
              TextField(
                controller: _videoUrlController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Paste Video URL, YouTube, or PDF link...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0D0F14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final link = _videoUrlController.text.trim();
              if (link.isNotEmpty) {
                setState(() {
                  _contentType = link.endsWith('.pdf') ? 'document' : 'video';
                  _currentContentTitle = link;
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Load Media', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _leaveRoom() {
    setState(() {
      _activeRoomCode = null;
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && _activeRoomCode != null) {
      setState(() {
        _activeRooms[_activeRoomCode]!.add({
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
              if (_activeRoomCode != null) {
                setState(() {
                  _activeRooms[_activeRoomCode]!.removeAt(index);
                });
              }
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
                  icon: const Icon(Icons.video_library, color: Colors.amberAccent),
                  onPressed: _showSelectMediaDialog,
                  tooltip: 'Select Content',
                ),
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
            'Watch videos or study documents together in sync with friends in real-time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 36),
          ElevatedButton.icon(
            onPressed: _showCreateRoomDialog,
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
              hintText: 'Enter Room Code or Name...',
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
    final messages = _activeRooms[_activeRoomCode] ?? [];

    return Column(
      children: [
        // Media Viewport Area (Video / Document)
        Container(
          width: double.infinity,
          height: 220,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _contentType == 'document'
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf, size: 56, color: Colors.amberAccent),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Studying Document: $_currentContentTitle',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    )
                  : Column(
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _isPlaying
                                ? 'Playing: $_currentContentTitle'
                                : 'Video Paused',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      color: Colors.pinkAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Live Chat (Room: $_activeRoomCode)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _showSelectMediaDialog,
                child: const Text(
                  '+ Media / Doc',
                  style: TextStyle(color: Colors.pinkAccent, fontSize: 12),
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
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
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
