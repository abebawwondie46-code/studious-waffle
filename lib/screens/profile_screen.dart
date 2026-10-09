import 'dart:io';
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
  User? _currentUser;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  
  int _postsCount = 0;
  int _likesCount = 0;
  int _followersCount = 0;
  
  String _userName = 'Community Creator';
  String _phoneNumber = 'Not provided';
  String? _profileImageUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserProfileAndStats();
  }

  Future<void> _loadUserProfileAndStats() async {
    try {
      final user = supabase.auth.currentUser ?? supabase.auth.currentSession?.user;
      
      // 1. የ ፖስቶች ብዛት ማምጣት
      int postsLen = 0;
      try {
        final postsResponse = await supabase.from('posts').select('id');
        postsLen = (postsResponse as List).length;
      } catch (_) {}

      // 2. ከ profiles ቴብል የተጠቃሚውን ስም፣ ስልክ እና ፎቶ ማምጣት
      if (user != null) {
        try {
          final profileData = await supabase
              .from('profiles')
              .select('full_name, phone_number, avatar_url')
              .eq('id', user.id)
              .maybeSingle();

          if (profileData != null) {
            setState(() {
              _userName = profileData['full_name'] ?? 'Community Creator';
              _phoneNumber = profileData['phone_number'] ?? 'Not provided';
              _profileImageUrl = profileData['avatar_url'];
            });
          }
        } catch (_) {}
      }

      // 3. Likes ቆጠራ
      int likesLen = 0;
      try {
        final likesResponse = await supabase.from('likes').select('id');
        likesLen = (likesResponse as List).length;
      } catch (_) {}

      // 4. Followers ቆጠራ
      int followersLen = 0;
      try {
        final followersResponse = await supabase.from('followers').select('id');
        followersLen = (followersResponse as List).length;
      } catch (_) {}

      setState(() {
        _currentUser = user;
        _postsCount = postsLen;
        _likesCount = likesLen;
        _followersCount = followersLen;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ፎቶን ከጋለሪ መርጦ ወደ Supabase Storage መጫን እና ፕሮፋይል ማዘመን
  Future<void> _pickAndUploadProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final user = supabase.auth.currentUser ?? supabase.auth.currentSession?.user;
      if (user == null) {
        setState(() => _isUploadingImage = false);
        return;
      }

      final file = File(image.path);
      final fileName = 'profile_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'avatars/$fileName';

      await supabase.storage.from('videos').upload(
            filePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = supabase.storage.from('videos').getPublicUrl(filePath);

      await supabase.from('profiles').upsert({
        'id': user.id,
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ስም እና ስልክ ቁጥር ማስተካከያ ፖፕአፕ (Edit Profile Dialog)
  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: _userName == 'Community Creator' ? '' : _userName);
    final TextEditingController phoneController = TextEditingController(text: _phoneNumber == 'Not provided' ? '' : _phoneNumber);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F1F23),
          title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2575FC)),
              onPressed: () async {
                final user = supabase.auth.currentUser ?? supabase.auth.currentSession?.user;
                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No logged in user found! Please log in again.'), backgroundColor: Colors.red),
                  );
                  return;
                }

                final newName = nameController.text.trim();
                final newPhone = phoneController.text.trim();

                try {
                  // መረጃውን ወደ Supabase profiles ቴብል መላክ
                  await supabase.from('profiles').upsert({
                    'id': user.id,
                    'full_name': newName.isNotEmpty ? newName : 'Community Creator',
                    'phone_number': newPhone.isNotEmpty ? newPhone : 'Not provided',
                  });

                  setState(() {
                    _userName = newName.isNotEmpty ? newName : 'Community Creator';
                    _phoneNumber = newPhone.isNotEmpty ? newPhone : 'Not provided';
                  });

                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign out: $e'), backgroundColor: Colors.red),
      );
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
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0A0A0C),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white70),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // የፕሮፋይል ፎቶ መቀየሪያ (ከካሜራ አዶ ጋር)
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
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isUploadingImage ? null : _pickAndUploadProfileImage,
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
            const SizedBox(height: 12),
            
            // የተጠቃሚው ስም
            Text(
              _userName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),

            // የተጠቃሚው ኢሜይል
            Text(
              _currentUser?.email ?? 'No Email',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 4),

            // የተጠቃሚው ስልክ ቁጥር
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone, color: Colors.white54, size: 14),
                const SizedBox(width: 6),
                Text(
                  _phoneNumber,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // ስታቲስቲክስ (Posts, Likes, Followers)
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
                  _ProfileStatItem(title: 'Posts', count: _postsCount.toString()),
                  _ProfileStatItem(title: 'Likes', count: _likesCount.toString()),
                  _ProfileStatItem(title: 'Followers', count: _followersCount.toString()),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Log Out አዝራር
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
