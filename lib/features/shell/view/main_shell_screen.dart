import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/features/explore/explore.dart';
import 'package:speakwise_mobile/features/profile/profile.dart';
import 'package:speakwise_mobile/features/scanner/view/scanner_screen.dart';
import 'package:speakwise_mobile/features/talks/view/talks_screen.dart';

/// ═══════════════════════════════════════════════════════════════
/// Main Shell Screen with Floating Pill Navigation Bar
/// Exact Reproduction of SpeakWise Reference UI
/// ═══════════════════════════════════════════════════════════════
class MainShellScreen extends StatefulWidget {
  final int initialIndex;

  const MainShellScreen({super.key, this.initialIndex = 0});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    ExploreScreen(),
    ScannerScreen(),
    TalksScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // 1. IndexedStack preserves state across tabs
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          // 2. Floating Centered Pill Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: _FloatingNavBar(
                currentIndex: _currentIndex,
                onTabSelected: _onTabSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabItem(0, Icons.explore_rounded, 'Explore'),
            const SizedBox(width: 6),
            _buildTabItem(1, Icons.search_rounded, 'Discover'),
            const SizedBox(width: 6),
            _buildTabItem(2, Icons.mic_none_rounded, 'Talks'),
            const SizedBox(width: 6),
            _buildTabItem(3, Icons.person_outline_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final isSelected = index == currentIndex;

    if (isSelected) {
      return GestureDetector(
        onTap: () => onTabSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.primaryAccent,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.black, size: 19),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.font(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0xFF222222),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: const Color(0xFFB0B0B0),
          size: 19,
        ),
      ),
    );
  }
}
