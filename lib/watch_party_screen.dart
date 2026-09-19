import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WatchPartyRoomScreen extends StatefulWidget {
  final String roomId;
  
  const WatchPartyRoomScreen({super.key, required this.roomId});

  @override
  State<WatchPartyRoomScreen> createState() => _WatchPartyRoomScreenState();
}

class _WatchPartyRoomScreenState extends State<WatchPartyRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  String _selectedMediaTitle = "No Video Loaded";

  @override
  void dispose() {
    _videoController?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _loadVideo(String url) {
    _videoController?.dispose();
    setState(() {
      _isInitialized = false;
      _selectedMediaTitle = "Loading Video...";
    });

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _selectedMediaTitle = "Playing Video";
          _videoController!.play();
        });
      }).catchError((error) {
        setState(() {
          _selectedMediaTitle = "Error loading video";
        });
      });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      setState(() {
        _messages.add({
          'sender': 'You',
          'text': _messageController.text.trim(),
        });
        _messageController.clear();
      });
    }
  }

  void _showLinkInputDialog() {
    final TextEditingController linkController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text("Paste Video Link", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: linkController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "https://... (.mp4)",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (linkController.text.isNotEmpty) {
                _loadVideo(linkController.text.trim());
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            child: const Text("Load Video"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        title: Text("Watch Party (Room: ${widget.roomId})"),
        actions: [
          IconButton(
            icon: const Icon(Icons.link, color: Colors.pinkAccent),
            onPressed: _showLinkInputDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Player Area
          Container(
            height: 240,
            width: double.infinity,
            color: Colors.black,
            child: _isInitialized && _videoController != null
                ? Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                      VideoProgressIndicator(
                        _videoController!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.pinkAccent,
                        ),
                      ),
                      IconButton(
                        iconSize: 50,
                        icon: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _videoController!.value.isPlaying
                                ? _videoController!.pause()
                                : _videoController!.play();
                          });
                        },
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.video_library, size: 50, color: Colors.pinkAccent),
                        const SizedBox(height: 10),
                        Text(_selectedMediaTitle, style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _showLinkInputDialog,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                          child: const Text("Paste Video Link"),
                        )
                      ],
                    ),
                  ),
          ),

          // Sync Status Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            color: const Color(0xFF1E1E2C),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Row(
                  children: [
                    Icon(Icons.sync, color: Colors.green, size: 18),
                    SizedBox(width: 6),
                    Text("LIVE SYNC ACTIVE", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Text("2 Users Connected", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),

          // Chat Area
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg['sender'] == 'You' ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: msg['sender'] == 'You' ? Colors.pinkAccent : const Color(0xFF2C2C3E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),

          // Chat Input Field
          Container(
            padding: const EdgeInsets.all(8.0),
            color: const Color(0xFF1E1E2C),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
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
      ),
    );
  }
}
