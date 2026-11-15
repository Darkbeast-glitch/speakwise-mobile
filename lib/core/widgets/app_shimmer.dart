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
  final BorderRadiusGeometry? customBorderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.customBorderRadius,
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
            : (customBorderRadius ?? BorderRadius.circular(borderRadius)),
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

/// ═══════════════════════════════════════════════════════════════
/// Speaker Profile Screen Shimmer Skeleton
/// ═══════════════════════════════════════════════════════════════
class SpeakerProfileShimmer extends StatelessWidget {
  const SpeakerProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // Top App Bar placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  ShimmerBox(width: 40, height: 40, shape: BoxShape.circle),
                  ShimmerBox(width: 40, height: 40, shape: BoxShape.circle),
                ],
              ),
            ),

            // Profile Card Header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 290,
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1F24),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Column(
                      children: const [
                        ShimmerBox(width: 170, height: 22, borderRadius: 6),
                        SizedBox(height: 8),
                        ShimmerBox(width: 130, height: 14, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 100, height: 12, borderRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Stats row (3 chips)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        left: index == 0 ? 0 : 5,
                        right: index == 2 ? 0 : 5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141416),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        children: const [
                          ShimmerBox(width: 44, height: 20, borderRadius: 4),
                          SizedBox(height: 6),
                          ShimmerBox(width: 54, height: 10, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // About Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 120, height: 16, borderRadius: 4),
                  SizedBox(height: 12),
                  ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                  SizedBox(height: 6),
                  ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                  SizedBox(height: 6),
                  ShimmerBox(width: 200, height: 12, borderRadius: 4),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Skills Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: 140, height: 16, borderRadius: 4),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      4,
                      (_) => const ShimmerBox(
                        width: 90,
                        height: 32,
                        borderRadius: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// Speaking Sessions List Shimmer (Tab 3: Talks)
/// ═══════════════════════════════════════════════════════════════
class SpeakingSessionsListShimmer extends StatelessWidget {
  const SpeakingSessionsListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: List.generate(
          2,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F110B),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner header
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFF191B16),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 110, height: 12, borderRadius: 4),
                      Spacer(),
                      ShimmerBox(width: 220, height: 18, borderRadius: 4),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 180, height: 12, borderRadius: 4),
                      SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerBox(width: 100, height: 28, borderRadius: 14),
                          ShimmerBox(width: 110, height: 36, borderRadius: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// Feedback Reviews Stream Shimmer (Tab 3: Feedback)
/// ═══════════════════════════════════════════════════════════════
class FeedbackListShimmer extends StatelessWidget {
  const FeedbackListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F110B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    ShimmerBox(width: 38, height: 38, shape: BoxShape.circle),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 100, height: 14, borderRadius: 4),
                        SizedBox(height: 4),
                        ShimmerBox(width: 60, height: 10, borderRadius: 4),
                      ],
                    ),
                    Spacer(),
                    ShimmerBox(width: 50, height: 24, borderRadius: 12),
                  ],
                ),
                const SizedBox(height: 12),
                const ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                const SizedBox(height: 6),
                const ShimmerBox(width: 220, height: 12, borderRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// Speakers Grid Shimmer (Explore Screen / All Speakers)
/// ═══════════════════════════════════════════════════════════════
class SpeakersGridShimmer extends StatelessWidget {
  const SpeakersGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF141416),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              ShimmerBox(width: 72, height: 72, shape: BoxShape.circle),
              SizedBox(height: 12),
              ShimmerBox(width: 90, height: 14, borderRadius: 4),
              SizedBox(height: 6),
              ShimmerBox(width: 70, height: 10, borderRadius: 4),
              SizedBox(height: 10),
              ShimmerBox(width: 64, height: 20, borderRadius: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// Events Vertical List Shimmer (All Events Screen)
/// ═══════════════════════════════════════════════════════════════
class EventsListShimmer extends StatelessWidget {
  const EventsListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF141416),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              const ShimmerBox(width: 88, height: 88, borderRadius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 70, height: 12, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerBox(width: 140, height: 15, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 100, height: 12, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════
/// Event Details Shimmer Skeleton
/// ═══════════════════════════════════════════════════════════════
class EventDetailsShimmer extends StatelessWidget {
  const EventDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(width: double.infinity, height: 260),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 90, height: 22, borderRadius: 11),
                  SizedBox(height: 12),
                  ShimmerBox(width: 240, height: 24, borderRadius: 6),
                  SizedBox(height: 10),
                  ShimmerBox(width: 170, height: 14, borderRadius: 4),
                  SizedBox(height: 18),
                  ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
                  SizedBox(height: 6),
                  ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
                  SizedBox(height: 6),
                  ShimmerBox(width: 190, height: 14, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
