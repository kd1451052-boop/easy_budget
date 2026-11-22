import 'package:flutter/material.dart';
import 'home_page.dart';
import 'history_screen.dart';
import 'budget_page.dart';
import 'settings_page.dart';
import 'shared_scanner_fab.dart';
import 'add_transaction_screen.dart';
import 'b_and_s_history_page.dart';
import 'history.dart';
import 'transaction_provider.dart';
import 'settings_provider.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'gamification_provider.dart';
import 'update_notifier.dart';

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
  AudioPlayer? _audioPlayer;
  TransactionProvider? _txProvider;
  bool _isShowingGoalReachedDialog = false;

  // Ordered list of the 5 primary tab screens in the bottom navigation bar.
  final List<Widget> _screens = const [
    HomePage(),
    HistoryScreen(),
    AddExpenseScreen(),
    BudgetPage(),
    SettingsPage(),
  ];

  // Initializes confetti controller, registers achievement celebration callbacks,
  // and listens for newly reached saving goals to display the "Goal Reached!" popup.
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final gamification = Provider.of<GamificationProvider>(
        context,
        listen: false,
      );
      gamification.onAchievementUnlocked = _playCelebrationEffects;

      _txProvider = Provider.of<TransactionProvider>(context, listen: false);
      _txProvider!.addListener(_onTransactionProviderChanged);
      _checkAndShowGoalReachedPopup();
      UpdateNotifier.checkAndShowWhatsNew(context);
    });
  }

  // Plays confetti and celebration audio when an achievement or saving goal is reached.
  void _playCelebrationEffects() {
    if (!mounted) return;
    try {
      _confettiController.play();
    } catch (e) {
      debugPrint('Confetti play error: $e');
    }
    try {
      _audioPlayer ??= AudioPlayer();
      _audioPlayer!
          .play(AssetSource('sounds/tada.wav'))
          .catchError((Object e) => debugPrint('Audio play error: $e'));
    } catch (e) {
      debugPrint('Audio init error: $e');
    }
  }

  // Listener callback triggered whenever TransactionProvider updates.
  void _onTransactionProviderChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkAndShowGoalReachedPopup();
    });
  }

  // Consumes any newly reached saving goal from TransactionProvider and displays
  // the "Goal Reached!" celebration dialog, informing the user that the reached goal
  // has been removed from active saving goals and posted to B&S History.
  Future<void> _checkAndShowGoalReachedPopup() async {
    if (_isShowingGoalReachedDialog || !mounted) return;
    final provider = _txProvider;
    if (provider == null) return;

    final reachedGoal = provider.consumeNewlyReachedGoal();
    if (reachedGoal == null) return;

    _isShowingGoalReachedDialog = true;
    _playCelebrationEffects();

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final currency = settings.currencySymbol;
    final savedAmount = provider.getSavedAmountForGoal(reachedGoal);
    final formattedSaved =
        '$currency${settings.formatAmount(savedAmount >= reachedGoal.amount ? savedAmount : reachedGoal.amount)}';
    final formattedTarget =
        '$currency${settings.formatAmount(reachedGoal.amount)}';

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFF10B981),
                  size: 40,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Goal Reached! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SafeProductImage(
                        imageUrl: reachedGoal.productImageUrl,
                        width: 56,
                        height: 56,
                        cacheWidth: 140,
                        fallback: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.savings_rounded,
                            color: Color(0xFF10B981),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reachedGoal.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (reachedGoal.productSite != null &&
                              reachedGoal.productSite!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              reachedGoal.productSite!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            'Saved: $formattedSaved / $formattedTarget',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Congratulations! Your saving goal has been achieved and moved to Budget & Saving History.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    dialogCtx,
                  ).colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BAndSHistoryPage()),
                );
              },
              child: const Text(
                'View in B&S History',
                style: TextStyle(
                  color: Color(0xFF5442F5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text(
                'Awesome!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    _isShowingGoalReachedDialog = false;
    if (mounted) {
      _checkAndShowGoalReachedPopup();
    }
  }

  // Disposes confetti, audio player, and TransactionProvider listener when destroyed.
  @override
  void dispose() {
    _txProvider?.removeListener(_onTransactionProviderChanged);
    _confettiController.dispose();
    _audioPlayer?.dispose();
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
