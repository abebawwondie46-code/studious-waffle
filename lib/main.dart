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
  final String category;
  final List<Color> gradientColors;
  final String? mediaFileName;
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
    this.mediaFileName,
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
      commentsCount: 48,
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

  void _showAddContentBottomSheet() {
    final titleController = TextEditingController();
    final usernameController = TextEditingController();
    final phoneController = TextEditingController();

    String selectedCategory = 'ንግድ';
    String? selectedFileName;
    
    // Preset Gradient Themes
    final List<List<Color>> gradientPresets = [
      [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)],
      [const Color(0xFF3A1C71), const Color(0xFFD76D77), const Color(0xFFFFAF7B)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      [const Color(0xFF2C3E50), const Color(0xFF000000)],
    ];
    List<Color> selectedGradient = gradientPresets[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181818),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'አዲስ ይዘት ያዘጋጁ እና ያጋሩ 🚀',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(ctx),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Category Selection
                    const Text('ምድብ ይምረጡ:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['ንግድ', 'ፖለቲካ', 'ዜና', 'ቪዲዮ', 'ጥቅስ', 'ቴክኖሎጂ'].map((cat) {
                        final isSelected = selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.amber,
                          backgroundColor: const Color(0xFF2A2A2A),
                          onSelected: (val) {
                            setModalState(() {
                              selectedCategory = cat;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Theme Color Selection
                    const Text('የጀርባ ቀለም ዲዛይን ይምረጡ:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: gradientPresets.map((gradient) {
                        final isSelected = selectedGradient == gradient;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedGradient = gradient;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: gradient),
                              border: Border.all(
                                color: isSelected ? Colors.amber : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 18, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Inputs
                    TextField(
                      controller: titleController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.description, color: Colors.amber),
                        labelText: 'መረጃ / ፅሁፍ / መልእክት',
                        filled: true,
                        fillColor: const Color(0xFF242424),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.alternate_email, color: Colors.amber),
                        labelText: 'የተጠቃሚ ስም (ምሳሌ @my_brand)',
                        filled: true,
                        fillColor: const Color(0xFF242424),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone, color: Colors.amber),
                        labelText: 'የስልክ ቁጥር (ከተፈለገ)',
                        filled: true,
                        fillColor: const Color(0xFF242424),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Upload Video / Media Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(color: Colors.amber, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.video_library, color: Colors.amber),
                      label: Text(
                        selectedFileName ?? 'ቪዲዮ ወይም ምስል ይምረጡ (Upload Media)',
                        style: const TextStyle(color: Colors.amber),
                      ),
                      onPressed: () {
                        setModalState(() {
                          selectedFileName = "my_video_sample.mp4";
                        });
                      },
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
                                  mediaFileName: selectedFileName,
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        if (item.mediaFileName != null) ...[
                          const SizedBox(height: 15),
                          Chip(
                            avatar: const Icon(Icons.play_circle_fill, color: Colors.amber),
                            label: Text(item.mediaFileName!),
                            backgroundColor: Colors.black54,
                          )
                        ]
                      ],
                    ),
                  ),
                ),

                // Right Interactive Actions
                Positioned(
                  right: 16,
                  bottom: 110,
                  child: Column(
                    children: [
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

                      IconButton(
                        iconSize: 32,
                        icon: const Icon(Icons.comment, color: Colors.white),
                        onPressed: () => _showCommentsModal(item),
                      ),
                      Text('${item.commentsCount}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                      const SizedBox(height: 18),

                      IconButton(
                        iconSize: 30,
                        icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                        onPressed: () {},
                      ),
                      const Text('Remix', style: TextStyle(color: Colors.white, fontSize: 11)),
                      const SizedBox(height: 18),

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
