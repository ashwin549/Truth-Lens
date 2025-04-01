import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'daily_tab.dart';

import 'profile_tab.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    HomeTab(),
    DailyTab(),
    ProfileTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final _pageController = PageController(initialPage: 0);

  /// Controller to handle bottom nav bar and also handles initial page

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white, // This will be the color behind the curve
        color: Colors.blue.shade100, // This is the color of the main bar
        buttonBackgroundColor: Colors.white,
        items: <Widget>[
          Icon(Icons.home, size: 30),
          Icon(Icons.trending_up, size: 30),
          Icon(Icons.person, size: 30),
        ],
        onTap: (index) {
          // Handle button tap
          setState(() {
            _selectedIndex = index;
          });
        },
        height: 50.0,
      ),
      body: _tabs[_selectedIndex],
    )
    ;
  }
}