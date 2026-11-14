import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speakwise_mobile/app/app_theme.dart';
import 'package:speakwise_mobile/core/widgets/widgets.dart';
import 'package:speakwise_mobile/features/explore/explore.dart';

/// ═══════════════════════════════════════════════════════════════
/// Screen: All Events Directory Screen
/// Connected directly to the live Events repository and API.
/// ═══════════════════════════════════════════════════════════════
class AllEventsScreen extends ConsumerStatefulWidget {
  final String initialCategory;

  const AllEventsScreen({super.key, this.initialCategory = 'all'});

  @override
  ConsumerState<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends ConsumerState<AllEventsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedCategory;
  String _searchQuery = '';
  List<EventItem> _events = [];
  bool _isLoading = false;

  // Filter sheet parameters
  String _timePeriod = 'All Events';
  String _admission = 'All events';
  bool _cfpOpenOnly = false;
  String _selectedCountry = 'All';
  List<String> _availableCountries = [];

  final List<String> _filterCategories = const [
    'All',
    'Africa',
    'Europe',
    'America',
    'Asia',
    'Ticketed',
    'Free',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory.toLowerCase();
    _loadEvents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(eventsRepositoryProvider);

      String? region;
      bool? isFree;

      if (_selectedCategory == 'africa' ||
          _selectedCategory == 'europe' ||
          _selectedCategory == 'america' ||
          _selectedCategory == 'asia') {
        region = _selectedCategory;
      } else if (_selectedCategory == 'free') {
        isFree = true;
      } else if (_selectedCategory == 'ticketed') {
        isFree = false;
      }

      if (_admission == 'Free') isFree = true;
      if (_admission == 'Ticketed') isFree = false;

      final timePeriod = _timePeriod == 'All Events'
          ? null
          : _timePeriod.toLowerCase();
      final country = _selectedCountry == 'All' ? null : _selectedCountry;
      final cfpOpen = _cfpOpenOnly ? true : null;

      final list = await repo.getEvents(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        region: region,
        timePeriod: timePeriod,
        isFree: isFree,
        cfpOpen: cfpOpen,
        country: country,
      );

      final countriesSet = <String>{};
      for (final ev in list) {
        if (ev.country != null && ev.country!.trim().isNotEmpty) {
          countriesSet.add(ev.country!.trim());
        }
      }

      if (mounted) {
        setState(() {
          _events = list;
          _availableCountries = countriesSet.toList()..sort();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _events = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openFilterSheet() {
    HapticFeedback.lightImpact();
    EventFilterSheet.show(
      context: context,
      initialTimePeriod: _timePeriod,
      initialAdmission: _admission,
      initialCfpOpenOnly: _cfpOpenOnly,
      initialCountry: _selectedCountry,
      availableCountries: _availableCountries,
      onApply:
          ({
            required String timePeriod,
            required String admission,
            required bool cfpOpenOnly,
            required String country,
          }) {
            setState(() {
              _timePeriod = timePeriod;
              _admission = admission;
              _cfpOpenOnly = cfpOpenOnly;
              _selectedCountry = country;
            });
            _loadEvents();
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters =
        _timePeriod != 'All Events' ||
        _admission != 'All events' ||
        _cfpOpenOnly ||
        _selectedCountry != 'All';

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. Header Bar: Back Button • Title • Total Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'All Events & Conferences',
                    style: AppTheme.font(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1E18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${_events.length} Events',
                      style: AppTheme.font(
                        color: AppTheme.primaryAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Discover Search & Filter Bar
            SearchFilterBar(
              controller: _searchController,
              hasActiveFilters: hasActiveFilters,
              onChanged: (query) {
                _searchQuery = query;
                _loadEvents();
              },
              onClear: () {
                _searchQuery = '';
                _loadEvents();
              },
              onFilterTap: _openFilterSheet,
            ),

            // 3. Horizontal Filter Category Chips
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filterCategories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _filterCategories[index];
                  final isSelected =
                      _selectedCategory.toLowerCase() == cat.toLowerCase();

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedCategory = cat.toLowerCase());
                      _loadEvents();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryAccent
                            : const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusPill,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryAccent
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: AppTheme.font(
                            color: isSelected ? Colors.black : Colors.white,
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // 4. Events List or Empty / Loading State
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryAccent,
                      ),
                    )
                  : _events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            color: AppTheme.textMuted.withValues(alpha: 0.6),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No events found',
                            style: AppTheme.font(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try adjusting your search or category filter',
                            style: AppTheme.font(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                      itemCount: _events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        final isFree =
                            event.isFree == true || !event.isTicketed;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push('/event/${event.id}', extra: event);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF141414),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Event Banner
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(22),
                                  ),
                                  child: SizedBox(
                                    height: 160,
                                    width: double.infinity,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        AppNetworkImage(
                                          imageUrl: event.imagePath,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black.withValues(
                                                    alpha: 0.6,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Top Right Ticket Tag
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isFree
                                                  ? const Color(0xFF1B2813)
                                                  : const Color(0xFF281E13),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isFree
                                                    ? AppTheme.primaryAccent
                                                          .withValues(
                                                            alpha: 0.4,
                                                          )
                                                    : const Color(
                                                        0xFFFFB74D,
                                                      ).withValues(alpha: 0.4),
                                              ),
                                            ),
                                            child: Text(
                                              isFree ? 'Free' : 'Ticketed',
                                              style: AppTheme.font(
                                                color: isFree
                                                    ? AppTheme.primaryAccent
                                                    : const Color(0xFFFFB74D),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Content Info Area
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.title,
                                        style: AppTheme.font(
                                          color: AppTheme.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            color: AppTheme.textMuted,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              event.location,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTheme.font(
                                                color: AppTheme.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            color: AppTheme.textMuted,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            event.date,
                                            style: AppTheme.font(
                                              color: AppTheme.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
        ),
      ),
    );
  }
}
