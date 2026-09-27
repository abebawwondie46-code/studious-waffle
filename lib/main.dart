import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

enum MediaType { none, image, video }

class FeedItem {
  final String id;
  final String title;
  final String username;
  final String phoneNumber;
  final String category;
  final List<Color> gradientColors;
  final String? mediaPath;
  final MediaType mediaType;
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
    this.mediaPath,
    this.mediaType = MediaType.none,
    required this.likes,
    this.commentsCount = 0,
    this.views = 120,
    this.isLiked = false,
  });
}

class CategoryData {
  final String title;
  final IconData icon;

  const CategoryData(this.title, this.icon);
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<FeedItem> _allFeedItems = [
    FeedItem(
      id: '1',
      title: 'አዳዲስ የይዘት ፈጠራዎችን እና የቴክኖሎጂ መረጃዎችን እዚህ ያግኙ!',
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
      title: 'የሀገራችን የፖለቲካ እና የኢኮኖሚ አዳዲስ መረጃዎች',
      username: '@ethio_politics',
      phoneNumber: '0922000000',
      category: 'ፖለቲካ',
      gradientColors: [const Color(0xFF3A1C71), const Color(0xFFD76D77), const Color(0xFFFFAF7B)],
      likes: 3400,
      commentsCount: 112,
      views: 8900,
    ),
  ];

  final List<CategoryData> _categories = const [
    CategoryData('ሁሉም', Icons.grid_view_rounded),
    CategoryData('ንግድ', Icons.shopping_bag_rounded),
    CategoryData('ፖለቲካ', Icons.gavel_rounded),
    CategoryData('ዜና', Icons.newspaper_rounded),
    CategoryData('ቪዲዮ', Icons.play_circle_fill_rounded),
    CategoryData('ጥቅስ', Icons.format_quote_rounded),
    CategoryData('ቴክኖሎጂ', Icons.memory_rounded),
  ];

