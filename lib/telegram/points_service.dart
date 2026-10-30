import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelegramPointsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ተጠቃሚው ነጥብ እንዲኖረው ወይም ነጥቡ እንዲጨምር የሚያደርግ ሎጂክ (የውድድር ሁኔታን የሚቆጣጠር)
  Future<void> addPoints(String telegramId, String username, int pointsToAdd) async {
    try {
      // 1. መጀመሪያ ውድድሩ በሥራ ላይ መሆኑን (is_competition_active) ከ app_settings ማረጋገጥ
      final settingsResponse = await _supabase
          .from('app_settings')
          .select('is_competition_active')
          .maybeSingle();

      bool isCompetitionActive = settingsResponse?['is_competition_active'] ?? true;

      // ውድድሩ ኦፍ (OFF) ከሆነ ነጥብ መጨመር ፈጽሞ የተከለከለ ነው!
      if (!isCompetitionActive) {
        debugPrint('ውድድሩ ስለጠፋ (OFF) ነጥብ መጨመር አይቻልም!');
        return;
      }

      // 2. ተጠቃሚው ቀድሞውኑ በዳታቤዝ ውስጥ መኖሩን ማረጋገጥ
      final existingUser = await _supabase
          .from('user_points')
          .select()
          .eq('telegram_id', telegramId)
          .maybeSingle();

      if (existingUser != null) {
        // ካለ ነባሩን ነጥብ ማሻሻል (Update)
        int currentPoints = (existingUser['points'] as num?)?.toInt() ?? 0;
        int newPoints = currentPoints + pointsToAdd;

        await _supabase.from('user_points').update({
          'points': newPoints,
          'username': username,
        }).eq('telegram_id', telegramId);
        
        debugPrint('በተሳካ ሁኔታ ነጥብ ተዘምኗል! አጠቃላይ ነጥብ: $newPoints');
      } else {
        // አዲስ ተጠቃሚ ከሆነ ማስገባት (Insert)
        await _supabase.from('user_points').insert({
          'telegram_id': telegramId,
          'username': username,
          'points': pointsToAdd,
        });
        
        debugPrint('አዲስ ተጠቃሚ ተመዝግቦ ነጥብ ተሰጥቷል!');
      }
    } catch (e) {
      debugPrint('የነጥብ ማሻሻያ ስህተት: $e');
    }
  }

  // የሊደርቦርድ (Leaderboard) ከፍተኛ ነጥብ ያላቸውን ተጠቃሚዎች ማምጣት
  Future<List>> getLeaderboard() async {
    try {
      final response = await _supabase
          .from('user_points')
          .select()
          .order('points', ascending: false)
          .limit(10);
      
      return List>.from(response);
    } catch (e) {
      debugPrint('ሊደርቦርድ ማምጣት አልተቻለም: $e');
      return [];
    }
  }
}
