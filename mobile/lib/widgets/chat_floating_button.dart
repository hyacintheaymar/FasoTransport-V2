import 'package:flutter/material.dart';
import 'package:fasotransport_mobile/screens/chat/chat_screen.dart';
import 'package:fasotransport_mobile/theme/app_theme.dart';

class ChatFloatingButton extends StatelessWidget {
  const ChatFloatingButton({super.key});

  void _openChatScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _openChatScreen(context),
      backgroundColor: AppColors.orange,
      icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      label: const Text('Chat', style: TextStyle(color: Colors.white)),
    );
  }
}
