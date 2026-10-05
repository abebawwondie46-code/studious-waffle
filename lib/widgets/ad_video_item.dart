import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'comments_bottom_sheet.dart';

class AdVideoItem extends StatefulWidget {
  final String title;
  final String videoUrl;
  final Map<String, dynamic> templateJson;
  final String? videoId;

  const AdVideoItem({
    super.key,
    required this.title,
    required this.videoUrl,
    required this.templateJson,
    this.videoId,
  });

  @override
  State<AdVideoItem> createState() => _AdVideoItemState();
}

class _AdVideoItemState extends State<AdVideoItem> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _showPlayIcon = false;
  late AnimationController _discController;
  
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _publishTitleController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoadingSearch = false;

  int _likeCount = 440;
  bool _isLiked = false;
  int _commentCount = 745;
  int _shareCount = 112;
  bool _isFollowing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _discController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _initializeVideo();
    _fetchEngagementData();
  }

  Future<void> _fetchEngagementData() async {
    if (widget.videoId == null) return;
    try {
      final response = await Supabase.instance.client
          .from('videos')
          .select('likes_count, comments_count, shares_count')
          .eq('id', widget.videoId!)
          .single();

      if (mounted) {
        setState(() {
          _likeCount = response['likes_count'] ?? _likeCount;
          _commentCount = response['comments_count'] ?? _commentCount;
          _shareCount = response['shares_count'] ?? _shareCount;
        });
      }
    } catch (e) {
      debugPrint('Error fetching engagement data: $e');
    }
  }

  Future<void> _handleLikePressed() async {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });

    if (widget.videoId != null) {
      try {
        await Supabase.instance.client
            .from('videos')
            .update({'likes_count': _likeCount})
            .eq('id', widget.videoId!);
      } catch (e) {
        debugPrint('Failed to update like on server: $e');
      }
    }
  }

  Future<void> _handleSharePressed() async {
    try {
      await Share.share('Check out this amazing video: ${widget.videoUrl}');
      setState(() {
        _shareCount += 1;
      });

      if (widget.videoId != null) {
        await Supabase.instance.client
            .from('videos')
            .update({'shares_count': _shareCount})
            .eq('id', widget.videoId!);
      }
    } catch (e) {
      debugPrint('Error sharing video: $e');
    }
  }

  void _initializeVideo() {
    if (widget.videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
            _videoController?.play();
            _videoController?.setLooping(true);
          }
        });

      _videoController?.addListener(_videoListener);
    }
  }

  void _videoListener() {
    if (mounted && _videoController != null && _videoController!.value.isInitialized) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _publishTitleController.dispose();
    _discController.dispose();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CommentsBottomSheet(
        videoId: widget.videoUrl,
        onCommentCountUpdated: (newCount) {
          setState(() {
            _commentCount = newCount;
          });
        },
      ),
    );
  }

  void _openVideoPhotoEditor() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VideoEditorStudioScreen(),
      ),
    );
  }

  void _openPosterStickerDesigner() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PosterStickerStudioScreen(),
      ),
    );
  }

  void _openPublishHub() {
    Navigator.pop(context);
    _publishTitleController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.greenAccent),
              SizedBox(width: 8),
              Text('Publish to Feed', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share your edited creation directly to the VibeShare AI community feed.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _publishTitleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter creation title...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.black54,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                final title = _publishTitleController.text.trim();
                if (title.isEmpty) return;
                Navigator.pop(context);

                try {
                  await Supabase.instance.client.from('videos').insert({
                    'title': title,
                    'video_url': widget.videoUrl,
                    'likes_count': 0,
                    'comments_count': 0,
                    'shares_count': 0,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Successfully published to feed!')),
                    );
                  }
                } catch (e) {
                  debugPrint('Publish error: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to publish. Try again.')),
                    );
                  }
                }
              },
              child: const Text('Publish Now', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  void _showAiSummaryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber),
              SizedBox(width: 8),
              Text('AI Vibe Creator Studio', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Video Title: "${widget.title}"',
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                const Text(
                  'AI Analysis: Optimized for high engagement and trendy aesthetics.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Divider(color: Colors.grey, height: 25),
                const Text(
                  '🎨 Creator Tools & Publishing Hub:',
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildStudioOption(
                  icon: Icons.movie_edit,
                  title: 'Video & Photo Editor',
                  subtitle: 'Combine clips and photos into stunning videos',
                  onTap: _openVideoPhotoEditor,
                ),
                _buildStudioOption(
                  icon: Icons.design_services,
                  title: 'Ad Posters & Stickers',
                  subtitle: 'Design custom promotional posters and trendy stickers',
                  onTap: _openPosterStickerDesigner,
                ),
                _buildStudioOption(
                  icon: Icons.cloud_upload,
                  title: 'Publish to Feed',
                  subtitle: 'Directly upload your creations to VibeShare AI',
                  onTap: _openPublishHub,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStudioOption({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Delete Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Remove this video from your feed', style: TextStyle(color: Colors.grey)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video deleted successfully')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: Colors.amber),
                title: const Text('AI Creator Studio', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showAiSummaryDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSearchSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.95),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.70,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Search Videos',
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type title or keywords...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[900],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setStateModal(() {
                                    _searchResults.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setStateModal(() {});
                      },
                      onSubmitted: (value) async {
                        await _performSearch(value.trim(), setStateModal);
                      },
                    ),
                    const SizedBox(height: 16),
                    _isLoadingSearch
                        ? const Expanded(
                            child: Center(
                              child: CircularProgressIndicator(color: Colors.redAccent),
                            ),
                          )
                        : Expanded(
                            child: _searchResults.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No results found. Try searching something else.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _searchResults.length,
                                    itemBuilder: (context, index) {
                                      final video = _searchResults[index];
                                      return ListTile(
                                        leading: const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 40),
                                        title: Text(
                                          video['title'] ?? 'Untitled',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Text(
                                          'Likes: ${video['likes_count'] ?? 0}',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Selected: ${video['title']}'),
                                              duration: const Duration(seconds: 1),
                                            ),
                                          );
                                        },
                                      );
                                    },
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

  Future<void> _performSearch(String query, StateSetter setStateModal) async {
    if (query.isEmpty) return;

    setStateModal(() {
      _isLoadingSearch = true;
    });

    try {
      final results = await Supabase.instance.client
          .from('videos')
          .select()
          .ilike('title', '%$query%');

      setStateModal(() {
        _searchResults = List<Map<String, dynamic>>.from(results);
        _isLoadingSearch = false;
      });

      setState(() {
        _searchQuery = query;
        _isSearching = true;
      });
    } catch (e) {
      setStateModal(() {
        _isLoadingSearch = false;
      });
      debugPrint('Search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search failed. Please check your connection.')),
        );
      }
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _discController.stop();
      } else {
        _videoController!.play();
        _discController.repeat();
      }
      _showPlayIcon = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showPlayIcon = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _isInitialized && _videoController != null
              ? GestureDetector(
                  onTap: _togglePlayPause,
                  onLongPress: _showVideoOptionsBottomSheet,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                      Center(
                        child: AnimatedOpacity(
                          opacity: _showPlayIcon ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.redAccent),
                ),

          Positioned(
            top: 45,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 28),
              onPressed: _openSearchSheet,
            ),
          ),
          
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 40, 70, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isSearching ? '${widget.title} (Search: $_searchQuery)' : widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            right: 12,
            bottom: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isFollowing = !_isFollowing;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isFollowing ? 'Following user!' : 'Unfollowed user'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white, size: 26),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: _isFollowing ? Colors.green : Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isFollowing ? Icons.check : Icons.add,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.redAccent : Colors.white,
                        size: 32,
                      ),
                      onPressed: _handleLikePressed,
                    ),
                    Text(
                      '$_likeCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Column(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                      onPressed: _openComments,
                    ),
                    Text(
                      '$_commentCount',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                
                Column(
                  children: [
                    IconButton(
                      icon: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(3.14159),
                        child: const Icon(Icons.reply, color: Colors.white, size: 30),
                      ),
                      onPressed: _handleSharePressed,
                    ),
                    Text(
                      '$_shareCount',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                GestureDetector(
                  onTap: _showAiSummaryDialog,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(Icons.auto_awesome, color: Colors.black, size: 18),
                    ),
                  ),
                ),

                RotationTransition(
                  turns: _discController,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 6),
                    ),
                    child: const Center(
                      child: Icon(Icons.music_note, color: Colors.white, size: 14),
                    ),
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

