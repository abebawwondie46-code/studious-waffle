import 'package:supabase_flutter/supabase_flutter.dart';

class TelegramPointsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ተጠቃሚው ነጥብ እንዲኖረው ወይም ነጥቡ እንዲጨምር የሚያደርግ ሎጂክ
  Future<void> addPoints(String telegramId, String username, int pointsToAdd) async {
    try {
      // ተጠቃሚው ቀድሞውኑ በዳታቤዝ ውስጥ መኖሩን ማረጋገጥ
      final existingUser = await _supabase
          .from('user_points')
          .select()
          .eq('telegram_id', telegramId)
          .maybeSingle();

      if (existingUser != null) {
        // ካለ ነባሩን ነጥብ ማሻሻል (Update)
        int currentPoints = existingUser['points'] ?? 0;
        int newPoints = currentPoints + pointsToAdd;

        await _supabase.from('user_points').update({
          'points': newPoints,
          'username': username,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('telegram_id', telegramId);
      } else {
        // አዲስ ተጠቃሚ ከሆነ ማስገባት (Insert)
        // ማስታወሻ: id UUID ስለሚጠይቅ አዲስ መነሻ id ማመንጨት ይቻላል ወይም auth.users ማያያዝ ይቻላል።
        // ለቴሌግራም ቦት በሚመች መልኩ አዲስ ሮው ማስገባት፦
        await _supabase.from('user_points').insert({
          'telegram_id': telegramId,
          'username': username,
          'points': pointsToAdd,
        });
      }
    } catch (e) {
      print('የነጥብ ማሻሻያ ስህተት: $e');
    }
  }

  // የሊደርቦርድ (Leaderboard) ከፍተኛ ነጥብ ያላቸውን ተጠቃሚዎች ማምጣት
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final response = await _supabase
          .from('user_points')
          .select()
          .order('points', ascending: false)
          .limit(10);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('ሊደርቦርድ ማምጣት አልተቻለም: $e');
      return [];
    }
  }
}
