import 'package:flutter/material.dart';

class CommentsBottomSheet extends StatefulWidget {
  const CommentsBottomSheet({super.key});

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  
  // የናሙና ኮሜንቶች ዝርዝር (እስከሚገናኝ ድረስ)
  final List<Map<String, String>> _comments = [
    {
      'name': 'በቀለ',
      'comment': 'በጣም አሪፍ ማስታወቂያ ነው! ቀጥበት።',
      'time': '2 ደቂቃ በፊት',
    },
    {
      'name': 'ሰላማዊት',
      'comment': 'ይህን ምርት እንዴት ማግኘት እንችላለን?',
      'time': '10 ደቂቃ በፊት',
    },
  ];

  void _addComment() {
    if (_commentController.text.trim().isEmpty) return;
    setState(() {
      _comments.insert(0, {
        'name': 'እርስዎ',
        'comment': _commentController.text.trim(),
        'time': 'አሁን',
      });
      _commentController.clear();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65, // የስክሪኑን 65% እንዲሸፍን
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 1. የከፍታ መያዣ (Drag Handle) እና  തല ጽሁፍ
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'አስተያየቶች (Comments)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white24),

          // 2. የኮሜንቶች ዝርዝር (List of Comments)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final item = _comments[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.redAccent,
                        child: Text(
                          item['name']![0],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['name']!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  item['time']!,
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['comment']!,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 3. ከታች አዲስ ኮሜንት መጻፊያ ሳጥን (Comment Input Bar)
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8, // የኪቦርድ መሸፈኛ እንዳይኖር
            ),
            color: Colors.black54,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'አስተያየት ይስጡ...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[850],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.redAccent),
                  onPressed: _addComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
