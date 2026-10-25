import 'package:flutter/material.dart';
import 'package:kuanyngne/Chat/secret_chat_screen.dart';

class AdVideoItem extends StatelessWidget {
  final String? userAvatar; 
  final String? userName;    
  final String? creatorId;

  const AdVideoItem({
    super.key,
    this.userAvatar,
    this.userName,
    this.creatorId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SecretChatScreen(
                  receiverId: creatorId ?? 'unknown_id',
                  receiverName: userName ?? 'ተጠቃሚ',
                  receiverAvatarUrl: userAvatar,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blueAccent, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueAccent.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.fingerprint,
              color: Colors.blueAccent,
              size: 70,
            ),
          ),
        ),
      ),
    );
  }
}
