import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// 1. አድሚን መሆን አለመሆኑን ማረጋገጥ
  static Future<bool> checkIfUserIsAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.email == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('is_admin')
          .eq('email', user.email!)
          .maybeSingle();

      if (response != null && response['is_admin'] == true) {
        return true;
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
    }
    return false;
  }

  /// 2. የ app_settings መረጃዎችን ከሰርቨር ማንበብ
  static Future<Map<String, dynamic>?> fetchAppSettings() async {
    try {
      final response = await _supabase
          .from('app_settings')
          .select()
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching app settings: $e');
      return null;
    }
  }

  /// 3. የ app_settings መረጃዎችን (Maintenance እና Announcement) በቀጥታ ማሻሻል
  static Future<bool> updateAppSettings({
    required bool maintenanceMode,
    required String announcement,
  }) async {
    try {
      final List<dynamic> existing = await _supabase.from('app_settings').select('id');
      
      if (existing.isNotEmpty) {
        final id = existing[0]['id'];
        await _supabase.from('app_settings').update({
          'maintenance_mode': maintenanceMode,
          'announcement': announcement,
        }).eq('id', id);
      } else {
        await _supabase.from('app_settings').insert({
          'maintenance_mode': maintenanceMode,
          'announcement': announcement,
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error updating app settings: $e');
      return false;
    }
  }

  /// 4. አፕ ሲከፈት Maintenance Mode ወይም Announcement ካለ ማሳያ
  static Future<void> checkAppStatus(BuildContext context) async {
    final settings = await fetchAppSettings();
    if (settings == null) return;

    final bool maintenanceMode = settings['maintenance_mode'] ?? false;
    final String? announcement = settings['announcement'];

    if (!context.mounted) return;

    if (maintenanceMode) {
      bool isAdmin = await checkIfUserIsAdmin();
      if (!isAdmin) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A2A2A),
            title: const Text('System Maintenance', style: TextStyle(color: Colors.redAccent)),
            content: const Text(
              'አፑ በአሁኑ ሰዓት በጥገና ላይ ይገኛል። እባክዎ ትንሽ ቆይተው ይሞክሩ።',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {},
                child: const Text('OK', style: TextStyle(color: Colors.greenAccent)),
              ),
            ],
          ),
        );
        return;
      }
    }

    if (announcement != null && announcement.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(announcement, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.green[800],
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// 5. አጠቃላይ ስታቲስቲክስ ማምጣት
  static Future<Map<String, int>> fetchAppStatistics() async {
    try {
      final usersRes = await _supabase.from('profiles').select('id');
      final postsRes = await _supabase.from('posts').select('id');
      final videosRes = await _supabase.from('videos').select('id');

      return {
        'total_users': (usersRes as List).length,
        'total_posts': (postsRes as List).length,
        'total_videos': (videosRes as List).length,
      };
    } catch (e) {
      return {'total_users': 0, 'total_posts': 0, 'total_videos': 0};
    }
  }

  /// 6. አክቲቭ ተጠቃሚዎችን በነጥብ ማምጣት (Leaderboard)
  static Future<List<Map<String, dynamic>>> fetchTopActiveUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('full_name, email, activity_points, avatar_url')
          .order('activity_points', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// 7. ተጠቃሚን ማገድ ወይም መክፈት (Ban User)
  static Future<bool> toggleUserBan(String email, bool banStatus) async {
    try {
      await _supabase
          .from('profiles')
          .update({'is_banned': banStatus})
          .eq('email', email);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 8. አድሚን ፓነል ዋና ዳሽቦርድ መክፈቻ
  static void showAdminPanel(BuildContext context) async {
    final settings = await fetchAppSettings();
    
    final TextEditingController announcementController = TextEditingController(
      text: settings?['announcement'] ?? '',
    );
    bool maintenanceValue = settings?['maintenance_mode'] ?? false;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 4,
        child: AlertDialog(
          backgroundColor: const Color(0xFF16161A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.admin_panel_settings, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('የአድሚን ማዕከል (Admin Control)', style: TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 420,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  labelColor: Colors.redAccent,
                  unselectedLabelColor: Colors.white54,
                  indicatorColor: Colors.redAccent,
                  tabs: [
                    Tab(text: 'ቅንብሮች/Maintenance', icon: Icon(Icons.settings, size: 16)),
                    Tab(text: 'ስታቲስቲክስ', icon: Icon(Icons.analytics, size: 16)),
                    Tab(text: 'ተጠቃሚዎች', icon: Icon(Icons.people, size: 16)),
                    Tab(text: 'ሽልማት/Leaderboard', icon: Icon(Icons.emoji_events, size: 16)),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Tab 1: System Settings
                      StatefulBuilder(
                        builder: (context, setStateBuilder) => ListView(
                          children: [
                            const SizedBox(height: 10),
                            TextField(
                              controller: announcementController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'አዲስ ማስታወቂያ ጻፍ (Announcement)',
                                labelStyle: TextStyle(color: Colors.white54),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white24),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SwitchListTile(
                              title: const Text(
                                'የጥገና ሁኔታ (Maintenance)',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              value: maintenanceValue,
                              activeColor: Colors.redAccent,
                              onChanged: (val) {
                                setStateBuilder(() {
                                  maintenanceValue = val;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: () async {
                                bool success = await updateAppSettings(
                                  maintenanceMode: maintenanceValue,
                                  announcement: announcementController.text,
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'ቅንብሩ ተቀይሯል!' : 'ማስተካከል አልተቻለም'),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                              },
                              child: const Text('ቅንብሮችን አስቀምጥ', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),

                      // Tab 2: Analytics
                      FutureBuilder<Map<String, int>>(
                        future: fetchAppStatistics(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
                          }
                          final stats = snapshot.data ?? {};
                          return ListView(
                            children: [
                              _buildStatCard('ጠቅላላ ተጠቃሚዎች (Total Users)', '${stats['total_users'] ?? 0}', Icons.group, Colors.blue),
                              _buildStatCard('ጠቅላላ ፖስቶች (Total Posts)', '${stats['total_posts'] ?? 0}', Icons.article, Colors.orange),
                              _buildStatCard('ጠቅላላ ቪዲዮዎች (Total Videos)', '${stats['total_videos'] ?? 0}', Icons.video_library, Colors.green),
                            ],
                          );
                        },
                      ),

                      // Tab 3: Users Management
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _supabase.from('profiles').select('full_name, email, is_banned').limit(20),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
                          }
                          final users = snapshot.data ?? [];
                          if (users.isEmpty) return const Center(child: Text('ምንም ተጠቃሚ የለም', style: TextStyle(color: Colors.white54)));

                          return ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              bool isBanned = user['is_banned'] ?? false;
                              return ListTile(
                                title: Text(user['full_name'] ?? 'ስም የሌለው', style: const TextStyle(color: Colors.white, fontSize: 14)),
                                subtitle: Text(user['email'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                trailing: IconButton(
                                  icon: Icon(isBanned ? Icons.lock : Icons.lock_open, color: isBanned ? Colors.red : Colors.green),
                                  onPressed: () async {
                                    await toggleUserBan(user['email'], !isBanned);
                                    Navigator.pop(context);
                                    showAdminPanel(context);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),

                      // Tab 4: Reward Leaderboard
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: fetchTopActiveUsers(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
                          }
                          final topUsers = snapshot.data ?? []; // እዚህ ጋር ከ {} ወደ [] ተስተካክሏል
                          if (topUsers.isEmpty) return const Center(child: Text('ምንም መረጃ የለም', style: TextStyle(color: Colors.white54)));

                          return ListView.builder(
                            itemCount: topUsers.length,
                            itemBuilder: (context, index) {
                              final user = topUsers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: index == 0 ? Colors.amber : Colors.blueAccent,
                                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(user['full_name'] ?? 'ተጠቃሚ', style: const TextStyle(color: Colors.white, fontSize: 14)),
                                trailing: Text('${user['activity_points'] ?? 0} ነጥብ', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ዝጋ', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF222228),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 4),
              Text(count, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
