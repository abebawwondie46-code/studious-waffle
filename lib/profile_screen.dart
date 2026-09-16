import 'package:flutter/material.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String username;
  final String profileImageUrl;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.profileImageUrl,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  // Demo video list placeholder for grid view
  final List<String> userVideos = List.generate(
    12,
    (index) => 'https://picsum.photos/300/400?random=$index',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121C),
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.username,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF1E1E2C),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.settings, color: Colors.white),
                      title: const Text('Settings', style: TextStyle(color: Colors.white)),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.share, color: Colors.white),
                      title: const Text('Share Profile', style: TextStyle(color: Colors.white)),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.redAccent),
                      title: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            );
          },
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
                    // Profile Image
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey.shade800,
                      backgroundImage: NetworkImage(widget.profileImageUrl),
                    ),
                    const SizedBox(height: 10),
                    // Username Handle
                    Text(
                      '@${widget.username.toLowerCase().replaceAll(' ', '_')}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Stats Row (Following, Followers, Likes)
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
                    // Action Buttons (Edit Profile / Follow)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E2C),
              title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
              content: const Text(
                'Profile editing features will be connected to Supabase soon.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: Color(0xFFFF2B54))),
                ),
              ],
            ),
          );
        },
             style: ElevatedButton.styleFrom(
               backgroundColor: const Color(0xFFFF2B54),
                  padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white24),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.bookmark_border,
                              color: Colors.white,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              // Grid View Tab Bar Header
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  const TabBar(
                    indicatorColor: Colors.white,
                    indicatorWeight: 2,
                    tabs: [
                      Tab(icon: Icon(Icons.grid_on_rounded, color: Colors.white)),
                      Tab(icon: Icon(Icons.favorite_border_rounded, color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // User Uploaded Videos Grid
              _buildVideoGrid(),
              // Liked Videos Grid Placeholder
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
      height: 15,
      width: 1,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  Widget _buildVideoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      itemCount: userVideos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              userVideos[index],
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 6,
              left: 6,
              child: Row(
                children: const [
                  Icon(Icons.play_arrow_outlined, color: Colors.white, size: 16),
                  SizedBox(width: 2),
                  Text(
                    '2.4K',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// Custom Delegate to keep TabBar pinned at the top
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
