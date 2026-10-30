import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// 1. አድሚን መሆን አለመሆኑን ማረጋገጥ
  static Future checkIfUserIsAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null && response['is_admin'] == true) {
        return true;
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
    }
    return false;
  }

  /// 2. የ app_settings መረጃዎችን ማንበብ
  static Future fetchAppSettings() async {
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

  /// 3. የ app_settings መረጃዎችን ማሻሻል
  static Future updateAppSettings({
    required bool maintenanceMode,
    required String announcement,
  }) async {
    try {
      final List existing = await _supabase.from('app_settings').select('id');
      
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

  /// 4. የውድድር ሁኔታን (Competition Active) በሰኩዮር መልኩ ማሻሻል
  static Future toggleCompetitionStatus(bool isActive) async {
    try {
      final List existing = await _supabase.from('app_settings').select('id');
      if (existing.isNotEmpty) {
        final id = existing[0]['id'];
        await _supabase.from('app_settings').update({
          'is_competition_active': isActive,
        }).eq('id', id);
      } else {
        await _supabase.from('app_settings').insert({
          'is_competition_active': isActive,
        });
      }
      return true;
    } catch (e) {
      debugPrint('Error updating competition status: $e');
      return false;
    }
  }

  /// 5. ሁሉንም ተጠቃሚዎች ነጥብ ወደ 0 መመለሻ (Reset Points)
  static Future resetAllPoints() async {
    try {
      await _supabase.from('user_points').update({'points': 0});
      return true;
    } catch (e) {
      debugPrint('Error resetting points: $e');
      return false;
    }
  }

  /// 6. አፕ ሲከፈት ማስታወቂያ የሚያሳይ
  static Future checkAppStatus(BuildContext context) async {
    final settings = await fetchAppSettings();
    if (settings == null) return;

    final String? announcement = settings['announcement'];

    if (!context.mounted) return;

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

  /// 7. አጠቃላይ ስታቲስቲክስ ማምጣት
  static Future fetchAppStatistics() async {
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

  /// 8. አክቲቭ ተጠቃሚዎችን በነጥብ ማምጣት (Leaderboard)
  static Future fetchTopActiveUsers() async {
    try {
      final response = await _supabase
          .from('user_points')
          .select('telegram_id, username, points')
          .order('points', ascending: false)
          .limit(10);
      return List.from(response);
    } catch (e) {
      return [];
    }
  }

  /// 9. ተጠቃሚን ማገድ ወይም መክፈት (Ban User)
  static Future toggleUserBan(String email, bool banStatus) async {
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

  /// 10. አድሚን ፓነል ዋና ዳሽቦርድ መክፈቻ
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
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('የአድሚን ማዕከል (Admin Control)', style: TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 480,
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
                      // Tab 1: System Settings & Competition Control
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
                            const SizedBox(height: 10),
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
                            const Divider(color: Colors.white24, height: 30),

                            // የውድድር እና የነጥብ መቆጣጠሪያ ፓነል (በStatefulBuilder የታገዘ ትክክለኛ ኦን/ኦፍ)
                            FutureBuilder(
                              future: fetchAppSettings(),
                              builder: (context, snapshot) {
                                final Map data = (snapshot.data as Map?) ?? {};
                                bool competitionValue = data['is_competition_active'] ?? true;

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E2C),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.emoji_events, color: Colors.amber, size: 18),
                                          SizedBox(width: 8),
                                          Text('የውድድር እና ነጥብ መቆጣጠሪያ', style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      SwitchListTile(
                                        title: const Text('የውድድር ነጥብ አሰጣጥ (Competition)', style: TextStyle(color: Colors.white, fontSize: 12)),
                                        subtitle: Text(
                                          competitionValue ? 'ውድድሩ በሥራ ላይ ነው (ON)' : 'ውድድሩ ቆሟል (OFF)',
                                          style: TextStyle(color: competitionValue ? Colors.greenAccent : Colors.redAccent, fontSize: 11),
                                        ),
                                        value: competitionValue,
                                        activeColor: Colors.amber,
                                        onChanged: (val) async {
                                          setStateBuilder(() {
                                            competitionValue = val;
                                          });
                                          await toggleCompetitionStatus(val);
                                        },
                                      ),
                                      const Divider(color: Colors.white12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.amber.shade800,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
                                          label: const Text('ውድድሩን ጨርሶ አዲስ ጀምር (Reset Points)', style: TextStyle(color: Colors.white, fontSize: 12)),
                                          onPressed: () async {
                                            bool confirmed = await showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                backgroundColor: const Color(0xFF1E1E3F),
                                                title: const Text('እርግጠኛ ነዎት?', style: TextStyle(color: Colors.white)),
                                                content: const Text('ይህ ድርጊት የሁሉንም ተጠቃሚዎች ነጥብ ወደ ዜሮ (0) ይመልሰዋል!', style: TextStyle(color: Colors.white70)),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ይቅር')),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                    onPressed: () => Navigator.pop(context, true), 
                                                    child: const Text('አዎ ሪሴት አድርግ', style: TextStyle(color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            ) ?? false;

                                            if (confirmed) {
                                              bool success = await resetAllPoints();
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(success ? 'ሁሉም ነጥቦች ተሰርዘው አዲስ ውድድር ተጀምሯል! 🚀' : 'ማስተካከል አልተቻለም')),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Tab 2: Analytics
                      FutureBuilder(
                        future: fetchAppStatistics(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
                          }
                          final Map stats = (snapshot.data as Map?) ?? {};
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
                      FutureBuilder(
                        future: _supabase.from('profiles').select('full_name, email, is_banned').limit(20),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
                          }
                          final List users = (snapshot.data as List?) ?? [];
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
                      FutureBuilder(
                        future: fetchTopActiveUsers(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
                          }
                          final List topUsers = (snapshot.data as List?) ?? [];
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
                                title: Text(user['username'] ?? 'ተጠቃሚ', style: const TextStyle(color: Colors.white, fontSize: 14)),
                                trailing: Text('${user['points'] ?? 0} ነጥብ', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
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
