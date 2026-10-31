import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// 1. አድሚን መሆን አለመሆኑን ማረጋገጥ
  static Future<bool> checkIfUserIsAdmin() async {
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

  /// 2. የ app_settings መረጃዎችን በቋሚ id: 1 ማንበብ
  static Future?> fetchAppSettings() async {
    try {
      var response = await _supabase
          .from('app_settings')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (response == null) {
        await _supabase.from('app_settings').upsert({
          'id': 1,
          'is_competition_active': true,
          'maintenance_mode': false,
          'announcement': '',
        });
        response = {
          'id': 1,
          'is_competition_active': true,
          'maintenance_mode': false,
          'announcement': '',
        };
      }

      return response;
    } catch (e) {
      debugPrint('Error fetching app settings: $e');
      return null;
    }
  }

  /// 3. የ app_settings መረጃዎችን ማሻሻል
  static Future<bool> updateAppSettings({
    required bool maintenanceMode,
    required String announcement,
  }) async {
    try {
      await _supabase.from('app_settings').upsert({
        'id': 1,
        'maintenance_mode': maintenanceMode,
        'announcement': announcement,
      });
      return true;
    } catch (e) {
      debugPrint('Error updating app settings: $e');
      return false;
    }
  }

  /// 4. የውድድር ሁኔታን (Competition Active) ማሻሻል እና ኦፍ ሲደረግ ነጥቦቹን ወደ 0 ማድረግ
  static Future<bool> toggleCompetitionStatus(bool isActive) async {
    try {
      await _supabase.from('app_settings').upsert({
        'id': 1,
        'is_competition_active': isActive,
      });

      if (!isActive) {
        await resetAllPoints();
      }

      debugPrint('የውድድር ስቴት በተሳካ ሁኔታ ወደ $isActive ተቀይሯል!');
      return true;
    } catch (e) {
      debugPrint('Error updating competition status: $e');
      return false;
    }
  }

  /// 5. ሁሉንም ተጠቃሚዎች ነጥብ በግልጽ ወደ 0 መመለሻ (Reset Points)
  static Future<bool> resetAllPoints() async {
    try {
      final response = await _supabase.from('user_points').select('telegram_id');
      
      if (response != null && (response as List).isNotEmpty) {
        for (var row in response) {
          final tId = row['telegram_id'];
          await _supabase.from('user_points').update({'points': 0}).eq('telegram_id', tId);
        }
      }

      debugPrint('ሁሉም የተጠቃሚ ነጥቦች በተሳካ ሁኔታ ወደ 0 ተደምስሰዋል!');
      return true;
    } catch (e) {
      debugPrint('Error resetting points: $e');
      return false;
    }
  }

  /// 6. አፕ ሲከፈት ማስታወቂያ የሚያሳይ
  static Future<void> checkAppStatus(BuildContext context) async {
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
  static Future> fetchAppStatistics() async {
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

  /// 8. አክቲቭ ተጠቃሚዎችን ከ profiles ቴብል ስም እና ፎቶ ጋር አቀናጅቶ ማምጣት (Leaderboard)
  static Future<List>> fetchTopActiveUsers() async {
    try {
      final pointsResponse = await _supabase
          .from('user_points')
          .select()
          .order('points', ascending: false)
          .limit(20);

      if (pointsResponse == null || (pointsResponse as List).isEmpty) {
        return [];
      }

      List> leaderboardList = [];

      for (var pointRow in pointsResponse) {
        final telegramId = pointRow['telegram_id'];
        
        var profileResponse;
        if (telegramId != null) {
          try {
            profileResponse = await _supabase
                .from('profiles')
                .select('full_name, username, avatar_url')
                .eq('telegram_id', telegramId)
                .maybeSingle();
          } catch (_) {
            profileResponse = null;
          }
        }

        String displayName = profileResponse?['full_name'] ?? 
                             profileResponse?['username'] ?? 
                             pointRow['username'] ?? 
                             'ስም የሌለው ተጠቃሚ';

        String avatarUrl = profileResponse?['avatar_url'] ?? '';

        leaderboardList.add({
          'telegram_id': telegramId ?? 'N/A',
          'username': displayName,
          'avatar_url': avatarUrl,
          'points': pointRow['points'] ?? 0,
        });
      }

      return leaderboardList;
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  /// 9. ተጠቃሚን ማገድ ወይም መክፈት (Ban User)
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

  /// 10. አድሚን ፓነል ዋና ዳሽቦርድ መክፈቻ
  static void showAdminPanel(BuildContext context) async {
    final settings = await fetchAppSettings();
    
    final TextEditingController announcementController = TextEditingController(
      text: settings?['announcement'] ?? '',
    );
    bool maintenanceValue = settings?['maintenance_mode'] ?? false;
    bool competitionValue = settings?['is_competition_active'] ?? true;

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

                            // የውድድር ስዊች መቆጣጠሪያ
                            Container(
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
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(val ? 'ውድድሩ ተጀምሯል! 🚀' : 'ውድድሩ ጠፍቷል! ነጥቦች ወደ 0 ተመልሰዋል 🔄'),
                                          backgroundColor: val ? Colors.green : Colors.orange,
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
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
                          final List users = List.from((snapshot.data as List?) ?? []);
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

                      // Tab 4: Reward Leaderboard (የፕሮፋይል ፎቶ እና ትክክለኛ ስም የሚታይበት)
                      FutureBuilder(
                        future: fetchTopActiveUsers(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Colors.redAccent));
                          }
                          final List topUsers = List.from((snapshot.data as List?) ?? []);
                          if (topUsers.isEmpty) return const Center(child: Text('ምንም ተወዳዳሪ የለም', style: TextStyle(color: Colors.white54)));

                          return ListView.builder(
                            itemCount: topUsers.length,
                            itemBuilder: (context, index) {
                              final user = topUsers[index];
                              
                              Color rankColor;
                              if (index == 0) {
                                rankColor = Colors.amber; // 1ኛ (ወርቃማ)
                              } else if (index == 1) {
                                rankColor = Colors.grey.shade400; // 2ኛ (ብር)
                              } else if (index == 2) {
                                rankColor = Colors.brown.shade300; // 3ኛ (ነሐስ)
                              } else {
                                rankColor = Colors.blueAccent;
                              }

                              String username = user['username'] ?? 'ስም የሌለው ተጠቃሚ';
                              String avatarUrl = user['avatar_url'] ?? '';

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E2C),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: rankColor.withOpacity(0.5), width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    // 🥇 የደረጃ ቁጥር ባጅ
                                    CircleAvatar(
                                      backgroundColor: rankColor,
                                      radius: 18,
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    
                                    // 🖼️ የፕሮፋይል ፎቶ (ፎቶ ከሌለ የስሙ የመጀመሪያ ፊደል)
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.grey[800],
                                      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                                      child: avatarUrl.isEmpty
                                          ? Text(
                                              username.isNotEmpty ? username[0].toUpperCase() : 'U',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),

                                    // 👤 የተጠቃሚው ስም እና ቴሌግራም ID
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            username,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'ID: ${user['telegram_id'] ?? 'N/A'}',
                                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),

                                    // 🏆 ነጥብ
                                    Text(
                                      '${user['points'] ?? 0} ነጥብ',
                                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(width: 4),

                                    // 🎁 የሽልማት መስጫ ቁልፍ
                                    IconButton(
                                      icon: const Icon(Icons.card_giftcard, color: Colors.amber, size: 22),
                                      tooltip: 'ተጠቃሚውን ሽልማት ስጥ',
                                      onPressed: () {
                                        _showAwardDialog(context, username, user['telegram_id']);
                                      },
                                    ),
                                  ],
                                ),
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

  /// ተጠቃሚን የመሸለሚያ ፖፕ-አፕ ዳይሎግ (Award Dialog)
  static void _showAwardDialog(BuildContext context, String username, String telegramId) {
    final TextEditingController prizeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.card_giftcard, color: Colors.amber),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ለሽልማት መምረጫ: $username',
                style: const TextStyle(color: Colors.white, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ለዚህ አሸናፊ የሚሰጡትን ሽልማት (ለምሳሌ፦ የብር መጠን፣ ስጦታ ወይም ሰርተፍኬት) ከታች ይጻፉ:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: prizeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ለምሳሌ፦ 1000 ብር ወይም ልዩ ስጦታ',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF16161A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ይቅር', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () async {
              String prize = prizeController.text.trim();
              if (prize.isEmpty) return;

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 $username ውብ ሽልማት ተሰጥቶታል: $prize!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: const Text('ሽልማት ላክ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
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