  String _selectedCategoryFilter = 'ሁሉም';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<FeedItem> get _filteredFeedItems {
    return _allFeedItems.where((item) {
      final matchesCategory = _selectedCategoryFilter == 'ሁሉም' || item.category == _selectedCategoryFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.username.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _confirmDeletePost(FeedItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF222222),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('ፖስቱን ማጥፋት', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text('ይህንን ፖስት ማጥፋት እርግጠኛ ነዎት?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ተው', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                _allFeedItems.removeWhere((element) => element.id == item.id);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ፖስቱ ተሰርዟል!')),
              );
            },
            child: const Text('ሰርዝ (Delete)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ስልክ መደወል አልተቻለም: $phoneNumber')),
        );
      }
    }
  }

  void _shareContent(FeedItem item) {
    String shareText = item.title;
    if (item.username.isNotEmpty) {
      shareText += '\n\nተጋሪ: ${item.username}';
    }
    if (item.phoneNumber.isNotEmpty) {
      shareText += ' | ስልክ: ${item.phoneNumber}';
    }
    Share.share(shareText);
  }

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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
              const SizedBox(height: 15),
              const ListTile(
                leading: CircleAvatar(backgroundColor: Colors.amber, child: Text('A', style: TextStyle(color: Colors.black))),
                title: Text('@user1', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('በጣም ደስ የሚል መረጃ ነው!'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'አስተያየት ይፃፉ...',
                        filled: true,
                        fillColor: const Color(0xFF2C2C2C),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
    String? selectedFilePath;
    MediaType selectedMediaType = MediaType.none;

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
            
            Future<void> pickMedia() async {
              final ImagePicker picker = ImagePicker();
              
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF222222),
                builder: (context) => Wrap(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.video_library, color: Colors.amber),
                      title: const Text('ቪዲዮ ይምረጡ (Video)'),
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? media = await picker.pickVideo(source: ImageSource.gallery);
                        if (media != null) {
                          setModalState(() {
                            selectedFilePath = media.path;
                            selectedMediaType = MediaType.video;
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.image, color: Colors.amber),
                      title: const Text('ምስል/ፎቶ ይምረጡ (Image)'),
                      onTap: () async {
                        Navigator.pop(context);
                        final XFile? media = await picker.pickImage(source: ImageSource.gallery);
                        if (media != null) {
                          setModalState(() {
                            selectedFilePath = media.path;
                            selectedMediaType = MediaType.image;
                          });
                        }
                      },
                    ),
                  ],
                ),
              );
            }

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
                    
                    const Text('ምድብ ይምረጡ:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.where((c) => c.title != 'ሁሉም').map((cat) {
                        final isSelected = selectedCategory == cat.title;
                        return ChoiceChip(
                          avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.black : Colors.amber),
                          label: Text(
                            cat.title,
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
                              selectedCategory = cat.title;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

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

                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(color: Colors.amber, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.perm_media, color: Colors.amber),
                      label: Text(
                        selectedFilePath != null
                            ? 'ተመርጧል: ${selectedFilePath!.split('/').last}'
                            : 'ቪዲዮ ወይም ምስል ይምረጡ (Upload Media)',
                        style: const TextStyle(color: Colors.amber),
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: pickMedia,
                    ),
                    const SizedBox(height: 20),

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
                          final inputUsername = usernameController.text.trim();
                          final inputPhone = phoneController.text.trim();
                          final inputTitle = titleController.text.trim();

                          if (inputTitle.isNotEmpty || selectedFilePath != null) {
                            String finalUsername = inputUsername.isEmpty ? '@user_ethio' : inputUsername;
                            if (!finalUsername.startsWith('@')) {
                              finalUsername = '@$finalUsername';
                            }

                            setState(() {
                              _allFeedItems.insert(
                                0,
                                FeedItem(
                                  id: DateTime.now().toString(),
                                  title: inputTitle,
                                  username: finalUsername,
                                  phoneNumber: inputPhone,
                                  category: selectedCategory,
                                  gradientColors: selectedGradient,
                                  mediaPath: selectedFilePath,
                                  mediaType: selectedMediaType,
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
    final itemsToDisplay = _filteredFeedItems;

    return Scaffold(
      body: Stack(
        children: [
          itemsToDisplay.isEmpty
              ? const Center(
                  child: Text(
                    'ምንም የተገኘ ይዘት የለም!',
                    style: TextStyle(fontSize: 16, color: Colors.white60),
                  ),
                )
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: itemsToDisplay.length,
                  itemBuilder: (context, index) {
                    final item = itemsToDisplay[index];
                    return FeedCardItem(
                      item: item,
                      onLike: () {
                        setState(() {
                          item.isLiked = !item.isLiked;
                          item.isLiked ? item.likes++ : item.likes--;
                        });
                      },
                      onComment: () => _showCommentsModal(item),
                      onShare: () => _shareContent(item),
                      onCall: () => _makePhoneCall(item.phoneNumber),
                      onAdd: _showAddContentBottomSheet,
                      onDelete: () => _confirmDeletePost(item),
                    );
                  },
                ),

          // Header Search Bar & Category Chips with Icons
          Positioned(
            top: 45,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(fontSize: 14, color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'በፅሁፍ ወይም በስም ፈልግ...',
                                  hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val;
                                  });
                                },
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                                child: const Icon(Icons.close, color: Colors.grey, size: 18),
                              )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategoryFilter == cat.title;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          avatar: Icon(cat.icon, size: 16, color: isSelected ? Colors.black : Colors.amber),
                          label: Text(
                            cat.title,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.amber,
                          backgroundColor: Colors.black.withOpacity(0.5),
                          onSelected: (val) {
                            setState(() {
                              _selectedCategoryFilter = cat.title;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FeedCardItem extends StatefulWidget {
  final FeedItem item;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onCall;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  const FeedCardItem({
    super.key,
    required this.item,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onCall,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  State<FeedCardItem> createState() => _FeedCardItemState();
}

class _FeedCardItemState extends State<FeedCardItem> {
  VideoPlayerController? _videoController;
  bool _isMuted = false;
  bool _showPlayPauseOverlay = false;
  bool _isCurrentlyPlaying = true;

  @override
  void initState() {
    super.initState();
    if (widget.item.mediaType == MediaType.video && widget.item.mediaPath != null) {
      _videoController = VideoPlayerController.file(File(widget.item.mediaPath!))
        ..initialize().then((_) {
          setState(() {
            _isCurrentlyPlaying = true;
          });
          _videoController!.setLooping(true);
          _videoController!.play();
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final isPlaying = _videoController!.value.isPlaying;
      setState(() {
        if (isPlaying) {
          _videoController!.pause();
          _isCurrentlyPlaying = false;
        } else {
          _videoController!.play();
          _isCurrentlyPlaying = true;
        }
        _showPlayPauseOverlay = true;
      });

      if (_isCurrentlyPlaying) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _showPlayPauseOverlay = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final bool hasMedia = item.mediaType != MediaType.none && item.mediaPath != null;

    return GestureDetector(
      onTap: _togglePlayPause,
      onLongPress: widget.onDelete,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: item.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background Video Player
            if (item.mediaType == MediaType.video && _videoController != null && _videoController!.value.isInitialized)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
              )
            // Background Image
            else if (item.mediaType == MediaType.image && item.mediaPath != null)
              SizedBox.expand(
                child: Image.file(
                  File(item.mediaPath!),
                  fit: BoxFit.cover,
                ),
              ),

            // Subtle Gradient Overlay
            if (hasMedia)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black38, Colors.transparent, Colors.black54],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

            // Play / Pause Overlay Icon
            if (!_isCurrentlyPlaying || _showPlayPauseOverlay)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Icon(
                    _isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                    size: 50,
                    color: Colors.amber,
                  ),
                ),
              ),

            // Views Counter Badge
            Positioned(
              top: 100,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.remove_red_eye, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${item.views}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),

            // Text Only Card (When No Media Uploaded)
            if (!hasMedia && item.title.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Text(
                            '# ${item.category}',
                            style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Interactive Video Progress Timeline Indicator
            if (item.mediaType == MediaType.video && _videoController != null && _videoController!.value.isInitialized)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _videoController!,
                  allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Colors.amber,
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ),

            // Right Action Buttons
            Positioned(
              right: 16,
              bottom: 110,
              child: Column(
                children: [
                  if (item.mediaType == MediaType.video) ...[
                    IconButton(
                      iconSize: 28,
                      icon: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        color: _isMuted ? Colors.amber : Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          _isMuted = !_isMuted;
                          _videoController?.setVolume(_isMuted ? 0 : 1);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  IconButton(
                    iconSize: 32,
                    icon: Icon(
                      item.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: item.isLiked ? Colors.red : Colors.white,
                    ),
                    onPressed: widget.onLike,
                  ),
                  Text('${item.likes}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(height: 16),

                  IconButton(
                    iconSize: 30,
                    icon: const Icon(Icons.comment, color: Colors.white),
                    onPressed: widget.onComment,
                  ),
                  Text('${item.commentsCount}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  const SizedBox(height: 16),

                  // TikTok Style Curved Share Arrow Icon
                  IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.shortcut_rounded, color: Colors.white),
                    onPressed: widget.onShare,
                  ),
                  const Text('Share', style: TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),

            // Clean Bottom Left Content Details
            Positioned(
              left: 16,
              right: 90,
              bottom: 35,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '# ${item.category}',
                      style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title Overlay
                  if (hasMedia && item.title.isNotEmpty)
                    Text(
                      item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        shadows: [
                          Shadow(blurRadius: 10, color: Colors.black, offset: Offset(1, 1)),
                          Shadow(blurRadius: 10, color: Colors.black, offset: Offset(-1, -1)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Username
                  if (item.username.isNotEmpty)
                    Text(
                      item.username,
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)],
                      ),
                    ),
                  
                  // Phone Call Button
                  if (item.phoneNumber.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      icon: const Icon(Icons.phone, color: Colors.white, size: 16),
                      label: Text(
                        'ይደውሉ: ${item.phoneNumber}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      onPressed: widget.onCall,
                    ),
                  ],
                ],
              ),
            ),

            // Bottom Right Floating Add Button (+ Button)
            Positioned(
              right: 16,
              bottom: 35,
              child: FloatingActionButton(
                mini: false,
                backgroundColor: Colors.amber[700],
                onPressed: widget.onAdd,
                child: const Icon(Icons.add, color: Colors.black, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
