import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/features/explore/data/models/event_model.dart';

/// ═══════════════════════════════════════════════════════════════
/// Categories Section Component
/// "Categories / See all" + Horizontal Category Pills with Thumbnails
/// ═══════════════════════════════════════════════════════════════
class CategoryChipsList extends StatelessWidget {
  final List<EventCategory> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback? onSeeAllTap;

  const CategoryChipsList({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.onSeeAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header: Categories / See all
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: AppTheme.font(
                  color: AppTheme.textPrimary,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSeeAllTap?.call();
                },
                child: Text(
                  'See all',
                  style: AppTheme.font(
                    color: AppTheme.textMuted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Horizontal Scrolling Pills
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category.id == selectedCategoryId;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onCategorySelected(category.id);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.fromLTRB(6, 5, 16, 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryAccent
                        : const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryAccent
                          : Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circular Globe Thumbnail
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: isSelected
                            ? Colors.black.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.1),
                        backgroundImage: AssetImage(category.imagePath),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category.name,
                        style: AppTheme.font(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
