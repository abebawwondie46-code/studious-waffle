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
    {
      'name': 'ሳሙኤል',
      'comment': 'ሰላም፣ ይህ ሊንክ ይሰራል?',
      'time': '15 ደቂቃ በፊት',
    },
    {
      'name': 'ገነት',
      'comment': 'በጣም አሪፍ ነው!',
      'time': '1 ሰዓት በፊት',
    },
  ];

  // አዲስ ኮሜንት የመጨመር ተግባር (ለቁጥር ቆጠራ የተስተካከለ)
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
    // ኪቦርዱን መዝጋት
    FocusScope.of(context).unfocus();
  }

  // ኮሜንትን የመሰረዝ ተግባር
  void _deleteComment(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text('አስተያየትን ሰርዝ', style: TextStyle(color: Colors.white)),
          content: const Text('እርግጠኛ ነዎት ይህን አስተያየት መሰረዝ ይፈልጋሉ?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: const Text('አይ', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop(); // የመሰረዝ መስኮቱን መዝጋት
              },
            ),
            TextButton(
              child: const Text('አዎ፣ ሰርዝ', style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                setState(() {
                  _comments.removeAt(index); // ኮሜንቱን ከዝርዝሩ ማስወገድ
                });
                Navigator.of(context).pop(); // የመሰረዝ መስኮቱን መዝጋት
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // አጠቃላይ የኮሜንቶች ብዛት (ከምሳሌው ጋር እንዲመሳሰል 4 ተጀመረ)
    // ወደፊት ከዳታቤዝ እውነተኛውን ቁጥር ለማግኘት እዚህ ላይ መቀየር ይቻላል።
    final int baseCount = 745; 
    final int newComments = _comments.length;
    final int totalCommentCount = baseCount + newComments;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 1. የከፍታ መያዣ (Drag Handle) እና ርዕስ (ከብዛት ቆጠራ ጋር)
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
          Text(
            // የኮሜንቶች ብዛት በራስ-ሰር ይዘምናል
            'አስተያየቶች ($totalCommentCount)', 
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white24),

          // 2. የኮሜንቶች ዝርዝር (ረጅም ሲጫኑ ለመሰረዝ የተስተካከለ)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final item = _comments[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  // ረጅም ጊዜ ሲጫን (Long Press) የሚሰራ ተግባር
                  child: GestureDetector(
                    onLongPress: () {
                      _deleteComment(index);
                    },
                    child: Container(
                      color: Colors.transparent, // ለመንካት ምቹ እንዲሆን
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
                  ),
                );
              },
            ),
          ),

          // 3. ከታች አዲስ ኮሜንት መጻፊያ ሳጥን
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
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
                    // ኢንተር ሲጫን ኮሜንቱን ለመጨመር
                    onSubmitted: (_) => _addComment(),
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
