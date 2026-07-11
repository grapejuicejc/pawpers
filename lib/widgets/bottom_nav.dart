import 'package:flutter/material.dart';
import '../app_theme.dart';

/// A custom bottom navigation bar with 5 icons, including a central "add" button.
/// parent screen via [onAddTap]).
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navIcon(Icons.home_outlined, 0),
          _navIcon(Icons.pets_outlined, 1),
          _addIcon(),
          _navIcon(Icons.volunteer_activism_outlined, 3),
          _navIcon(Icons.person_outline, 4),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, int index) {
    final selected = currentIndex == index;
    return IconButton(
      onPressed: () => onTap(index),
      icon: Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
    );
  }

  Widget _addIcon() {
    return GestureDetector(
      onTap: onAddTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        child: const Icon(Icons.add, color: Colors.white, size: 22),
      ),
    );
  }
}