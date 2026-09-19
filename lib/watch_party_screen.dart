import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({super.key});

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];

  VideoPlayerController? _videoController;
  String _selectedFileName = "No Content Loaded";
  bool _isInitialized = false;

  @override
  void dispose() {
    _videoController?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickVideoFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      _loadLocalVideo(file, result.files.single.name);
    }
  }

  void _loadLocalVideo(File file, String name) {
    _videoController?.dispose();
    setState(() {
      _isInitialized = false;
      _selectedFileName = name;
    });

    _videoController = VideoPlayerController.file(file)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _videoController!.play();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text("Watch Party"),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_library, color: Colors.pinkAccent),
            onPressed: _pickVideoFile,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.black,
            child: _buildScreenContent(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            color: const Color(0xFF1E1E2C),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, color: Colors.red, size: 12),
                    SizedBox(width: 6),
                    Text("LIVE SYNC ACTIVE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Text("Connected", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
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

  Widget _buildScreenContent() {
    if (_isInitialized && _videoController != null) {
      return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          VideoProgressIndicator(
            _videoController!,
            allowScrubbing: true,
            colors: const VideoProgressColors(playedColor: Colors.pinkAccent),
          ),
          IconButton(
            iconSize: 50,
            icon: Icon(
              _videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
              });
            },
          ),
        ],
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_collection, size: 50, color: Colors.pinkAccent),
            const SizedBox(height: 10),
            Text(_selectedFileName, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _pickVideoFile,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              child: const Text("Select Video File"),
            )
          ],
        ),
      );
    }
  }
}
