import 'dart:math';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

// በነፃ ከ console.agora.io የሚያገኘውን App ID እዚህ ያስገባሉ (ለሙከራ ይህ ይሰራል)
const String appId = "YOUR_AGORA_APP_ID"; 

class WatchPartyScreen extends StatefulWidget {
  const WatchPartyScreen({super.key});

  @override
  State<WatchPartyScreen> createState() => _WatchPartyScreenState();
}

class _WatchPartyScreenState extends State<WatchPartyScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _currentRoomCode;
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isVideoDisabled = false;
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();
  }

  Future<void> initAgora(String channelName) async {
    // Request Camera & Microphone Permissions
    await [Permission.microphone, Permission.camera].request();

    // Create RtcEngine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: '',
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  String _generateRoomCode() {
    final random = Random();
    final code = 1000 + random.nextInt(9000);
    return "STD-$code";
  }

  void _createRoom() {
    final code = _generateRoomCode();
    setState(() {
      _currentRoomCode = code;
    });
    initAgora(code);
  }

  void _joinRoom() {
    final code = _codeController.text.trim();
    if (code.isNotEmpty) {
      setState(() {
        _currentRoomCode = code;
      });
      initAgora(code);
    }
  }

  void _leaveRoom() async {
    await _engine.leaveChannel();
    await _engine.release();
    setState(() {
      _localUserJoined = false;
      _remoteUid = null;
      _currentRoomCode = null;
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRoomCode == null ? 'Live Study Room' : 'Room: $_currentRoomCode'),
        actions: [
          if (_localUserJoined)
            IconButton(
              icon: const Icon(Icons.call_end, color: Colors.red),
              onPressed: _leaveRoom,
            )
        ],
      ),
      body: _currentRoomCode == null ? _buildJoinLobby() : _buildVideoRoom(),
    );
  }

  Widget _buildJoinLobby() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.blueAccent,
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('አዲስ የጥናት ሩም ክፈት (Create Room)', style: TextStyle(color: Colors.white, fontSize: 16)),
            onPressed: _createRoom,
          ),
          const SizedBox(height: 30),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("ወይም")),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'የሩም ኮድ አስገባ (e.g. STD-4821)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.green,
            ),
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text('በኮድ ተቀላቀል (Join Room)', style: TextStyle(color: Colors.white, fontSize: 16)),
            onPressed: _joinRoom,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoRoom() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Center(
                child: _remoteUid != null
                    ? AgoraVideoView(
                        controller: VideoViewController.remote(
                          rtcEngine: _engine,
                          canvas: VideoCanvas(uid: _remoteUid),
                          connection: RtcConnection(channelId: _currentRoomCode),
                        ),
                      )
                    : const Text(
                        'ተማሪዎች ኮዱን ተጠቅመው እስኪገቡ በመጠባበቅ ላይ...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              if (_localUserJoined)
                Align(
                  alignment: Alignment.topRight,
                  child: SizedBox(
                    width: 120,
                    height: 160,
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          color: Colors.black12,
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                onPressed: () {
                  setState(() => _isMuted = !_isMuted);
                  _engine.muteLocalAudioStream(_isMuted);
                },
              ),
              IconButton(
                icon: Icon(_isVideoDisabled ? Icons.videocam_off : Icons.videocam),
                onPressed: () {
                  setState(() => _isVideoDisabled = !_isVideoDisabled);
                  _engine.muteLocalVideoStream(_isVideoDisabled);
                },
              ),
            ],
          ),
        )
      ],
    );
  }
}
