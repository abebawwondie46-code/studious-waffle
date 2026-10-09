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
  bool _isSaving = false;
  
  int _postsCount = 0;
  int _likesCount = 0;
  int _followersCount = 0;
  
  // ለጽሁፍ መቀበያ መቆጣጠሪያዎች (Controllers)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
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

      // 2. ከ profiles ቴብል የተጠቃሚውን ስም፣ ስልክ እና ኢሜይል ማምጣት
      try {
        final profileData = await supabase
            .from('profiles')
            .select('full_name, phone_number, email, avatar_url')
            .maybeSingle();

        if (profileData != null) {
          _nameController.text = profileData['full_name'] ?? '';
          _phoneController.text = profileData['phone_number'] ?? '';
          _emailController.text = profileData['email'] ?? '';
          _profileImageUrl = profileData['avatar_url'];
        }
      } catch (_) {}

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

  // ከጋለሪ ወይም ከካሜራ ፎቶ መምረጫ / ማንሻ ሜኑ
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

  // ፎቶን መርጦ ወይም አንስቶ ወደ Supabase Storage መጫን
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // መረጃዎችን (ስም፣ ኢሜይል፣ ስልክ) በቀጥታ ሴቭ ማድረግ
  Future<void> _saveProfileChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final newName = _nameController.text.trim();
      final newEmail = _emailController.text.trim();
      final newPhone = _phoneController.text.trim();

      await supabase.from('profiles').upsert({
        'id': 1,
        'full_name': newName.isNotEmpty ? newName : 'Community Creator',
        'email': newEmail.isNotEmpty ? newEmail : '',
        'phone_number': newPhone.isNotEmpty ? newPhone : 'Not provided',
      });

      setState(() {
        _isSaving = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
      );
    }
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
            
            // የፕሮፋይል ፎቶ መቀየሪያ
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
            
            // የተጠቃሚው ስም (TextField)
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

            // የተጠቃሚው ኢሜይል (TextField - Secure/Obscured & Editable)
            TextField(
              controller: _emailController,
              readOnly: false, // እንዲፃፍበት ተፈቅዷል
              obscureText: true, // ሲፃፍ በነጥብ (••••) እንዲሸፈን
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.start,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address (Secure)',
                labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF16161A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 14),

            // የተጠቃሚው ስልክ ቁጥር (TextField)
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
            
            const SizedBox(height: 20),
            
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
            
            const SizedBox(height: 24),

            // Save Changes አዝራር
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProfileChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2575FC),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 12),
            
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
