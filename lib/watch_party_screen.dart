import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({Key? key}) : super(key: key);

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  // Voice Recording & Playback States
  bool _isRecordingAudio = false;
  int _audioRecordDuration = 0;
  Timer? _audioTimer;
  String? _currentlyPlayingAudioId;

  // Messages List
  final List<Map<String, String>> _messages = [
    {
      'id': '1',
      'sender': 'System',
      'text': 'Voice Recorder Demo Ready',
      'time': '12:00',
      'isAudio': 'false',
    }
  ];

  @override
  void dispose() {
    _audioTimer?.cancel();
    super.dispose();
  }

  // 1. ድምፅ መቅረፅ መጀመር እና ማቆም (Toggle Record)
  void _toggleAudioRecording() {
    if (_isRecordingAudio) {
      // መቅረፅ ማቆም እና መልእክቱን መላክ
      _audioTimer?.cancel();
      final durationStr = "${_audioRecordDuration}s";
      _sendVoiceMessage(durationStr);

      setState(() {
        _isRecordingAudio = false;
        _audioRecordDuration = 0;
      });
    } else {
      // መቅረፅ መጀመር
      setState(() {
        _isRecordingAudio = true;
        _audioRecordDuration = 0;
      });

      _audioTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _audioRecordDuration++;
        });
      });
    }
  }

  // 2. የድምፅ መልእክት ወደ ቻት መላክ
  void _sendVoiceMessage(String duration) {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final msgMap = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'sender': 'You',
      'text': 'Voice Note ($duration)',
      'time': timeStr,
      'isAudio': 'true',
    };

    setState(() {
      _messages.add(msgMap);
    });
  }

  // 3. የድምፅ መልእክቱን ማጫወት / ማቆም (Play/Pause Audio)
  void _togglePlayVoiceNote(String id) {
    setState(() {
      if (_currentlyPlayingAudioId == id) {
        _currentlyPlayingAudioId = null;
      } else {
        _currentlyPlayingAudioId = id;
      }
    });

    // ድምፁ ለ4 ሰከንድ ተጫውቶ አውቶማቲክ እንዲቆም ማድረግ
    if (_currentlyPlayingAudioId != null) {
      Timer(const Duration(seconds: 4), () {
        if (mounted && _currentlyPlayingAudioId == id) {
          setState(() {
            _currentlyPlayingAudioId = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F17),
      appBar: AppBar(
        title: const Text("Voice Recorder Test", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF181824),
      ),
      body: Column(
        children: [
          // የቻት እና የድምፅ መልእክቶች ዝርዝር
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAudio = msg['isAudio'] == 'true';

                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD633E6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isAudio)
                          GestureDetector(
                            onTap: () => _togglePlayVoiceNote(msg['id']!),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _currentlyPlayingAudioId == msg['id']
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.graphic_eq, color: Colors.white70, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  msg['text']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Text(
                            msg['text']!,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          msg['time']!,
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ድምፅ መቅረጫ ታችኛው ክፍል (Bottom Recorder Control)
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF181824),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (_isRecordingAudio)
                  Text(
                    "Recording: ${_audioRecordDuration}s",
                    style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
                  )
                else
                  const Text(
                    "Press Mic to Record Voice",
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),

                // የቀይ/ሐምራዊ ማይክራፎን በተን
                GestureDetector(
                  onTap: _toggleAudioRecording,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: _isRecordingAudio ? Colors.redAccent : Colors.purpleAccent,
                    child: Icon(
                      _isRecordingAudio ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 30,
                    ),
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
