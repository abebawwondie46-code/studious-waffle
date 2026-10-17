import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuanyngne/Chat/biometric_service.dart';

class SecretChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const SecretChatScreen({
    Key? key,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);

  @override
  State<SecretChatScreen> createState() => _SecretChatScreenState();
}

class _SecretChatScreenState extends State<SecretChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isFingerprintPassed = false;
  bool _isUnlocked = false;
  bool _isSelfDestruct = false; 
  static bool _hasEnteredChatOnce = false; 

  int _tapCount = 0; 
  int _requiredTaps = 3; 
  Timer? _tapResetTimer; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCustomTaps();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateUser();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tapResetTimer?.cancel();
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

  String _toValidUuid(String? rawId, String fallback) {
    if (rawId == null || rawId.isEmpty || rawId == 'unknown_id') {
      return fallback;
    }
    final uuidRegExp = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (uuidRegExp.hasMatch(rawId)) {
      return rawId;
    }
    return fallback;
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
            'መጀመሪያ ሚስጥራዊውን ቻት መክፈትና ማጠናቀቅ አለብዎት! 🚫',
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

    final prefs = await SharedPreferences.getInstance();
    String? rawSenderId = _supabase.auth.currentUser?.id ?? 
                          _supabase.auth.currentSession?.user.id ?? 
                          prefs.getString('test_user_id');

    final validSenderId = _toValidUuid(rawSenderId, '11111111-1111-1111-1111-111111111111');
    final validReceiverId = _toValidUuid(widget.receiverId, '22222222-2222-2222-2222-222222222222');

    _messageController.clear();

    try {
      await _supabase.from('messages').insert({
        'sender_id': validSenderId,
        'receiver_id': validReceiverId,
        'content': text,
        'is_self_destruct': _isSelfDestruct,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
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

    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, prefsSnapshot) {
        final prefs = prefsSnapshot.data;
        final rawSenderId = _supabase.auth.currentUser?.id ?? 
                            _supabase.auth.currentSession?.user.id ?? 
                            prefs?.getString('test_user_id');

        final currentUserId = _toValidUuid(rawSenderId, '11111111-1111-1111-1111-111111111111');
        final currentReceiverId = _toValidUuid(widget.receiverId, '22222222-2222-2222-2222-222222222222');

        return Scaffold(
          backgroundColor: const Color(0xFF18191A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF242526),
            title: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.receiverName, style: const TextStyle(fontSize: 16, color: Colors.white)),
                    const Text('በአሻራ እና በድብቅ ምት የተጠበቀ', style: TextStyle(fontSize: 11, color: Colors.greenAccent)),
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
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _supabase
                      .from('messages')
                      .stream(primaryKey: ['id'])
                      .order('created_at', ascending: true),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'ምንም መልእክት የለም። ውይይት ይጀምሩ!',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      );
                    }

                    // 🌟 መልእክቶች እንዳይጠፉ እና በሁለቱ ተጠቃሚዎች መካከል ያለጥርጥር እንዲታዩ የተስተካከለ ማጣሪያ
                    final messages = snapshot.data!.where((m) {
                      final sender = m['sender_id']?.toString() ?? '';
                      final receiver = m['receiver_id']?.toString() ?? '';
                      
                      return (sender == currentUserId && receiver == currentReceiverId) ||
                             (sender == currentReceiverId && receiver == currentUserId);
                    }).toList();

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'እስካሁን የተላከ መልእክት የለም።',
                          style: TextStyle(color: Colors.white54, fontSize: 14),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['sender_id']?.toString() == currentUserId;
                        final bool isSelfDestruct = msg['is_self_destruct'] ?? false;
                        final String timeStr = _formatTime(msg['created_at']?.toString());

                        return _buildMessageBubble(
                          msg['content'] ?? '', 
                          isMe, 
                          isSelfDestruct,
                          timeStr,
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: const Color(0xFF242526),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.timer,
                        color: _isSelfDestruct ? Colors.orangeAccent : Colors.white54,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSelfDestruct = !_isSelfDestruct;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isSelfDestruct
                                ? 'ራሱን የሚያጠፋ መልእክት በርቷል 💣'
                                : 'መደበኛ መልእክት በርቷል'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _isSelfDestruct ? 'የሚጠፋ መልእክት ጻፍ...' : 'መልእክት ጻፍ...',
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
      },
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, bool isSelfDestruct, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isMe
              ? (isSelfDestruct ? Colors.orange[800] : Colors.blueAccent)
              : const Color(0xFF3A3B3C),
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelfDestruct)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.timer, size: 14, color: Colors.white70),
                  ),
                Flexible(
                  child: Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ],
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
