import 'package:flutter/material.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedTimeframe = "7 Days";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121217),
      appBar: AppBar(
        title: const Text("Creator Analytics", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF121217),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeframe Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "የይዘት አፈጻጸም (Overview)",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  dropdownColor: const Color(0xFF1E1E2C),
                  value: _selectedTimeframe,
                  style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold),
                  underline: Container(),
                  items: ["7 Days", "28 Days", "90 Days", "Total"].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedTimeframe = newValue!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Analytics Metric Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard("Total Views", "128.5K", "+12.4%", Icons.remove_red_eye_rounded, Colors.blue),
                _buildStatCard("Watch Time", "3.2K hrs", "+8.1%", Icons.timer_rounded, Colors.purple),
                _buildStatCard("Subscribers", "+1,240", "+15.3%", Icons.people_alt_rounded, Colors.green),
                _buildStatCard("Estimated Coins", "14,850", "+22.0%", Icons.monetization_on_rounded, Colors.amber),
              ],
            ),

            const SizedBox(height: 24),

            // Chart / Graphical Overview (Simulated Bar Visualizer)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAlignment.start,
                children: [
                  const Text(
                    "የዕይታዎች እድገት (Views Trend)",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 150,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBar("ሰኞ", 0.4),
                        _buildBar("ማክሰኞ", 0.7),
                        _buildBar("ረቡዕ", 0.5),
                        _buildBar("ሐሙስ", 0.9),
                        _buildBar("አርብ", 0.6),
                        _buildBar("ቅዳሜ", 0.8),
                        _buildBar("እሁድ", 1.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Top Performing Videos Section
            const Text(
              "ከፍተኛ ተወዳጅነት ያገኙ ቪዲዮዎች",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _buildVideoPerformanceTile("ቪዲዮ 1 - VibeShare AI Tutorial", "45.2K views", "98% Like Rate", Colors.pinkAccent),
            _buildVideoPerformanceTile("ቪዲዮ 2 - Funny Status Clips", "32.1K views", "95% Like Rate", Colors.blueAccent),
            _buildVideoPerformanceTile("ቪዲዮ 3 - Ethiopian Tech News", "18.4K views", "91% Like Rate", Colors.orangeAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String change, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(change, style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double heightFactor) {
    double height = double.parse(heightFactor.toString());
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 14,
          height: 100 * height,
          decoration: BoxDecoration(
            color: Colors.pinkAccent,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(day, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  Widget _buildVideoPerformanceTile(String title, String views, String likeRate, Color badgeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.play_arrow_rounded, color: badgeColor, size: 30),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("$views • $likeRate", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 16),
      ),
    );
  }
}
