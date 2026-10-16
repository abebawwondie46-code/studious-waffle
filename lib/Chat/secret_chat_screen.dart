import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  bool _isUnlocked = false;
  bool _isSelfDestruct = false; // ራሱን የሚያጠፋ መልእክት ማብሪያ

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ስክሪኑ ሲከፈት በአውቶማቲክ የአሻራ ማረጋገጫውን መጠየቅ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateUser();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      setState(() {
        _isUnlocked = false;
      });
    }
  }

  /// የአሻራ ወይም የፒን ማረጋገጫ መጠየቅ
  Future<void> _authenticateUser() async {
    bool authenticated = await BiometricService.authenticateWithFingerprint();
    if (mounted) {
      setState(() {
        _isUnlocked = authenticated;
      });
    }
  }

  /// መልእክት መላክ
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    await _supabase.from('messages').insert({
      'sender_id': currentUser.id,
      'receiver_id': widget.receiverId,
      'content': text,
      'is_self_destruct': _isSelfDestruct,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    // አሻራ ካልተረጋገጠ የተቆለፈ ስክሪን ማሳየት
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
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.fingerprint, size: 90, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                'ይህ የሜሴጅ ገጽ በአሻራ የተቆለፈ ነው',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _authenticateUser,
                icon: const Icon(Icons.lock_open, color: Colors.white),
                label: const Text('በአሻራ ክፈት', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final currentUserId = _supabase.auth.currentUser?.id ?? '';

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
                const Text('በአሻራ የተጠበቀ', style: TextStyle(fontSize: 11, color: Colors.greenAccent)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock, color: Colors.redAccent),
            onPressed: () {
              setState(() {
                _isUnlocked = false;
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
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                }

                final messages = snapshot.data!.where((m) =>
                    (m['sender_id'] == currentUserId && m['receiver_id'] == widget.receiverId) ||
                    (m['sender_id'] == widget.receiverId && m['receiver_id'] == currentUserId)).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == currentUserId;
                    final bool isSelfDestruct = msg['is_self_destruct'] ?? false;

                    return _buildMessageBubble(msg['content'], isMe, isSelfDestruct);
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
  }

  Widget _buildMessageBubble(String text, bool isMe, bool isSelfDestruct) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        child: Row(
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
      ),
    );
  }
}
