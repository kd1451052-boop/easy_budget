import 'package:flutter/material.dart';
import 'home_page.dart';
import 'history_screen.dart';
import 'budget_page.dart';
import 'settings_page.dart';
import 'shared_scanner_fab.dart';
import 'add_transaction_screen.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'gamification_provider.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Tracks the active bottom-nav tab index and which tabs have been lazily built.
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0};
  late ConfettiController _confettiController;
  late AudioPlayer _audioPlayer;

  // Ordered list of the 5 primary tab screens in the bottom navigation bar.
  final List<Widget> _screens = const [
    HomePage(),
    HistoryScreen(),
    AddExpenseScreen(),
    BudgetPage(),
    SettingsPage(),
  ];

  // Initializes confetti & audio controllers and registers a callback on
  // GamificationProvider to play a celebration whenever an achievement unlocks.
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _audioPlayer = AudioPlayer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gamification = Provider.of<GamificationProvider>(
        context,
        listen: false,
      );
      gamification.onAchievementUnlocked = () {
        if (!mounted) return;
        _confettiController.play();
        _audioPlayer.play(AssetSource('sounds/tada.wav'));
      };
    });
  }

  // Disposes confetti and audio player controllers when the screen is destroyed.
  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Updates the active tab index and marks the tab as visited so IndexedStack builds it.
  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
  }

  // Builds the main app shell with lazy IndexedStack tabs, the receipt-scanner FAB,
  // the bottom navigation bar, and the top-aligned confetti overlay.
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: List.generate(
              _screens.length,
              (i) => _visitedTabs.contains(i)
                  ? _screens[i]
                  : const SizedBox.shrink(),
            ),
          ),
          floatingActionButton: _currentIndex != 4
              ? const SharedScannerFAB()
              : null,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onBottomNavTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF5442F5),
            unselectedItemColor: Colors.grey.shade400,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            elevation: 0,
            backgroundColor: Theme.of(context).cardColor,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF5442F5),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
                label: 'Add',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet),
                label: 'Budget',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
        // Confetti Overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }
}
