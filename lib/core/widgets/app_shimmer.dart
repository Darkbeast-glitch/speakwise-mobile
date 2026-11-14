import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════
/// Smooth, High-Performance Animated Shimmer for Dark Theme
/// Sweeps an animated gradient over child placeholders.
/// ═══════════════════════════════════════════════════════════════
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFF141416),
    this.highlightColor = const Color(0xFF26272E),
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                (t - 0.35).clamp(0.0, 1.0),
                t.clamp(0.0, 1.0),
                (t + 0.35).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A standalone placeholder container for skeletons
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F24),
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// Full-Feed Explore Screen Shimmer Skeleton
/// Rendered while API data is loading — NO dummy data flashing!
/// ═══════════════════════════════════════════════════════════════
class ExploreFeedShimmer extends StatelessWidget {
  const ExploreFeedShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Categories shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: List.generate(
                4,
                (index) => const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: ShimmerBox(
                    width: 78,
                    height: 38,
                    borderRadius: 19,
                  ),
                ),
              ),
            ),
          ),

          // 2. Top Featured Event Section Title
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: ShimmerBox(
              width: 155,
              height: 18,
              borderRadius: 6,
            ),
          ),

          // 3. Top Featured Event Card Shimmer
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF141416),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Image Shimmer
                ShimmerBox(
                  width: double.infinity,
                  height: 180,
                  borderRadius: 20,
                ),
                SizedBox(height: 14),

                // Title Shimmer
                ShimmerBox(
                  width: 220,
                  height: 22,
                  borderRadius: 6,
                ),
                SizedBox(height: 10),

                // Date Shimmer
                ShimmerBox(
                  width: 170,
                  height: 14,
                  borderRadius: 4,
                ),
                SizedBox(height: 8),

                // Location Shimmer
                ShimmerBox(
                  width: 130,
                  height: 14,
                  borderRadius: 4,
                ),
                SizedBox(height: 10),

                // Bio Shimmer (2 lines)
                ShimmerBox(
                  width: double.infinity,
                  height: 12,
                  borderRadius: 4,
                ),
                SizedBox(height: 6),
                ShimmerBox(
                  width: 200,
                  height: 12,
                  borderRadius: 4,
                ),
                SizedBox(height: 16),

                // Action Buttons Shimmer
                Row(
                  children: [
                    Expanded(
                      child: ShimmerBox(
                        height: 44,
                        borderRadius: 22,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ShimmerBox(
                        height: 44,
                        borderRadius: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. "Happening This Month" Section Shimmer
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 160, height: 18, borderRadius: 6),
                ShimmerBox(width: 45, height: 14, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Horizontal Cards Shimmer
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) => Container(
                width: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF141416),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                padding: const EdgeInsets.all(12),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: double.infinity, height: 130, borderRadius: 14),
                    SizedBox(height: 12),
                    ShimmerBox(width: 130, height: 16, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerBox(width: 90, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 5. "Top Keynote Speakers" Section Shimmer
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 150, height: 18, borderRadius: 6),
                ShimmerBox(width: 45, height: 14, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (index) => const Column(
                  children: [
                    ShimmerBox(width: 60, height: 60, shape: BoxShape.circle),
                    SizedBox(height: 8),
                    ShimmerBox(width: 50, height: 10, borderRadius: 4),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 36),
        ],
      ),
    );
  }
}
