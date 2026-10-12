import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _obscureEmail = true;
  
  int _postsCount = 0;
  int _likesCount = 0;
  int _followersCount = 0;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  String? _profileImageUrl;
  String _currentFullName = 'Community Creator';
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndStats();
  }

  void _showNoInternetToast() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('No internet connection! Please check your network.'),
          ],
        ),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadUserProfileAndStats() async {
    try {
      int postsLen = 0;
      try {
        final postsResponse = await supabase.from('posts').select('id');
        postsLen = (postsResponse as List).length;
      } catch (_) {}

      try {
        final profileData = await supabase
            .from('profiles')
            .select('full_name, phone_number, email, avatar_url')
            .maybeSingle();

        if (profileData != null) {
          setState(() {
            _nameController.text = profileData['full_name'] ?? '';
            _currentFullName = profileData['full_name'] ?? 'Community Creator';
            _phoneController.text = profileData['phone_number'] ?? '';
            _emailController.text = profileData['email'] ?? '';
            _profileImageUrl = profileData['avatar_url'];
          });
        }
      } catch (_) {}

      int totalLikes = 0;
      try {
        final videosResponse = await supabase.from('videos').select('likes_count');
        for (var video in (videosResponse as List)) {
          int count = (video['likes_count'] as num?)?.toInt() ?? 0;
          totalLikes += max(0, count);
        }
      } catch (_) {}

      int totalFollowers = 0;
      try {
        final videosResponse = await supabase.from('videos').select('followers_count');
        for (var video in (videosResponse as List)) {
          int count = (video['followers_count'] as num?)?.toInt() ?? 0;
          if (count > 0) {
            totalFollowers += count;
          }
        }
      } catch (_) {}

      setState(() {
        _postsCount = postsLen;
        _likesCount = max(0, totalLikes);
        _followersCount = max(0, totalFollowers);
        _isLoading = false;
      });
    } catch (e) {
      _showNoInternetToast();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F1F23),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('Pick from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('Take a Photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadProfileImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadProfileImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final file = File(image.path);
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'avatars/$fileName';

      await supabase.storage.from('videos').upload(
            filePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = supabase.storage.from('videos').getPublicUrl(filePath);

      await supabase.from('profiles').upsert({
        'id': 1,
        'avatar_url': imageUrl,
      });

      setState(() {
        _profileImageUrl = imageUrl;
        _isUploadingImage = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      _showNoInternetToast();
    }
  }

  Future<void> _saveProfileChanges() async {
    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    final newPhone = _phoneController.text.trim();

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{7,15}$');

    if (newName.isEmpty || !newName.contains(' ')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name!'), backgroundColor: Colors.red),
      );
      return;
    }
    if (newEmail.isEmpty || !emailRegex.hasMatch(newEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix your email address!'), backgroundColor: Colors.red),
      );
      return;
    }
    if (newPhone.isEmpty || !phoneRegex.hasMatch(newPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix your phone number!'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_profileImageUrl == null || _profileImageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile picture!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await supabase.from('profiles').upsert({
        'id': 1,
        'full_name': newName,
        'email': newEmail,
        'phone_number': newPhone,
        'avatar_url': _profileImageUrl,
      });

      setState(() {
        _currentFullName = newName;
        _isSaving = false;
        _isEditing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showNoInternetToast();
    }
  }

  Future<void> _signOut() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully logged out!'),
            backgroundColor: Colors.blueAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }

      try {
        await supabase.from('profiles').delete().match({'id': 1});
      } catch (_) {}

      try {
        await supabase.auth.signOut();
      } catch (_) {}

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0C),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2575FC))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(_isEditing ? Icons.check_rounded : Icons.edit_rounded, color: Colors.white70),
              onPressed: _isSaving
                  ? null
                  : () {
                      if (_isEditing) {
                        _saveProfileChanges();
                      } else {
                        setState(() {
                          _isEditing = true;
                        });
                      }
                    },
              tooltip: _isEditing ? 'Save Changes' : 'Edit Profile',
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white70),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: GlobalSearchDelegate(),
                );
              },
              tooltip: 'Search Posts, Likes & Followers',
            ),
            const Spacer(),
            const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
        backgroundColor: const Color(0xFF0A0A0C),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white70),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings opened!'), backgroundColor: Colors.indigo),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF2575FC),
                  backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingImage ? null : _showImageSourceDialog,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2575FC),
                          shape: BoxShape.circle,
                        ),
                        child: _isUploadingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            
            _isEditing
                ? Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.start,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF16161A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _emailController,
                        readOnly: false,
                        obscureText: _obscureEmail,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.start,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF16161A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureEmail ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureEmail = !_obscureEmail;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        keyboardType: TextInputType.phone,
                        textAlign: TextAlign.start,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF16161A),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Text(
                        _nameController.text.isNotEmpty ? _nameController.text : 'Community Creator',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _emailController.text.isNotEmpty 
                            ? ('•' * (_emailController.text.length > 10 ? 10 : _emailController.text.length)) 
                            : 'No Email',
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.phone, color: Colors.white54, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _phoneController.text.isNotEmpty ? _phoneController.text : 'Not provided',
                            style: const TextStyle(color: Colors.white54, fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF16161A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => UserPostsScreen(userName: _currentFullName, avatarUrl: _profileImageUrl)),
                      );
                    },
                    child: _ProfileStatItem(title: 'Posts', count: _postsCount.toString()),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserLikesScreen()),
                      );
                    },
                    child: _ProfileStatItem(title: 'Likes', count: _likesCount.toString()),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const UserFollowersScreen()),
                      );
                    },
                    child: _ProfileStatItem(title: 'Followers', count: _followersCount.toString()),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F1F23),
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  final String title;
  final String count;

  const _ProfileStatItem({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(color: Colors.white38, fontSize: 14),
        ),
      ],
    );
  }
}

