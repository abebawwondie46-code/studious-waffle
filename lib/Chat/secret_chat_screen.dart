import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kuanyngne/Chat/biometric_service.dart';
import 'package:kuanyngne/screens/profile_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isFingerprintPassed = false;
  bool _isUnlocked = false;
  static bool _hasEnteredChatOnce = false; 

  int _tapCount = 0; 
  int _requiredTaps = 3; 
  Timer? _tapResetTimer; 
  Timer? _pollingTimer;

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _searchResults = [];
  Set<String> _addedUserIds = {}; 
  bool _isLoading = true;
  bool _isSearching = false;
  
  String _currentReceiverName = '';
  String? _fetchedAvatarUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentReceiverName = widget.receiverName;
    _fetchedAvatarUrl = widget.receiverAvatarUrl;
    
    _loadCustomTaps();
    _loadAddedFriends(); 
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
    _searchController.dispose();
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

  Future<void> _loadAddedFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedFriends = prefs.getStringList('added_friends_list');
    if (savedFriends != null && mounted) {
      setState(() {
        _addedUserIds = savedFriends.toSet();
      });
    }
  }

  Future<void> _loadCustomTaps() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _requiredTaps = prefs.getInt('secret_knock_taps') ?? 3;
    });
  }

  Future<void> _fetchReceiverProfileAndMessages() async {
    try {
      final profileData = await _supabase
          .from('profiles')
          .select()
          .maybeSingle();

      if (profileData != null && mounted) {
        final fullName = profileData['full_name'];
        final url = profileData['avatar_url'] ?? profileData['profile_pic'] ?? profileData['photo_url'];
        
        setState(() {
          if (fullName != null && fullName.toString().isNotEmpty) {
            _currentReceiverName = fullName.toString();
          }
          if (url != null && url.toString().isNotEmpty) {
            _fetchedAvatarUrl = url.toString().trim();
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

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .ilike('full_name', '%$query%');

      if (mounted) {
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    }
  }

  Future<void> _toggleFriend(String targetUserId, String targetName, String? targetAvatar) async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      if (_addedUserIds.contains(targetUserId)) {
        _addedUserIds.remove(targetUserId);
      } else {
        _addedUserIds.add(targetUserId);
        _currentReceiverName = targetName; 
        _fetchedAvatarUrl = targetAvatar; 
      }
    });

    await prefs.setStringList('added_friends_list', _addedUserIds.toList());
  }

  // 🌟 መልእክት ከዳታቤዝ የሚያጠፋ ፈንክሽን
  Future<void> _deleteMessage(dynamic messageId) async {
    try {
      await _supabase
          .from('messages')
          .delete()
          .eq('id', messageId);

      await _fetchMessages();
    } catch (e) {
      debugPrint('DELETE ERROR: $e');
    }
  }

  // 🌟 በስክሪንሾቱ መሰረት በትክክል "Delete Message" የሚል ዳይሎግ የሚያሳይ ፈንክሽን
  void _confirmDeleteMessage(Map<String, dynamic> msg) {
    final messageId = msg['id'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2B2B2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Message',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this message?',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMessage(messageId);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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

  void _navigateToUserProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
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
          backgroundColor: const Color(0xFF1E1F22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '$tempTaps',
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('secret_knock_taps', tempTaps);
                setState(() {
                  _requiredTaps = tempTaps;
                  _tapCount = 0;
                });
                Navigator.pop(context);
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
      debugPrint("Authentication error: $e");
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
    } catch (e) {
      debugPrint('SUPABASE INSERT ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F1012),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white70),
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _isFingerprintPassed ? Colors.cyanAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2),
                          const Color(0xFF1E1F22),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: _isFingerprintPassed ? Colors.cyanAccent : Colors.blueAccent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isFingerprintPassed ? Colors.cyanAccent : Colors.blueAccent).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isFingerprintPassed ? Icons.vibration : Icons.fingerprint,
                      size: 70,
                      color: _isFingerprintPassed ? Colors.cyanAccent : Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    !_isFingerprintPassed
                        ? 'ይህ የሜሴጅ ገጽ በአሻራ የተቆለፈ ነው 🔒'
                        : 'ሚስጥራዊውን ምት በድብቅ ያንኳኩት...',
                    style: TextStyle(
                      color: _isFingerprintPassed ? Colors.cyanAccent : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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

    ImageProvider? imageProvider;
    if (_fetchedAvatarUrl != null && _fetchedAvatarUrl!.isNotEmpty) {
      if (_fetchedAvatarUrl!.startsWith('http://') || _fetchedAvatarUrl!.startsWith('https://')) {
        imageProvider = NetworkImage(_fetchedAvatarUrl!);
      } else if (File(_fetchedAvatarUrl!).existsSync()) {
        imageProvider = FileImage(File(_fetchedAvatarUrl!));
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121316),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1F22),
        elevation: 2,
        leadingWidth: 35,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'ተጠቃሚዎችን ፈልግ...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
                  border: InputBorder.none,
                ),
                onChanged: _searchUsers,
              )
            : InkWell(
                onTap: _navigateToUserProfile,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blueAccent.shade700,
                            backgroundImage: imageProvider,
                            child: imageProvider == null
                                ? Text(
                                    _currentReceiverName.isNotEmpty ? _currentReceiverName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF1E1F22), width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentReceiverName,
                              style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Row(
                              children: const [
                                Icon(Icons.lock_rounded, size: 10, color: Colors.greenAccent),
                                SizedBox(width: 3),
                                Text('ሚስጥራዊ ቻት', style: TextStyle(fontSize: 10, color: Colors.greenAccent)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white70),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
            tooltip: 'ተጠቃሚ መፈለጊያ',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
            color: const Color(0xFF1E1F22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              if (value == 'lock') {
                setState(() {
                  _isFingerprintPassed = false;
                  _isUnlocked = false;
                  _tapCount = 0;
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'lock',
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text('እንደገና ቆልፍ', style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121316), Color(0xFF181A20)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            if (_isSearching && _searchController.text.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1F22),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: _searchResults.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                          child: Text('ምንም ተጠቃሚ አልተገኘም 🔍', style: TextStyle(color: Colors.white54)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final user = _searchResults[index];
                          final name = user['full_name'] ?? 'ስም የሌለው';
                          final avatar = user['avatar_url'] ?? user['profile_pic'];
                          final userId = user['id']?.toString() ?? '$index';
                          final bool isAdded = _addedUserIds.contains(userId);

                          return ListTile(
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundImage: (avatar != null && avatar.toString().isNotEmpty)
                                  ? NetworkImage(avatar)
                                  : null,
                              child: (avatar == null || avatar.toString().isEmpty)
                                  ? Text(name[0].toUpperCase(), style: const TextStyle(fontSize: 14))
                                  : null,
                            ),
                            title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                            trailing: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAdded ? Colors.red.shade700 : Colors.blueAccent,
                                minimumSize: const Size(90, 32),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              icon: Icon(
                                isAdded ? Icons.delete_outline_rounded : Icons.person_add_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              label: Text(
                                isAdded ? 'Remove' : 'Add',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () => _toggleFriend(userId, name, avatar),
                            ),
                          );
                        },
                      ),
              ),

            // የቻት መልእክቶች ዝርዝር
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Colors.blueAccent),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'እስካሁን ምንም መልእክት የለም።\nውይይት ይጀምሩ! 💬',
                                style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final content = msg['content']?.toString() ?? '';
                            final senderId = msg['sender_id']?.toString() ?? '';
                            final timeStr = _formatTime(msg['created_at']?.toString());
                            
                            final isMe = (senderId == '11111111-1111-1111-1111-111111111111');

                            // 🌟 መልእክት ላይ ጫን (Long Press) ሲደረግ _confirmDeleteMessage ይጠራል
                            return GestureDetector(
                              onLongPress: () => _confirmDeleteMessage(msg),
                              child: _buildMessageBubble(content, isMe, timeStr),
                            );
                          },
                        ),
            ),

            // 💌 የመልእክት መጻፊያ ሳጥን
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1F22),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B2D31),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'መልእክት ጻፍ...',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blueAccent, Colors.blue.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : const Color(0xFF2B2D31),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time,
                    style: const TextStyle(color: Colors.white60, fontSize: 9),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all, size: 12, color: Colors.cyanAccent),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
