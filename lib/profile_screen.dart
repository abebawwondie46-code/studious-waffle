import 'settings_screens.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  final String profileImageUrl;
  final Function(String newUsername, String newImagePath)? onProfileUpdated;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.profileImageUrl,
    this.onProfileUpdated,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _username;
  String _bio = '📱 Tech Creator & Developer | Building cool apps 🚀';
  File? _selectedImageFile;
  bool _isLoading = true;

  final List<String> userVideos = [
    'https://picsum.photos/id/10/300/400',
    'https://picsum.photos/id/20/300/400',
    'https://picsum.photos/id/30/300/400',
    'https://picsum.photos/id/40/300/400',
    'https://picsum.photos/id/50/300/400',
    'https://picsum.photos/id/60/300/400',
  ];

  @override
  void initState() {
    super.initState();
    _username = widget.username;
    _loadSavedData();
  }

  // 1. Load Saved Profile Data permanently
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('user_name') ?? widget.username;
      _bio = prefs.getString('user_bio') ?? '📱 Tech Creator & Developer | Building cool apps 🚀';
      String? imagePath = prefs.getString('user_image_path');
      if (imagePath != null && File(imagePath).existsSync()) {
        _selectedImageFile = File(imagePath);
      }
      _isLoading = false;
    });
  }

  // Save profile updates to storage
  Future<void> _saveData(String name, String bio, String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_bio', bio);
    if (imagePath != null) {
      await prefs.setString('user_image_path', imagePath);
    }
    if (widget.onProfileUpdated != null) {
      widget.onProfileUpdated!(name, imagePath ?? '');
    }
  }

  // 2. Camera or Gallery Selector
  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Change Profile Photo',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFFFF2B54)),
                title: const Text('Take Photo with Camera', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFFFF2B54)),
                title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 85);
    if (image != null) {
      setState(() {
        _selectedImageFile = File(image.path);
      });
      await _saveData(_username, _bio, image.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo saved successfully!')),
        );
      }
    }
  }

  // 3. Complete Log Out Handler
  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all user session data

    if (!mounted) return;

    // Pop current screen or navigate to login/root page
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushReplacementNamed('/'); // or login route
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2B54)),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _handleLogout(); // Perform logout & exit screen
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.white),
              title: const Text('Account Settings', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_none, color: Colors.white),
              title: const Text('Notifications', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.white),
              title: const Text('Privacy & Security', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                );
              },
             ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF12121C),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFF2B54))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF12121C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121C),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          _username,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1E1E2C),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'settings') {
                _showSettingsModal();
              } else if (value == 'logout') {
                _confirmLogout();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Settings', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    SizedBox(width: 12),
                    Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _showImageSourcePicker,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFFF2B54), Color(0xFFFF8E53)],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.grey.shade900,
                              backgroundImage: _selectedImageFile != null
                                  ? FileImage(_selectedImageFile!) as ImageProvider
                                  : NetworkImage(widget.profileImageUrl),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF2B54),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '@$_username',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        _bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatColumn('Following', '128'),
                        _buildStatDivider(),
                        _buildStatColumn('Followers', '12.4K'),
                        _buildStatDivider(),
                        _buildStatColumn('Likes', '85.2K'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            final nameController = TextEditingController(text: _username);
                            final bioController = TextEditingController(text: _bio);

                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E2C),
                                title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: nameController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Username',
                                        labelStyle: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: bioController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Bio',
                                        labelStyle: TextStyle(color: Colors.white70),
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
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2B54)),
                                    onPressed: () async {
                                      setState(() {
                                        _username = nameController.text;
                                        _bio = bioController.text;
                                      });
                                      await _saveData(_username, _bio, _selectedImageFile?.path);
                                      if (mounted) Navigator.pop(context);
                                    },
                                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF2B54),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  const TabBar(
                    indicatorColor: Color(0xFFFF2B54),
                    indicatorWeight: 3,
                    tabs: [
                      Tab(icon: Icon(Icons.grid_on_rounded, color: Colors.white)),
                      Tab(icon: Icon(Icons.favorite_border, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildVideoGrid(),
              const Center(child: Text('No liked videos yet', style: TextStyle(color: Colors.white54))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 16,
      width: 1,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildVideoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      itemCount: userVideos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        final imageUrl = userVideos[index];
        return GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.black,
                insetPadding: EdgeInsets.zero,
                child: Stack(
                  children: [
                    Center(
                      child: InteractiveViewer(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 20,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade900,
              child: const Icon(Icons.movie_creation, color: Colors.white54),
            ),
          ),
        );
      },
    );
  }
}
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF12121C),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
