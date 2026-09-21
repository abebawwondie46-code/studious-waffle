import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({super.key});

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordedPath;

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // 1. ድምፅ መቅረፅ መጀመር እና ማቆም (ፈቃዱን በራሱ ይፈልጋል)
  Future<void> _toggleRecord() async {
    try {
      if (_isRecording) {
        // መቅረፅ ማቆም
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _recordedPath = path;
        });
        debugPrint('Recorded file path: $path');
      } else {
        // የማይክራፎን ፈቃድ ማረጋገጥ
        if (await _audioRecorder.hasPermission()) {
          final dir = await getApplicationDocumentsDirectory();
          final filePath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: filePath,
          );

          setState(() {
            _isRecording = true;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('እባክዎን የማይክራፎን ፈቃድ ይስጡ')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Recording error: $e');
    }
  }

  // 2. የተቀረፀውን ድምፅ ማጫወት
  Future<void> _playAudio() async {
    if (_recordedPath != null && File(_recordedPath!).existsSync()) {
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioPlayer.play(DeviceFileSource(_recordedPath!));
        setState(() {
          _isPlaying = true;
        });

        _audioPlayer.onPlayerComplete.listen((event) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Recorder')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRecording)
              const Text(
                'ድምፅ እየቀረጸ ነው...',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            const SizedBox(height: 20),
            
            // የማይክራፎን ቁልፍ (Record Button)
            IconButton(
              iconSize: 64,
              icon: Icon(
                _isRecording ? Icons.stop_circle : Icons.mic,
                color: _isRecording ? Colors.red : Colors.blue,
              ),
              onPressed: _toggleRecord,
            ),
            
            const SizedBox(height: 30),

            // የተቀረጸውን ማጫወቻ (Play Button)
            if (_recordedPath != null)
              ElevatedButton.icon(
                onPressed: _playAudio,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                label: Text(_isPlaying ? 'አቁም' : 'ድምፁን አጫውት'),
              ),
          ],
        ),
      ),
    );
  }
}
