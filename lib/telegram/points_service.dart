import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelegramPointsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// ተጠቃሚው አፑን ተጠቅሞ ሰዓት ሲያጠራቅም ወይም ነጥብ ሲያገኝ የሚጠራ ሎጂክ
  Future<void> addOrUpdateDailyPoints(String telegramId, String username, int sessionSeconds) async {
    try {
      // 1. መጀመሪያ ውድድሩ በሥራ ላይ መሆኑን ከ app_settings ማረጋገጥ
      final settingsResponse = await _supabase
          .from('app_settings')
          .select('is_competition_active')
          .maybeSingle();

      bool isCompetitionActive = settingsResponse?['is_competition_active'] ?? true;

      if (!isCompetitionActive) {
        debugPrint('ውድድሩ ስለጠፋ (OFF) ነጥብ መጨመር አይቻልም!');
        return;
      }

      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // 2. ተጠቃሚው ዳታቤዝ ውስጥ መኖሩን ማረጋገጥ
      final existingUser = await _supabase
          .from('user_points')
          .select()
          .eq('telegram_id', telegramId)
          .maybeSingle();

      if (existingUser != null) {
        String? lastDateStr = existingUser['last_active_date'];
        double currentPoints = (existingUser['points'] as num?)?.toDouble() ?? 0.01;
        int accumulatedSeconds = (existingUser['active_seconds'] as num?)?.toInt() ?? 0;

        // የቀን ቆጠራ እና የ Streak ንጽጽር
        if (lastDateStr != null) {
          DateTime lastActive = DateTime.parse(lastDateStr);
          final lastActiveDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
          final today = DateTime(now.year, now.month, now.day);
          int dayDifference = today.difference(lastActiveDay).inDays;

          if (dayDifference > 1) {
            // ከ 1 ቀን በላይ ካለፈ (ቀን ካልገባ) ነጥቡ እና ሰዓቱ ወደ 0.01 እና 0 ይመለሳሉ!
            currentPoints = 0.01;
            accumulatedSeconds = 0;
          } else if (dayDifference == 1 && lastDateStr != todayStr) {
            // አዲስ ቀን ጀምሯል (Streak ተጠብቋል) - ሰዓቱን ለአዲስ ቀን እናስተካክላለን
            accumulatedSeconds = 0;
          }
        }

        // በ 24 ሰዓት ውስጥ የተጠራቀመውን ሰዓት እንጨምራለን
        accumulatedSeconds += sessionSeconds;

        // 30 ደቂቃ (1800 ሰኮንድ) በ 24 ሰዓት ውስጥ ሞልቶ ከሆነ ነጥብ (0.01) ይጨምራል
        if (accumulatedSeconds >= 1800) {
          currentPoints += 0.01;
          accumulatedSeconds = 0; // ለቀጣይ 30 ደቂቃ እንደገና ይጀምራል
          debugPrint('30 ደቂቃ ተሞልቷል! 0.01 ነጥብ ተጨምሯል።');
        }

        await _supabase.from('user_points').update({
          'points': currentPoints,
          'active_seconds': accumulatedSeconds,
          'last_active_date': todayStr,
          'username': username,
        }).eq('telegram_id', telegramId);

        debugPrint('ነጥብ እና ሰዓት ተዘምኗል! አጠቃላይ ነጥብ: $currentPoints');
      } else {
        // አዲስ ተጠቃሚ ከሆነ በ 0.01 ነጥብ እንጀምራለን
        await _supabase.from('user_points').insert({
          'telegram_id': telegramId,
          'username': username,
          'points': 0.01,
          'active_seconds': sessionSeconds,
          'last_active_date': todayStr,
        });

        debugPrint('አዲስ ተጠቃሚ በ 0.01 ነጥብ ተመዝግቧል!');
      }
    } catch (e) {
      debugPrint('የነጥብ እና ሰዓት ማሻሻያ ስህተት: $e');
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