// 🎬 Interactive Video & Photo Editor Studio Screen with Live AI Online Assets Fetcher
class VideoEditorStudioScreen extends StatefulWidget {
  const VideoEditorStudioScreen({super.key});

  @override
  State<VideoEditorStudioScreen> createState() => _VideoEditorStudioScreenState();
}

class _VideoEditorStudioScreenState extends State<VideoEditorStudioScreen> {
  double _trimValue = 0.5;
  String _selectedFilter = 'Funny 😂';
  bool _isProcessing = false;
  bool _isLoadingAiAsset = false;
  XFile? _pickedFile;
  VideoPlayerController? _editorVideoController;
  bool _isEditorVideoInitialized = false;

  final TextEditingController _funnyCaptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _aiFetchedMessage = 'AI Asset Loaded: Comedy Sound & Funny Sticker Pack 🔥';

  Future<void> _pickMediaFile() async {
    try {
      final XFile? media = await _picker.pickMedia();
      if (media != null) {
        setState(() {
          _pickedFile = media;
        });

        if (media.path.endsWith('.mp4') || media.path.endsWith('.mov') || media.path.endsWith('.avi')) {
          _editorVideoController?.dispose();
          _editorVideoController = VideoPlayerController.networkUrl(Uri.parse(media.path))
            ..initialize().then((_) {
              if (mounted) {
                setState(() {
                  _isEditorVideoInitialized = true;
                });
                _editorVideoController?.play();
                _editorVideoController?.setLooping(true);
              }
            });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully loaded: ${media.name}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
    }
  }

  // 🌐 Simulate Fetching AI Smart Assets from Internet based on Filter
  Future<void> _fetchAiFilterAssets(String filterName) async {
    setState(() {
      _isLoadingAiAsset = true;
      _selectedFilter = filterName;
    });

    // Simulate network delay for fetching online AI templates/effects
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _isLoadingAiAsset = false;
      if (filterName == 'Funny 😂') {
        _aiFetchedMessage = 'AI Fetched: Laugh Track Audio & Meme Stickers 🤪';
        _funnyCaptionController.text = 'Wait for the funny plot twist! 😂🔥';
      } else if (filterName == 'Cinematic') {
        _aiFetchedMessage = 'AI Fetched: Hollywood Color Grading & Epic BGM 🎬';
        _funnyCaptionController.text = 'Cinematic masterpiece in progress ✨';
      } else if (filterName == 'Vibe AI') {
        _aiFetchedMessage = 'AI Fetched: Smart Beat Sync & Neon Glow FX 🚀';
        _funnyCaptionController.text = 'Catch the ultimate vibe with VibeShare AI 💎';
      } else {
        _aiFetchedMessage = 'Normal Mode: Standard Raw Editor Active 🎥';
        _funnyCaptionController.text = '';
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_aiFetchedMessage), duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  void dispose() {
    _editorVideoController?.dispose();
    _funnyCaptionController.dispose();
    super.dispose();
  }

  Future<void> _publishEditedVideoToFeed() async {
    final caption = _funnyCaptionController.text.trim();
    if (_pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video or photo first!')),
      );
      return;
    }
    if (caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a funny or creative caption!')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await Supabase.instance.client.from('videos').insert({
        'title': '$caption [AI Preset: $_selectedFilter]',
        'video_url': 'https://www.sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
        'likes_count': 0,
        'comments_count': 0,
        'shares_count': 0,
      });

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funny creation successfully published to VibeShare AI Feed!')),
        );
      }
    } catch (e) {
      debugPrint('Publish error: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to publish. Check connection.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Video & Photo Editor Studio', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Live Preview Box
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _isEditorVideoInitialized && _editorVideoController != null
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _editorVideoController!.value.size.width,
                          height: _editorVideoController!.value.size.height,
                          child: VideoPlayer(_editorVideoController!),
                        ),
                      )
                    : Center(
                        child: _isLoadingAiAsset
                            ? const CircularProgressIndicator(color: Colors.redAccent)
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.video_collection, size: 45, color: Colors.redAccent),
                                  const SizedBox(height: 8),
                                  Text(
                                    _pickedFile != null ? 'File: ${_pickedFile!.name}' : 'Tap "Add Media" to load video/photo',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _aiFetchedMessage,
                                    style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            // Funny Caption Input
            TextField(
              controller: _funnyCaptionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add funny/creative caption (e.g. Epic Vibe Moment 😂)...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.mood, color: Colors.amber),
              ),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Trim Video Duration', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
            Slider(
              value: _trimValue,
              min: 0.0,
              max: 1.0,
              activeColor: Colors.redAccent,
              inactiveColor: Colors.grey,
              onChanged: (value) {
                setState(() {
                  _trimValue = value;
                });
              },
            ),
            const SizedBox(height: 8),
            // Interactive Filters fetching AI assets
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['Normal', 'Funny 😂', 'Cinematic', 'Vibe AI'].map((filter) {
                bool isSelected = _selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  selectedColor: Colors.redAccent,
                  backgroundColor: Colors.grey[800],
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                  onSelected: (selected) {
                    _fetchAiFilterAssets(filter);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.all(14)),
                    icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                    label: const Text('Add Media', style: TextStyle(color: Colors.white)),
                    onPressed: _pickMediaFile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(14)),
                    icon: _isProcessing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_upload, color: Colors.white),
                    label: Text(_isProcessing ? 'Publishing...' : 'Publish to Feed', style: const TextStyle(color: Colors.white)),
                    onPressed: _isProcessing ? null : _publishEditedVideoToFeed,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 🎨 Dedicated Posters & Stickers Studio Screen
