import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vertical Feed App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const FeedScreen(),
    );
  }
}

class FeedItem {
  final String id;
  final String title;
  final String username;
  final String phoneNumber;
  final Color backgroundColor;
  int likes;
  bool isLiked;

  FeedItem({
    required this.id,
    required this.title,
    required this.username,
    required this.phoneNumber,
    required this.backgroundColor,
    required this.likes,
    this.isLiked = false,
  });
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<FeedItem> _feedItems = [
    FeedItem(
      id: '1',
      title: 'አዳዲስ የይዘት\nፈጠራዎችን እዚህ ያግኙ',
      username: '@ethio_tech',
      phoneNumber: '0911000000',
      backgroundColor: const Color(0xFF1565C0),
      likes: 1800,
    ),
    FeedItem(
      id: '2',
      title: 'የልጆችዎን ነገ ዛሬ ያሳምሩ',
      username: '@hibret_bank',
      phoneNumber: '995',
      backgroundColor: const Color(0xFF1B5E20),
      likes: 2400,
    ),
    FeedItem(
      id: '3',
      title: 'ምርጥ የሀበሻ ቡና በቀናሽ\nዋጋ',
      username: '@ethio_coffee',
      phoneNumber: '0912000000',
      backgroundColor: const Color(0xFF4E342E),
      likes: 5100,
    ),
  ];

  // Call launcher function
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  // Bottom sheet for adding new content
  void _showAddContentBottomSheet() {
    final titleController = TextEditingController();
    final usernameController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'አዲስ ይዘት ፍጠር',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'ፅሁፍ / መልእክት',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'የተጠቃሚ ስም (उदा. @my_brand)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'የስልክ ቁጥር',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[700],
                  ),
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      setState(() {
                        _feedItems.insert(
                          0,
                          FeedItem(
                            id: DateTime.now().toString(),
                            title: titleController.text,
                            username: usernameController.text.isEmpty
                                ? '@user'
                                : usernameController.text,
                            phoneNumber: phoneController.text.isEmpty
                                ? '0900000000'
                                : phoneController.text,
                            backgroundColor: Colors.deepPurple,
                            likes: 0,
                          ),
                        );
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('ለጥፍ (Publish)', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _feedItems.length,
        itemBuilder: (context, index) {
          final item = _feedItems[index];
          return Container(
            color: item.backgroundColor,
            child: Stack(
              children: [
                // Main Content Text
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),

                // Right Action Buttons
                Positioned(
                  right: 16,
                  bottom: 120,
                  child: Column(
                    children: [
                      // Like Button
                      IconButton(
                        iconSize: 36,
                        icon: Icon(
                          item.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: item.isLiked ? Colors.red : Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            item.isLiked = !item.isLiked;
                            item.isLiked ? item.likes++ : item.likes--;
                          });
                        },
                      ),
                      Text(
                        '${item.likes}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(height: 20),

                      // Remix Button
                      IconButton(
                        iconSize: 32,
                        icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Remix Feature Selected')),
                          );
                        },
                      ),
                      const Text(
                        'Remix',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(height: 20),

                      // Share Button
                      IconButton(
                        iconSize: 32,
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: () {},
                      ),
                      const Text(
                        'Share',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Bottom Left Username & Call Button
                Positioned(
                  left: 16,
                  bottom: 40,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.phone, color: Colors.white),
                        label: Text(
                          'ይደውሉ: ${item.phoneNumber}',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                        onPressed: () => _makePhoneCall(item.phoneNumber),
                      ),
                    ],
                  ),
                ),

                // Floating Plus Button (Add New Post)
                Positioned(
                  right: 16,
                  bottom: 40,
                  child: FloatingActionButton(
                    backgroundColor: Colors.amber[700],
                    child: const Icon(Icons.add, color: Colors.black, size: 30),
                    onPressed: _showAddContentBottomSheet,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
