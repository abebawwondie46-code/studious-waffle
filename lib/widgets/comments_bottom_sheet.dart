import 'package:flutter/material.dart';

class CommentsBottomSheet extends StatelessWidget {
  const CommentsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'አስተያየቶች (Comments)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.redAccent, child: Text('አ', style: TextStyle(color: Colors.white))),
                  title: Text('በቀለ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('በጣም አሪፍ ማስታወቂያ ነው! ቀጥበት።', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