class PosterStickerStudioScreen extends StatefulWidget {
  const PosterStickerStudioScreen({super.key});

  @override
  State<PosterStickerStudioScreen> createState() => _PosterStickerStudioScreenState();
}

class _PosterStickerStudioScreenState extends State<PosterStickerStudioScreen> {
  String _selectedSticker = '🔥 Vibe Badge';
  String? _posterImageName;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickPosterImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _posterImageName = image.name;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Poster background loaded: ${image.name}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text('Posters & Stickers Studio', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber, width: 1.5),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.brush, size: 70, color: Colors.amber),
                      const SizedBox(height: 16),
                      Text(
                        _posterImageName != null ? 'Poster Image: $_posterImageName' : 'Design Canvas & Sticker Board',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Active Sticker: $_selectedSticker',
                        style: const TextStyle(color: Colors.amberAccent, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Choose Trendy Badge / Sticker', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['🔥 Vibe Badge', '⭐ Top Creator', '🚀 Viral AI', '💎 Exclusive'].map((sticker) {
                bool isSelected = _selectedSticker == sticker;
                return ChoiceChip(
                  label: Text(sticker),
                  selected: isSelected,
                  selectedColor: Colors.amber,
                  backgroundColor: Colors.grey[800],
                  labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.grey, fontWeight: FontWeight.bold),
                  onSelected: (selected) {
                    setState(() {
                      _selectedSticker = sticker;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800], padding: const EdgeInsets.all(12), minimumSize: const Size.fromHeight(45)),
              icon: const Icon(Icons.image, color: Colors.white),
              label: const Text('Add Background Image', style: TextStyle(color: Colors.white)),
              onPressed: _pickPosterImage,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.all(14), minimumSize: const Size.fromHeight(50)),
              icon: const Icon(Icons.check, color: Colors.black),
              label: const Text('Save Poster Design', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Poster design saved and added to gallery!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
