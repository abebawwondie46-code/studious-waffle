import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MaterialApp(
    home: NativeVoiceRecorderApp(),
    debugShowCheckedModeBanner: false,
  ));
}

class NativeVoiceRecorderApp extends StatefulWidget {
  const NativeVoiceRecorderApp({super.key});

  @override
  State<NativeVoiceRecorderApp> createState() => _NativeVoiceRecorderAppState();
}

class _NativeVoiceRecorderAppState extends State<NativeVoiceRecorderApp> {
  static const platform = MethodChannel('com.example.voice/native');

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _filePath;

  // 1. የማይክራፎን በተኑ ሲነካ
  Future<void> _toggleRecord() async {
    try {
      if (_isRecording) {
        // መቅረፅ ማቆም
        final String? path = await platform.invokeMethod('stopRecording');
        setState(() {
          _isRecording = false;
          _filePath = path;
        });
      } else {
        // አስቀድሞ ፈቃድ አለ ወይ ብሎ ማረጋገጥ/መጠየቅ
        final bool hasPermission = await platform.invokeMethod('checkAndRequestPermission');

        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('እባክዎን የማይክራፎን ፈቃዱን "Allow" በለውና እንደገና ይጫኑት')),
            );
          }
          return;
        }

        // ፈቃድ ከተሰጠ መቅረፅ መጀመር
        final String? path = await platform.invokeMethod('startRecording');
        setState(() {
          _isRecording = true;
          _filePath = path;
        });
      }
    } on PlatformException catch (e) {
      debugPrint("Record Error: ${e.message}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }

  // 2. የተቀረፀውን ማጫወት
  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await platform.invokeMethod('stopAudio');
        setState(() {
          _isPlaying = false;
        });
      } else {
        await platform.invokeMethod('playAudio');
        setState(() {
          _isPlaying = true;
        });
      }
    } on PlatformException catch (e) {
      debugPrint("Play Error: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101018),
      appBar: AppBar(
        title: const Text("Native Voice Recorder Test"),
        backgroundColor: Colors.black12,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isRecording)
              const Text(
                "ድምፅ በ Native እየቀረፀ ነው...",
                style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold),
              )
            else
              const Text(
                "ለመቅረፅ የማይክራፎን ቁልፉን ይጫኑ",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),

            const SizedBox(height: 40),

            // Record Button
            GestureDetector(
              onTap: _toggleRecord,
              child: CircleAvatar(
                radius: 45,
                backgroundColor: _isRecording ? Colors.red : Colors.deepPurple,
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Play Button
            if (_filePath != null && !_isRecording)
              ElevatedButton.icon(
                onPressed: _togglePlay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                label: Text(
                  _isPlaying ? "አቁም" : "የተቀረፀውን አጫውት",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
