import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecorderDemo extends StatefulWidget {
  const VoiceRecorderDemo({Key? key}) : super(key: key);

  @override
  State<VoiceRecorderDemo> createState() => _VoiceRecorderDemoState();
}

class _VoiceRecorderDemoState extends State<VoiceRecorderDemo> {
  // Audio Recorder & Player Objects
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;

  // States
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedFilePath;
  int _recordDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();

    // ድምፁ ተጫውቶ ሲያበቃ አውቶማቲክ እንዲቆም ማዳመጫ
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // 1. ድምፅ መቅረፅ መጀመር እና ማቆም (Start/Stop Recording)
  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        // መቅረፅ ማቆም
        final path = await _audioRecorder.stop();
        _timer?.cancel();

        setState(() {
          _isRecording = false;
          _recordedFilePath = path;
        });
        debugPrint("Recorded Audio Saved At: $path");
      } else {
        // የማይክራፎን ፈቃድ ማረጋገጥ
        if (await _audioRecorder.hasPermission()) {
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

          // መቅረፅ መጀመር
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: filePath,
          );

          setState(() {
            _isRecording = true;
            _recordDuration = 0;
            _recordedFilePath = null;
          });

          // የታይመር ቆጣሪ መጀመር
          _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() {
              _recordDuration++;
            });
          });
        }
      }
    } catch (e) {
      debugPrint("Error recording audio: $e");
    }
  }

  // 2. የተቀረፀውን ድምፅ ማጫወት እና ማቆም (Play/Pause Audio)
  Future<void> _togglePlayAudio() async {
    if (_recordedFilePath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioPlayer.setFilePath(_recordedFilePath!);
        await _audioPlayer.play();
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F17),
      appBar: AppBar(
        title: const Text("Voice Recorder Test"),
        backgroundColor: const Color(0xFF181824),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // የሚቆጥረው ሰከንድ
            if (_isRecording) ...[
              Text(
                "Recording: ${_recordDuration}s",
                style: const TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
            ],

            // የመቅረጫ ነጥብ/ማይክራፎን በተን
            GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.redAccent : Colors.purpleAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.redAccent : Colors.purpleAccent).withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isRecording ? "Tap to Stop" : "Tap Mic to Record",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 40),

            // የተቀረፀው ድምፅ ሲኖር የሚታይ ማጫወቻCard
            if (_recordedFilePath != null && !_isRecording) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFF181824),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                        color: Colors.purpleAccent,
                        size: 36,
                      ),
                      onPressed: _togglePlayAudio,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Voice Message",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Duration: ${_recordDuration}s",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
