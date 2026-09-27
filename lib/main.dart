import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ethio Content Hub',
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
  final String category; // ንግድ, ፖለቲካ, ዜና, ቪዲዮ, ጥቅስ
  final List<Color> gradientColors;
  final String? mediaUrl;
  int likes;
  int commentsCount;
  int views;
  bool isLiked;

  FeedItem({
    required this.id,
    required this.title,
    required this.username,
    required this.phoneNumber,
    required this.category,
    required this.gradientColors,
    this.mediaUrl,
    required this.likes,
    this.commentsCount = 0,
    this.views = 120,
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
      title: 'አዳዲስ የይዘት\nፈጠራዎችን እዚህ ያግኙ!',
      username: '@ethio_tech',
      phoneNumber: '0911000000',
      category: 'ቴክኖሎጂ',
      gradientColors: [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)],
      likes: 1800,
      commentsCount: 45,
      views: 3200,
    ),
    FeedItem(
      id: '2',
      title: 'የሀገራችን የፖለቲካ እና\nየኢኮኖሚ አዳዲስ መረጃዎች',
      username: '@ethio_politics',
      phoneNumber: '0922000000',
      category: 'ፖለቲካ',
      gradientColors: [const Color(0xFF3A1C71), const Color(0xFFD76D77), const Color(0xFFFFAF7B)],
      likes: 3400,
      commentsCount: 112,
      views: 8900,
    ),
    FeedItem(
      id: '3',
      title: 'ምርጥ የሀበሻ ቡና በቀናሽ\nዋጋ ይሸምቱ',
      username: '@ethio_coffee',
      phoneNumber: '0912000000',
      category: 'ንግድ',
      gradientColors: [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)],
      likes: 5100,
      commentsCount: 88,
      views: 12400,
    ),
  ];

  // Show Comments Modal
  void _showCommentsModal(FeedItem item) {
    final commentController = TextEditingController();
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
              Text(
                'አስተያየቶች (${item.commentsCount})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              const ListTile(
                leading: CircleAvatar(child: Text('A')),
                title: Text('@user1'),
                subtitle: Text('በጣም ደስ የሚል መረጃ ነው!'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        hintText: 'አስተያየት ይፃፉ...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.amber),
                    onPressed: () {
                      if (commentController.text.isNotEmpty) {
                        setState(() {
                          item.commentsCount++;
                        });
                        Navigator.pop(ctx);
                      }
                    },
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Bottom Sheet for Design & Post Creation
  void _showAddContentBottomSheet() {
    final titleController = TextEditingController();
    final usernameController = TextEditingController();
    final phoneController = TextEditingController();
    final mediaUrlController = TextEditingController();

    String selectedCategory = 'ንግድ';
    List<Color> selectedGradient = [const Color(0xFF11998E), const Color(0xFF38EF7D)];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'አዲስ ይዘት ያዘጋጁ እና ያጋሩ 🚀',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
                    ),
                    const SizedBox(height: 15),
                    
                    // Category Selection
                    const Text('ምድብ ይምረጡ:', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['ንግድ', 'ፖለቲካ', 'ዜና', 'ቪዲዮ', 'ጥቅስ', 'ቴክኖሎጂ'].map((cat) {
                        final isSelected = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: Colors.amber,
                          onSelected: (val) {
                            setModalState(() {
                              selectedCategory = cat;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: titleController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'መረጃ / ፅሁፍ / መልእክት',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'የተጠቃሚ ስም (ምሳሌ @my_brand)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'የስልክ ቁጥር (ከተፈለገ)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: mediaUrlController,
                      decoration: const InputDecoration(
                        labelText: 'የቪዲዮ ወይም የምስል ሊንክ (አማራጭ)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Publish Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                  category: selectedCategory,
                                  gradientColors: selectedGradient,
                                  mediaUrl: mediaUrlController.text.isEmpty
                                      ? null
                                      : mediaUrlController.text,
                                  likes: 0,
                                ),
                              );
                            });
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text(
                          'ለጥፍ (Publish)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: item.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Top Category Badge & Views
                Positioned(
                  top: 50,
                  left: 20,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber, width: 1),
                        ),
                        child: Text(
                          '# ${item.category}',
                          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye, size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text('${item.views}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Text / Content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0),
                    child: Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),

                // Right Interactive Actions
                Positioned(
                  right: 16,
                  bottom: 110,
                  child: Column(
                    children: [
                      // Like
                      IconButton(
                        iconSize: 34,
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
                      Text('${item.likes}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(height: 18),

                      // Comment
                      IconButton(
                        iconSize: 32,
                        icon: const Icon(Icons.comment, color: Colors.white),
                        onPressed: () => _showCommentsModal(item),
                      ),
                      Text('${item.commentsCount}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(height: 18),

                      // Remix
                      IconButton(
                        iconSize: 30,
                        icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                        onPressed: () {},
                      ),
                      const Text('Remix', style: TextStyle(color: Colors.white, fontSize: 11)),
                      const SizedBox(height: 18),

                      // Share
                      IconButton(
                        iconSize: 30,
                        icon: const Icon(Icons.share, color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ሊንኩ ተቀድቷል (Link Copied)')),
                          );
                        },
                      ),
                      const Text('Share', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),

                // Bottom Left User Info & Call Button
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
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                        label: Text(
                          'ይደውሉ: ${item.phoneNumber}',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('ደውል: ${item.phoneNumber}')),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Bottom Right Add (+ Button)
                Positioned(
                  right: 16,
                  bottom: 40,
                  child: FloatingActionButton(
                    backgroundColor: Colors.amber[700],
                    child: const Icon(Icons.add, color: Colors.black, size: 32),
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
