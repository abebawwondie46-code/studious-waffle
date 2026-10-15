import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// 1. አሁን የገባው ተጠቃሚ አድሚን መሆኑን በኢሜል ማረጋገጫ
  static Future<bool> checkIfUserIsAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.email == null) return false;

      // በ UUID ፋንታ በቀጥታ በ ዩዘር ኢሜል (email) ማረጋገጥ
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

  /// 3. የ app_settings መረጃዎችን ማሻሻል (Update)
  static Future<bool> updateAppSettings({
    required bool maintenanceMode,
    required String announcement,
  }) async {
    try {
      final isAdmin = await checkIfUserIsAdmin();
      if (!isAdmin) return false;

      final existing = await _supabase.from('app_settings').select('id').maybeSingle();
      
      if (existing != null) {
        final id = existing['id'];
        await _supabase.from('app_settings').update({
          'maintenance_mode': maintenanceMode,
          'announcement': announcement,
        }).eq('id', id);
        return true;
      }
    } catch (e) {
      debugPrint('Error updating app settings: $e');
    }
    return false;
  }

  /// 4. አፕ ሲከፈት Maintenance Mode ወይም Announcement ካለ ማሳያ
  static Future<void> checkAppStatus(BuildContext context) async {
    final settings = await fetchAppSettings();
    if (settings == null) return;

    final bool maintenanceMode = settings['maintenance_mode'] ?? false;
    final String? announcement = settings['announcement'];

    if (!context.mounted) return;

    if (maintenanceMode) {
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

  /// 5. አድሚን ፓነል ፖፕ-አፕ (ቁልፉ ሲጫን የሚከፈተው ዳይሎግ)
  static void showAdminPanel(BuildContext context) {
    final TextEditingController announcementController = TextEditingController();
    bool maintenanceValue = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'የአድሚን መቆጣጠሪያ ፓነል',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: announcementController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'አዲስ ማስታወቂያ ጻፍ',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 15),
            StatefulBuilder(
              builder: (context, setStateBuilder) => SwitchListTile(
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
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ሰርዝ', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              bool success = await updateAppSettings(
                maintenanceMode: maintenanceValue,
                announcement: announcementController.text,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'ቅንብሩ ተቀይሯል!' : 'ማስተካከል አልተቻለም'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('አስቀምጥ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