// Global Search Delegate
class GlobalSearchDelegate extends SearchDelegate {
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFF0A0A0C),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF16161A),
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('posts').select(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2575FC)));
        }
        final posts = snapshot.data ?? [];
        final filtered = posts.where((p) {
          final caption = (p['caption'] ?? p['title'] ?? '').toString().toLowerCase();
          return caption.contains(query.toLowerCase());
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No results found.', style: TextStyle(color: Colors.white54)));
        }

        return ListView.builder(
          itemCount: filtered.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final item = filtered[index];
            final caption = item['caption'] ?? item['title'] ?? 'No Description';
            return ListTile(
              title: Text(caption, style: const TextStyle(color: Colors.white)),
              subtitle: Text(item['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(color: Colors.white54)),
            );
          },
        );
      },
    );
  }
}

// User Posts Screen (Updated to accept profile name and avatar)
class UserPostsScreen extends StatelessWidget {
  final String userName;
  final String? avatarUrl;

  const UserPostsScreen({super.key, required this.userName, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final SupabaseClient supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: AppBar(
        title: const Text('My Posts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0A0A0C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase.from('posts').select().order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2575FC)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white54)));
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const Center(child: Text('No posts found.', style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            itemCount: posts.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final post = posts[index];
              final caption = post['caption'] ?? post['title'] ?? 'No Description';
              final mediaUrl = post['media_url'] ?? post['video_url'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF2575FC),
                        backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                            ? NetworkImage(avatarUrl!)
                            : null,
                        child: (avatarUrl == null || avatarUrl!.isEmpty)
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(post['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                    if (mediaUrl.isNotEmpty)
                      Image.network(
                        mediaUrl,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: Colors.black26,
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 50)),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        caption,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// User Likes Screen
class UserLikesScreen extends StatelessWidget {
  const UserLikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SupabaseClient supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: AppBar(
        title: const Text('Liked Videos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0A0A0C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase.from('videos').select().order('likes_count', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2575FC)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white54)));
          }
          final videos = snapshot.data ?? [];
          if (videos.isEmpty) {
            return const Center(child: Text('No liked videos found.', style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            itemCount: videos.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final video = videos[index];
              final caption = video['caption'] ?? video['title'] ?? 'No Description';
              final videoUrl = video['video_url'] ?? video['media_url'] ?? '';
              int rawLikes = (video['likes_count'] as num?)?.toInt() ?? 0;
              final likesCount = max(0, rawLikes);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF2575FC),
                        child: Icon(Icons.favorite, color: Colors.white),
                      ),
                      title: const Text('Liked Content', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite, color: Colors.pink, size: 18),
                          const SizedBox(width: 6),
                          Text('$likesCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (videoUrl.isNotEmpty)
                      Container(
                        height: 220,
                        width: double.infinity,
                        color: Colors.black,
                        child: const Center(
                          child: Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        caption,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// User Followers Screen
class UserFollowersScreen extends StatelessWidget {
  const UserFollowersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SupabaseClient supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: AppBar(
        title: const Text('Followers List', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0A0A0C),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase.from('videos').select().order('followers_count', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2575FC)));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white54)));
          }
          final followers = snapshot.data ?? [];
          if (followers.isEmpty) {
            return const Center(child: Text('No followers found.', style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            itemCount: followers.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final follower = followers[index];
              final title = follower['caption'] ?? follower['title'] ?? 'Community Follower';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16161A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10, width: 0.5),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2575FC),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('Joined: ${follower['created_at']?.toString().substring(0, 10) ?? ''}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
