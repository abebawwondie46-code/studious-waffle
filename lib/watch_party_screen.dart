import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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
  final ImagePicker _picker = ImagePicker();

  VideoPlayerController? _videoController;
  File? _selectedFile;
  String _mediaType = 'none'; // 'video', 'document', 'none'
  String _selectedFileName = "No Content Loaded";
  bool _isInitialized = false;

  @override
  void dispose() {
    _videoController?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // 1. Pick Video from Gallery
  Future<void> _pickFromGallery() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _loadLocalVideo(File(video.path), video.name);
    }
  }

  // 2. Record Video with Camera
  Future<void> _recordWithCamera() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      _loadLocalVideo(File(video.path), "Recorded Video");
    }
  }

  // 3. Pick Study Document
  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      _videoController?.dispose();
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
        _mediaType = 'document';
        _isInitialized = true;
      });
    }
  }

  void _loadLocalVideo(File file, String name) {
    _videoController?.dispose();
    setState(() {
      _isInitialized = false;
      _mediaType = 'video';
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

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Select Video or Document",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.pinkAccent),
                title: const Text("Choose from Gallery", style: TextStyle(color: Colors.white)),
                subtitle: const Text("Select local video from storage", style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),

              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.pinkAccent),
                title: const Text("Record with Camera", style: TextStyle(color: Colors.white)),
                subtitle: const Text("Record a video now", style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _recordWithCamera();
                },
              ),

              ListTile(
                leading: const Icon(Icons.menu_book, color: Colors.pinkAccent),
                title: const Text("Select Study Document", style: TextStyle(color: Colors.white)),
                subtitle: const Text("Read and discuss documents together", style: TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
            ],
          ),
        );
      },
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
            icon: const Icon(Icons.add_to_photos, color: Colors.pinkAccent),
            onPressed: _showMediaPicker,
          ),
        ],
      ),
      body: Column(
        children: [
          // Screen Viewer Container
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.black,
            child: _buildScreenContent(),
          ),

          // Live Sync Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            color: const Color(0xFF1E1E2C),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Row(
                  children: [
                    Icon(Icons.circle, color: Colors.red, size: 12),
                    SizedBox(width: 6),
                    Text("LIVE SYNC", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Text("2 Users Connected", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),

          // Chat Section
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

          // Message Input Bar
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
    if (_mediaType == 'video' && _isInitialized && _videoController != null) {
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
    } else if (_mediaType == 'document' && _isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 70, color: Colors.pinkAccent),
            const SizedBox(height: 10),
            Text(
              _selectedFileName,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text("Document Live Loaded for both users", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.file_upload_outlined, size: 50, color: Colors.pinkAccent),
            const SizedBox(height: 10),
            const Text("No Content Loaded", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _showMediaPicker,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              child: const Text("Select Media or Document"),
            )
          ],
        ),
      );
    }
  }
}
