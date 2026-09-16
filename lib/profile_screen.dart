import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  final String profileImageUrl;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.profileImageUrl,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _username;
  String _bio = '📱 Tech Creator & Developer | Building cool apps 🚀';
  File? _selectedImageFile;

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
  }

  // 1. Profile Picture Picker with State Update
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImageFile = File(image.path);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      }
    }
  }

  // 2. Settings Bottom Sheet
  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text('Account', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: Colors.white),
              title: const Text('Notifications', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.white),
              title: const Text('Privacy', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Share Action
  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile link copied: https://myapp.com/@${_username.toLowerCase()}')),
    );
  }

  // 4. Logout Confirmation Dialog
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121C),
        elevation: 0,
        centerTitle: true,
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
              } else if (value == 'share') {
                _shareProfile();
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
              const PopupMenuItem<String>(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.white, size: 20),
                    SizedBox(width: 12),
                    Text('Share Profile', style: TextStyle(color: Colors.white)),
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
                    const SizedBox(height: 12),
                    // Profile Image with Dynamic File/Network Switch
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.grey.shade800,
                            backgroundImage: _selectedImageFile != null
                                ? FileImage(_selectedImageFile!) as ImageProvider
                                : NetworkImage(widget.profileImageUrl),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF2B54),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '@${_username.toLowerCase().replaceAll(' ', '')}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Bio Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        _bio,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stats Row
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
                    // Edit Profile Button
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
                                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2B54))),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: bioController,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        labelText: 'Bio',
                                        labelStyle: TextStyle(color: Colors.white70),
                                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF2B54))),
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
                                    onPressed: () {
                                      setState(() {
                                        _username = nameController.text;
                                        _bio = bioController.text;
                                      });
                                      Navigator.pop(context);
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
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.bookmark_border, color: Colors.white),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bookmarks feature coming soon!')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // Tab Header
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  const TabBar(
                    indicatorColor: Colors.white,
                    indicatorWeight: 2,
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
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No liked videos yet',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
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
    if (userVideos.isEmpty) {
      return const Center(
        child: Text(
          'No videos uploaded yet',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }
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
        return GestureDetector(
          onTap: () {
            // Creative Video Preview Dialog
            showDialog(
              context: context,
              builder: (context) => Dialog(
                backgroundColor: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(userVideos[index], fit: BoxFit.cover),
                      const Icon(Icons.play_circle_fill, color: Colors.white70, size: 64),
                    ],
                  ),
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                userVideos[index],
                fit: BoxFit.cover,
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Row(
                  children: const [
                    Icon(Icons.play_arrow_outlined, color: Colors.white, size: 16),
                    SizedBox(width: 2),
                    Text(
                      '2.4K',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF12121C),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
