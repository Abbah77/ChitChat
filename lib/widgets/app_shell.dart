import 'package:flutter/material.dart';
import 'package:chitchat/widgets/dashboard_widgets/ai_companion.dart';
import 'package:chitchat/screens/dashboard.dart';
import 'package:chitchat/screens/chat_page.dart';

class AppShell extends StatefulWidget {
  final List<Widget> pages;
  
  const AppShell({
    super.key,
    required this.pages,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _showAICompanion = true;

  @override
  void initState() {
    super.initState();
    // Update to 6 pages since you added Videos tab
    if (widget.pages.length != 6) {
      throw AssertionError('Expected 6 pages for navigation');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Using IndexedStack instead of PageView
          IndexedStack(
            index: _currentIndex,
            children: widget.pages,
          ),
          // Show AI companion on specific pages
          if (_showAICompanion && _shouldShowAI(_currentIndex))
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 80,
              right: 20,
              child: const AICompanion(),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  bool _shouldShowAI(int index) {
    // Show AI on Home (0) and Chats (2) pages
    return index == 0 || index == 2;
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: 'Friends',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Chats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.video_library_outlined),
          label: 'Videos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
