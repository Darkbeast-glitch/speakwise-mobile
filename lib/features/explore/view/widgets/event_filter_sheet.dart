import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speakwise_mobile/app/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// EventFilterSheet Component
/// Exactly matches the SpeakWise web application filter specification:
/// - Search input
/// - Time Period (All Events, Upcoming, Past)
/// - Call for Proposals (CFP Open Only)
/// - Admission (All events, Free, Ticketed)
/// - Filter by Country dropdown
/// ═══════════════════════════════════════════════════════════════
class EventFilterSheet extends StatefulWidget {
  final String initialTimePeriod;
  final String initialAdmission;
  final bool initialCfpOpenOnly;
  final String initialCountry;
  final List<String> availableCountries;
  final Function({
    required String timePeriod,
    required String admission,
    required bool cfpOpenOnly,
    required String country,
  }) onApply;

  const EventFilterSheet({
    super.key,
    required this.initialTimePeriod,
    required this.initialAdmission,
    required this.initialCfpOpenOnly,
    required this.initialCountry,
    required this.availableCountries,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialTimePeriod,
    required String initialAdmission,
    required bool initialCfpOpenOnly,
    required String initialCountry,
    required List<String> availableCountries,
    required Function({
      required String timePeriod,
      required String admission,
      required bool cfpOpenOnly,
      required String country,
    }) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventFilterSheet(
        initialTimePeriod: initialTimePeriod,
        initialAdmission: initialAdmission,
        initialCfpOpenOnly: initialCfpOpenOnly,
        initialCountry: initialCountry,
        availableCountries: availableCountries,
        onApply: onApply,
      ),
    );
  }

  @override
  State<EventFilterSheet> createState() => _EventFilterSheetState();
}

class _EventFilterSheetState extends State<EventFilterSheet> {
  late String _timePeriod;
  late String _admission;
  late bool _cfpOpenOnly;
  late String _selectedCountry;

  final List<String> _timePeriods = const ['All Events', 'Upcoming', 'Past'];
  final List<String> _admissions = const ['All events', 'Free', 'Ticketed'];

  @override
  void initState() {
    super.initState();
    _timePeriod = widget.initialTimePeriod;
    _admission = widget.initialAdmission;
    _cfpOpenOnly = widget.initialCfpOpenOnly;
    _selectedCountry = widget.initialCountry;
  }

  void _onReset() {
    HapticFeedback.lightImpact();
    setState(() {
      _timePeriod = 'All Events';
      _admission = 'All events';
      _cfpOpenOnly = false;
      _selectedCountry = 'All';
    });
  }

  void _onApply() {
    HapticFeedback.lightImpact();
    widget.onApply(
      timePeriod: _timePeriod,
      admission: _admission,
      cfpOpenOnly: _cfpOpenOnly,
      country: _selectedCountry,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final countries = ['All', ...widget.availableCountries];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F100D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0x22FFFFFF), width: 1),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Sheet Title & Reset Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Events',
                  style: AppTheme.font(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                GestureDetector(
                  onTap: _onReset,
                  child: Text(
                    'Reset',
                    style: AppTheme.font(
                      color: AppTheme.primaryAccent,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 1. Time Period Section
            Text(
              'Time Period',
              style: AppTheme.font(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: _timePeriods.map((period) {
                final isSelected = _timePeriod.toLowerCase() == period.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _timePeriod = period);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE2E7ED) : const Color(0xFF141716),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        period,
                        style: AppTheme.font(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // 2. Call for Proposals (CFP) Section
            Text(
              'Call for Proposals',
              style: AppTheme.font(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _cfpOpenOnly = !_cfpOpenOnly);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _cfpOpenOnly ? const Color(0xFF1B2513) : const Color(0xFF141716),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _cfpOpenOnly ? AppTheme.primaryAccent : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: _cfpOpenOnly ? AppTheme.primaryAccent : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'CFP Open Only',
                        style: AppTheme.font(
                          color: _cfpOpenOnly ? AppTheme.primaryAccent : Colors.white,
                          fontSize: 14,
                          fontWeight: _cfpOpenOnly ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      _cfpOpenOnly ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      size: 20,
                      color: _cfpOpenOnly ? AppTheme.primaryAccent : AppTheme.textMuted,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // 3. Admission Section
            Text(
              'Admission',
              style: AppTheme.font(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: _admissions.map((adm) {
                final isSelected = _admission.toLowerCase() == adm.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _admission = adm);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE2E7ED) : const Color(0xFF141716),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        adm,
                        style: AppTheme.font(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            Text(
              'Free events may still require registration.',
              style: AppTheme.font(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 22),

            // 4. Filter by Country Section
            Text(
              'Filter by Country',
              style: AppTheme.font(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF141716),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: countries.contains(_selectedCountry) ? _selectedCountry : 'All',
                  isExpanded: true,
                  dropdownColor: const Color(0xFF141716),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                  ),
                  style: AppTheme.font(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  items: countries.map((c) {
                    return DropdownMenuItem<String>(
                      value: c,
                      child: Text(c == 'All' ? 'Select Countries (All)' : c),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCountry = val);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Material(
                color: AppTheme.primaryAccent,
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: _onApply,
                  child: Center(
                    child: Text(
                      'Apply Filters',
                      style: AppTheme.font(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
