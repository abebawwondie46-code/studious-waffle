import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({Key? key}) : super(key: key);

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;

  bool _isRecordingAudio = false;
  int _audioRecordDuration = 0;
  Timer? _audioTimer;
  String? _currentlyPlayingAudioId;

  final List<Map<String, String>> _messages = [
    {
      'id': '1',
      'sender': 'System',
      'text': 'Voice Recorder Demo Ready',
      'time': '12:00',
      'isAudio': 'false',
      'audioPath': '',
    }
  ];

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();

    // ድምፁ ተጫውቶ ሲያበቃ አውቶማቲክ እንዲቆም ማድረግ
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            _currentlyPlayingAudioId = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _audioTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // 1. እውነተኛ ድምፅ መቅረፅ መጀመር እና ማቆም
  Future<void> _toggleAudioRecording() async {
    try {
      if (_isRecordingAudio) {
        // መቅረፅ ማቆም እና የፋይሉን Path መቀበል
        final path = await _audioRecorder.stop();
        _audioTimer?.cancel();

        if (path != null) {
          _sendVoiceMessage("${_audioRecordDuration}s", path);
        }

        setState(() {
          _isRecordingAudio = false;
          _audioRecordDuration = 0;
        });
      } else {
        // የማይክራፎን ፈቃድ ማረጋገጥ
        if (await _audioRecorder.hasPermission()) {
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: filePath,
          );

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
    } catch (e) {
      debugPrint("Error recording audio: $e");
    }
  }

  // 2. የተቃረፀውን ድምፅ ወደ ቻቱ መላክ
  void _sendVoiceMessage(String duration, String filePath) {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'sender': 'You',
        'text': 'Voice Note ($duration)',
        'time': timeStr,
        'isAudio': 'true',
        'audioPath': filePath,
      });
    });
  }

  // 3. እውነተኛውን የድምፅ ፋይል ማጫወት እና ማቆም
  Future<void> _togglePlayVoiceNote(String id, String audioPath) async {
    try {
      if (_currentlyPlayingAudioId == id) {
        await _audioPlayer.stop();
        setState(() {
          _currentlyPlayingAudioId = null;
        });
        return;
      }

      await _audioPlayer.stop();

      if (audioPath.isNotEmpty) {
        await _audioPlayer.setFilePath(audioPath);
        setState(() {
          _currentlyPlayingAudioId = id;
        });
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint("Error playing audio: $e");
      if (mounted) {
        setState(() {
          _currentlyPlayingAudioId = null;
        });
      }
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
                            onTap: () => _togglePlayVoiceNote(msg['id']!, msg['audioPath'] ?? ''),
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
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
