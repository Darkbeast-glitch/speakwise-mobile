import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speakwise_mobile/app/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// Search and Filter Bar Component
/// Stadium "Discover" Field + Circular Tune Filter Button
/// ═══════════════════════════════════════════════════════════════
class SearchFilterBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final VoidCallback? onTap;
  final bool hasActiveFilters;
  final bool autoFocus;

  const SearchFilterBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onFilterTap,
    this.onTap,
    this.hasActiveFilters = false,
    this.autoFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEditable = controller != null || onChanged != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          // 1. Stadium "Discover" Search Field
          Expanded(
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Colors.white.withValues(alpha: 0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: isEditable
                        ? TextField(
                            controller: controller,
                            autofocus: autoFocus,
                            onChanged: onChanged,
                            onSubmitted: onSubmitted,
                            style: AppTheme.font(
                              color: AppTheme.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                            cursorColor: AppTheme.primaryAccent,
                            decoration: InputDecoration(
                              hintText: 'Discover',
                              hintStyle: AppTheme.font(
                                color: AppTheme.textMuted,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          )
                        : GestureDetector(
                            onTap: onTap,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Discover',
                                style: AppTheme.font(
                                  color: AppTheme.textMuted,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                  ),
                  if (controller != null && controller!.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        controller!.clear();
                        onClear?.call();
                        onChanged?.call('');
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppTheme.textMuted,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 2. Circular Filter Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onFilterTap?.call();
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: hasActiveFilters ? const Color(0xFF1E2813) : const Color(0xFF181818),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hasActiveFilters
                          ? AppTheme.primaryAccent
                          : Colors.white.withValues(alpha: 0.14),
                      width: hasActiveFilters ? 1.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.tune_rounded,
                      color: hasActiveFilters ? AppTheme.primaryAccent : AppTheme.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
                if (hasActiveFilters)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
