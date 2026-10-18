import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuanyngne/Chat/biometric_service.dart';

class SecretChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverAvatarUrl;

  const SecretChatScreen({
    Key? key,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatarUrl,
  }) : super(key: key);

  @override
  State<SecretChatScreen> createState() => _SecretChatScreenState();
}

class _SecretChatScreenState extends State<SecretChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isFingerprintPassed = false;
  bool _isUnlocked = false;
  static bool _hasEnteredChatOnce = false; 

  int _tapCount = 0; 
  int _requiredTaps = 3; 
  Timer? _tapResetTimer; 
  Timer? _pollingTimer;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  
  String _currentReceiverName = '';
  String? _fetchedAvatarUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentReceiverName = widget.receiverName;
    _fetchedAvatarUrl = widget.receiverAvatarUrl;
    
    _loadCustomTaps();
    _fetchReceiverProfileAndMessages(); 

    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_isUnlocked) {
        _fetchMessages();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateUser();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapResetTimer?.cancel();
    _pollingTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (!_isUnlocked) {
        setState(() {
          _isFingerprintPassed = false;
          _tapCount = 0;
        });
      }
    }
  }

  Future<void> _loadCustomTaps() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _requiredTaps = prefs.getInt('secret_knock_taps') ?? 3;
    });
  }

  // 🌟 የፕሮፋይል ፎቶውን እና ስሙን ከ Supabase profiles እና SharedPreferences በትክክል የሚያመጣው ክፍል
  Future<void> _fetchReceiverProfileAndMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. መጀመሪያ ከ SharedPreferences መፈለግ
      final String? savedAvatar = prefs.getString('receiver_avatar_${widget.receiverId}') ?? 
                                  prefs.getString('current_user_avatar');
      if (savedAvatar != null && savedAvatar.isNotEmpty) {
        setState(() {
          _fetchedAvatarUrl = savedAvatar;
        });
      }

      // 2. ከ Supabase 'profiles' ቴብል ያለ ማጣሪያ (Filter) የመጀመሪያውን ሮው መውሰድ
      final profileData = await _supabase
          .from('profiles')
          .select('full_name, avatar_url, profile_pic, photo_url')
          .maybeSingle();

      if (profileData != null && mounted) {
        final fullName = profileData['full_name'];
        final url = profileData['avatar_url'] ?? profileData['profile_pic'] ?? profileData['photo_url'];
        
        setState(() {
          if (fullName != null && fullName.toString().isNotEmpty) {
            _currentReceiverName = fullName.toString();
          }
          if (url != null && url.toString().isNotEmpty) {
            _fetchedAvatarUrl = url.toString();
            prefs.setString('receiver_avatar_${widget.receiverId}', url.toString());
          }
        });
      }
    } catch (e) {
      debugPrint('Profile fetch error: $e');
    }

    await _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await _supabase
          .from('messages')
          .select()
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('FETCH ERROR: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(createdAt).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }

  Future<void> _verifyAndOpenSettings() async {
    if (!_hasEnteredChatOnce) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'መጀመሪያ ቻቱን መክፈትና ማጠናቀቅ አለብዎት! 🚫',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    bool authenticated = await BiometricService.authenticateWithFingerprint();
    if (authenticated && mounted) {
      _changeKnockSettings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('የባለቤቱ ማረጋገጫ ስላልተሳካ ቅንብሮቹን መክፈት አልተቻለም! 🚫')),
      );
    }
  }

  Future<void> _changeKnockSettings() async {
    int tempTaps = _requiredTaps;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF242526),
          title: const Text('የድብቅ ምት ብዛት ማቀናበሪያ', style: TextStyle(color: Colors.white)),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ቻቱን ለመክፈት ስክሪኑን የሚነኩበትን የምት ሚስጥር (እስከ 12) ይምረጡ:',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.blueAccent, size: 32),
                        onPressed: () {
                          if (tempTaps > 2) {
                            setDialogState(() => tempTaps--);
                          }
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'ምስጢራዊ ምት',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.blueAccent, size: 32),
                        onPressed: () {
                          if (tempTaps < 12) {
                            setDialogState(() => tempTaps++);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ይቅር', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('secret_knock_taps', tempTaps);
                setState(() {
                  _requiredTaps = tempTaps;
                  _tapCount = 0;
                });
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'የድብቅ ምት ወደ $tempTaps ጊዜ ተቀይሯል! 🔒',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Colors.white,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('አስቀምጥ', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _authenticateUser() async {
    try {
      bool authenticated = await BiometricService.authenticateWithFingerprint();
      if (mounted) {
        setState(() {
          _isFingerprintPassed = authenticated;
          _tapCount = 0;
        });
      }
    } catch (e) {
      print("Authentication error: $e");
    }
  }

  void _handleScreenTap() {
    if (_isUnlocked) return;

    if (!_isFingerprintPassed) {
      _authenticateUser();
      return;
    }

    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && !_isUnlocked) {
        setState(() {
          _tapCount = 0;
        });
      }
    });

    setState(() {
      _tapCount++;
      if (_tapCount >= _requiredTaps) {
        _tapResetTimer?.cancel();
        _isUnlocked = true; 
        _hasEnteredChatOnce = true; 
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      await _supabase.from('messages').insert({
        'sender_id': '11111111-1111-1111-1111-111111111111',
        'receiver_id': '22222222-2222-2222-2222-222222222222',
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await _fetchMessages();
      debugPrint('መልእክት በተሳካ ሁኔታ ተልኳል!');
    } catch (e) {
      debugPrint('SUPABASE INSERT ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('መልእክት መላክ አልተቻለም፦ $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              onPressed: _verifyAndOpenSettings,
              tooltip: 'የድብቅ ምት ማስተካከያ',
            ),
          ],
        ),
        body: GestureDetector(
          onTap: _handleScreenTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isFingerprintPassed
                          ? Colors.cyanAccent.withOpacity(0.15)
                          : Colors.blueAccent.withOpacity(0.1),
                      border: Border.all(
                        color: _isFingerprintPassed ? Colors.cyanAccent : Colors.blueAccent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _isFingerprintPassed ? Icons.vibration : Icons.fingerprint,
                      size: 80,
                      color: _isFingerprintPassed ? Colors.cyanAccent : Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    !_isFingerprintPassed
                        ? 'ይህ የሜሴጅ ገጽ በአሻራ የተቆለፈ ነው'
                        : 'ሚስጥራዊውን ምት በድብቅ ያንኳኩት...',
                    style: TextStyle(
                      color: _isFingerprintPassed ? Colors.cyanAccent : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 🌟 አቫታር ፕሮቫይደር (NetworkImage ወይም FileImage)
    ImageProvider? imageProvider;
    if (_fetchedAvatarUrl != null && _fetchedAvatarUrl!.isNotEmpty) {
      if (_fetchedAvatarUrl!.startsWith('http://') || _fetchedAvatarUrl!.startsWith('https://')) {
        imageProvider = NetworkImage(_fetchedAvatarUrl!);
      } else if (File(_fetchedAvatarUrl!).existsSync()) {
        imageProvider = FileImage(File(_fetchedAvatarUrl!));
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF18191A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF242526),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blueAccent,
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? Text(
                      _currentReceiverName.isNotEmpty ? _currentReceiverName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_currentReceiverName, style: const TextStyle(fontSize: 16, color: Colors.white)),
                const Text('መደበኛ ቻት (በቋሚነት የሚታይ)', style: TextStyle(fontSize: 11, color: Colors.greenAccent)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock, color: Colors.redAccent),
            onPressed: () {
              setState(() {
                _isFingerprintPassed = false;
                _isUnlocked = false;
                _tapCount = 0;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'ምንም መልእክት የለም። ውይይት ይጀምሩ!',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final content = msg['content']?.toString() ?? '';
                          final senderId = msg['sender_id']?.toString() ?? '';
                          final timeStr = _formatTime(msg['created_at']?.toString());
                          
                          final isMe = (senderId == '11111111-1111-1111-1111-111111111111');

                          return _buildMessageBubble(content, isMe, timeStr);
                        },
                      ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: const Color(0xFF242526),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'መልእክት ጻፍ...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF3A3B3C),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : const Color(0xFF3A3B3C),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 2),
            bottomRight: Radius.circular(isMe ? 2 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                time,
                style: const TextStyle(color: Colors.white60, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
