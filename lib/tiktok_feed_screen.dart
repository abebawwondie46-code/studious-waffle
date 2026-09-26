import 'package:flutter/material.dart';
import 'poster_editor_screen.dart';

class TikTokFeedScreen extends StatefulWidget {
  const TikTokFeedScreen({Key? key}) : super(key: key);

  @override
  State<TikTokFeedScreen> createState() => _TikTokFeedScreenState();
}

class _TikTokFeedScreenState extends State<TikTokFeedScreen> {
  final PageController _pageController = PageController();

  // ለሙከራ የሚሆኑ የማስታወቂያ አብነቶች/ናሙናዎች
  final List<Map<String, dynamic>> _feedItems = [
    {
      "author": "@hibret_bank",
      "title": "የልጆችዎን ነገ ዛሬ ያሳምሩ",
      "color": const Color(0xFF1B5E20),
      "likes": "2.4k",
      "phone": "995"
    },
    {
      "author": "@ethio_tech",
      "title": "አዳዲስ የይዘት ፈጠራዎችን እዚህ ያግኙ",
      "color": const Color(0xFF0D47A1),
      "likes": "1.8k",
      "phone": "0911000000"
    },
    {
      "author": "@ethio_coffee",
      "title": "ምርጥ የሀበሻ ቡና በቅናሽ ዋጋ",
      "color": const Color(0xFF4E342E),
      "likes": "5.1k",
      "phone": "0912000000"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical, // ልክ እንደ ቲክቶክ ወደ ታች/ላይ የሚቀያየር
        controller: _pageController,
        itemCount: _feedItems.length,
        itemBuilder: (context, index) {
          final item = _feedItems[index];
          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. የማስታወቂያ/የፖስተር ማሳያ (Poster Container)
              Container(
                color: item["color"],
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      item["title"],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // 2. በስተቀኝ በኩል ያሉ ቁልፎች (Like, Remix, Share)
              Positioned(
                right: 16,
                bottom: 100,
                child: Column(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 38),
                    const SizedBox(height: 4),
                    Text(
                      item["likes"],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 24),

                    // === REMIX / EDIT BUTTON (ወደ ኤዲተር የሚወስድ) ===
                    GestureDetector(
                      onTap: () {
                        // ይህንን ዲዛይን ወስዶ ወደ ኤዲተሩ ገጽ ለመሄድ
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PosterEditorScreen(),
                          ),
                        );
                      },
                      child: const Column(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.amber,
                            radius: 24,
                            child: Icon(Icons.auto_awesome, color: Colors.black, size: 28),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Remix",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Icon(Icons.share, color: Colors.white, size: 32),
                    const SizedBox(height: 4),
                    const Text(
                      "Share",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // 3. በስተታች የሚቀመጥ መረጃ እና ደውል (Call to Action)
              Positioned(
                left: 16,
                bottom: 40,
                child: Column(
                  crossAxisAlignment: CrossAlignment.start,
                  children: [
                    Text(
                      item["author"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.phone, color: Colors.white),
                      label: Text(
                        "ይደውሉ: ${item["phone"]}",
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      // ወደ ኤዲተር ገጽ በቀጥታ መሄጃ የመደመር (+) ቁልፍ
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black, size: 32),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PosterEditorScreen(),
            ),
          );
        },
      ),
    );
  }
}
