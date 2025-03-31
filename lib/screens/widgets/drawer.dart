import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import '../../../models/chat_session.dart';
import '../../../services/chat_service.dart';

class CustomDrawer extends StatelessWidget {
  final ChatService chatService;
  final Function(ChatSession) onSessionTap;

  const CustomDrawer({
    Key? key,
    required this.chatService,
    required this.onSessionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: SearchBar(),
            ),
            const Divider(),
            // Use StreamBuilder to listen to chat sessions
            Expanded(
              child: StreamBuilder<List<ChatSession>>(
                stream: chatService.sessions,
                initialData: chatService.getAllSessions(),
                builder: (context, snapshot) {
                  final sessions = snapshot.data ?? [];

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Close drawer
                          onSessionTap(session);
                        },
                        child: Text(
                          session.title ?? 'New Chat',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            const DrawerFooter(),
          ],
        ),
      ),
    );
  }
}

class SearchBar extends StatelessWidget {
  const SearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: const [
          Icon(Icons.search, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DrawerHistory extends StatelessWidget {
  const DrawerHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: const [
        Text('Today', style: TextStyle(color: Colors.grey, fontSize: 12)),
        SizedBox(height: 8),
        Text('How to manage my money', style: TextStyle(fontSize: 16)),
        SizedBox(height: 12),
        Text('What’s happening in stock market today', style: TextStyle(fontSize: 16)),
        SizedBox(height: 24),
        Text('2 days ago', style: TextStyle(color: Colors.grey, fontSize: 12)),
        SizedBox(height: 8),
        Text('Zomato stocks', style: TextStyle(fontSize: 16)),
      ],
    );
  }
}

class DrawerFooter extends StatelessWidget {
  const DrawerFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.blue,
            child: Text('R', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          const Text(
            'RGB',
            style: TextStyle(color: Colors.white),
          ),
          const Spacer(),
          const Icon(Icons.more_horiz, color: Colors.white),
        ],
      ),
    );
  }
}
