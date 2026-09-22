import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class WatchPartyScreen extends StatefulWidget {
  final String videoId;
  final String videoUrl;

  const WatchPartyScreen({
    Key? key,
    this.videoId = '5', // Default video ID
    this.videoUrl = 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
  }) : super(key: key);

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController = TextEditingController();

  // Video Controller State
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isFullScreen = false;

  // Recording & Chat State
  bool _isRecordingAudio = false;
  int _audioRecordDuration = 0;
  Timer? _recordingTimer;
  bool _ghostMode = false;
  String? _currentlyPlayingAudioId;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  // የቪዲዮ ማጫወቻ ማስነሻ
  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    )..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _videoController!.play();
      });
  }

  // ኮሜንት/መልእክት ወደ Supabase መላክ
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {});

    final now = DateTime.now();
    final timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    try {
      await _supabase.from('comments').insert({
        'video_id': widget.videoId,
        'username': 'You',
        'text': text,
        'created_at': now.toIso8601String(),
        'is_ghost': _ghostMode,
        'is_audio': false,
      });
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  // የድምፅ መቅረጫ ታይመር
  void _toggleAudioRecording() {
    setState(() {
      _isRecordingAudio = !_isRecordingAudio;
      if (_isRecordingAudio) {
        _audioRecordDuration = 0;
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _audioRecordDuration++;
          });
        });
      } else {
        _recordingTimer?.cancel();
        if (_audioRecordDuration > 0) {
          _sendVoiceNote();
        }
      }
    });
  }

  // የድምፅ መልእክት መላክ
  Future<void> _sendVoiceNote() async {
    final now = DateTime.now();

    try {
      await _supabase.from('comments').insert({
        'video_id': widget.videoId,
        'username': 'You',
        'text': "Voice Note (${_audioRecordDuration}s)",
        'created_at': now.toIso8601String(),
        'is_ghost': _ghostMode,
        'is_audio': true,
      });
    } catch (e) {
      debugPrint("Error sending voice note: $e");
    }
  }

  void _togglePlayVoiceNote(String id) {
    setState(() {
      _currentlyPlayingAudioId = (_currentlyPlayingAudioId == id) ? null : id;
    });
  }

  Future<void> _deleteMessage(String id) async {
    try {
      await _supabase.from('comments').delete().eq('id', id);
    } catch (e) {
      debugPrint("Error deleting message: $e");
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _recordingTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181824),
        title: Text("Watch Party - Video ${widget.videoId}",
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(_ghostMode ? Icons.ghost_filled : Icons.ghost_outlined,
                color: _ghostMode ? Colors.purpleAccent : Colors.white70),
            onPressed: () {
              setState(() {
                _ghostMode = !_ghostMode;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Video Player Section
          Expanded(
            flex: _isFullScreen ? 10 : 4,
            child: Container(
              color: Colors.black,
              child: _buildVideoPlayerContent(),
            ),
          ),

          // 2. Realtime Chat Section (በኢንተርኔት ቀጥታ መረጃ የሚስብ)
          if (!_isFullScreen) ...[
            Expanded(
              flex: 5,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _supabase
                    .from('comments')
                    .stream(primaryKey: ['id'])
                    .eq('video_id', widget.videoId)
                    .order('created_at', ascending: true),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.redAccent)),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.purpleAccent),
                    );
                  }

                  final comments = snapshot.data!;

                  if (comments.isEmpty) {
                    return const Center(
                      child: Text("No comments yet. Start typing...",
                          style: TextStyle(color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final msg = comments[index];
                      final isMe = msg['username'] == 'You';
                      final isGhost = msg['is_ghost'] == true;
                      final isAudio = msg['is_audio'] == true;
                      final msgId = msg['id'].toString();
                      final isPlayingThisAudio = _currentlyPlayingAudioId == msgId;

                      return GestureDetector(
                        onLongPress: () => _deleteMessage(msgId),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.purpleAccent,
                                  child: Text(
                                    (msg['username'] ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              if (!isMe) const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? (isGhost ? Colors.purple.shade900 : Colors.purpleAccent)
                                            : const Color(0xFF222233),
                                        border: isGhost ? Border.all(color: Colors.purpleAccent, width: 1) : null,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(16),
                                          topRight: const Radius.circular(16),
                                          bottomLeft: Radius.circular(isMe ? 16 : 2),
                                          bottomRight: Radius.circular(isMe ? 2 : 16),
                                        ),
                                      ),
                                      child: isAudio
                                          ? InkWell(
                                              onTap: () => _togglePlayVoiceNote(msgId),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isPlayingThisAudio ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                                    color: Colors.white,
                                                    size: 26,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    Icons.graphic_eq,
                                                    size: 20,
                                                    color: isPlayingThisAudio ? Colors.greenAccent : Colors.white70,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    msg['text'] ?? '',
                                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isGhost)
                                                  const Padding(
                                                    padding: EdgeInsets.only(right: 6),
                                                    child: Icon(Icons.timer, size: 14, color: Colors.white70),
                                                  ),
                                                Flexible(
                                                  child: Text(
                                                    msg['text'] ?? '',
                                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          msg['username'] ?? 'User',
                                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.done_all, size: 12, color: Colors.purpleAccent),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 3. Message Input Bar Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF181824),
                boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F17),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isRecordingAudio
                              ? Colors.redAccent
                              : (_ghostMode ? Colors.purpleAccent : Colors.transparent),
                        ),
                      ),
                      child: _isRecordingAudio
                          ? Row(
                              children: [
                                const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  "Recording... ${_audioRecordDuration}s",
                                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : TextField(
                              controller: _messageController,
                              style: const TextStyle(color: Colors.white),
                              onChanged: (text) {
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                hintText: _ghostMode ? "Ghost message (disappears)..." : "Type comment...",
                                hintStyle: TextStyle(
                                  color: _ghostMode ? Colors.purpleAccent.withOpacity(0.7) : Colors.grey,
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: _isRecordingAudio ? Colors.redAccent : Colors.purpleAccent,
                    child: IconButton(
                      icon: Icon(
                        _messageController.text.trim().isNotEmpty
                            ? Icons.send_rounded
                            : (_isRecordingAudio ? Icons.stop_rounded : Icons.mic_rounded),
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () {
                        if (_messageController.text.trim().isNotEmpty) {
                          _sendMessage();
                        } else {
                          _toggleAudioRecording();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // የቪዲዮ ማጫወቻ Widget
  Widget _buildVideoPlayerContent() {
    if (_isInitialized && _videoController != null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
          if (_showControls)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: Colors.black54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                          child: Text("Video ID: ${widget.videoId}",
                              style: const TextStyle(color: Colors.purpleAccent, fontSize: 11)),
                        ),
                        IconButton(
                          icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen, color: Colors.white),
                          onPressed: _toggleFullScreen,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.replay_10, color: Colors.white),
                        onPressed: () {
                          final current = _videoController!.value.position;
                          _videoController!.seekTo(current - const Duration(seconds: 10));
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        iconSize: 56,
                        icon: Icon(
                          _videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.purpleAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        iconSize: 36,
                        icon: const Icon(Icons.forward_10, color: Colors.white),
                        onPressed: () {
                          final current = _videoController!.value.position;
                          _videoController!.seekTo(current + const Duration(seconds: 10));
                        },
                      ),
                    ],
                  ),
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.purpleAccent,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(color: Colors.purpleAccent),
      );
    }
  }
}
