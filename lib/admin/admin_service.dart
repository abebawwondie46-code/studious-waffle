import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// 1. አሁን የገባው ተጠቃሚ አድሚን መሆኑን ከ profiles ታብል ማረጋገጫ
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

  /// 3. አድሚን ብቻ ሆነው የ app_settings መረጃዎችን (Maintenance mode ወይም Announcement) ማሻሻል (Update)
  static Future<bool> updateAppSettings({
    required bool maintenanceMode,
    required String announcement,
  }) async {
    try {
      final isAdmin = await checkIfUserIsAdmin();
      if (!isAdmin) return false;

      // በመጀመሪያ ያለውን ረድፍ (Row) መታወቂያ (id) ለማግኘት
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
}
