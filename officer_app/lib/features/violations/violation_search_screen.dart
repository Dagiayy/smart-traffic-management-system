import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_format.dart';
import '../../shared/models/app_user.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../tickets/data/ticket_data.dart';

// ── Providers ─────────────────────────────────────────────────────────────
class _SearchState {
  final String query;
  final String? status;
  final String? severity;
  final String? dateFrom;
  final String? dateTo;

  const _SearchState({
    this.query = '',
    this.status,
    this.severity,
    this.dateFrom,
    this.dateTo,
  });

  _SearchState copyWith({
    String? query, String? status, String? severity,
    String? dateFrom, String? dateTo,
    bool clearStatus = false, bool clearSeverity = false,
  }) => _SearchState(
    query:    query    ?? this.query,
    status:   clearStatus  ? null : status   ?? this.status,
    severity: clearSeverity? null : severity ?? this.severity,
    dateFrom: dateFrom ?? this.dateFrom,
    dateTo:   dateTo   ?? this.dateTo,
  );
}

final _searchStateProvider = StateProvider<_SearchState>((ref) => const _SearchState());

final violationSearchProvider = FutureProvider.autoDispose<PaginatedResponse<FieldTicket>>((ref) async {
  final s   = ref.watch(_searchStateProvider);
  final api = ref.watch(apiClientProvider);

  if (s.query.isEmpty && s.status == null && s.severity == null &&
      s.dateFrom == null && s.dateTo == null) {
    return const PaginatedResponse(count: 0, results: []);
  }

  final query = <String, dynamic>{};
  if (s.query.isNotEmpty) query['q'] = s.query;
  if (s.status != null)   query['status']   = s.status;
  if (s.severity != null) query['severity']  = s.severity;
  if (s.dateFrom != null) query['date_from'] = s.dateFrom;
  if (s.dateTo != null)   query['date_to']   = s.dateTo;

  final res = await api.get('/officer/search/violations/', query: query);
  return PaginatedResponse.fromJson(res.data as Map<String, dynamic>, FieldTicket.fromJson);
});

// ── Screen ────────────────────────────────────────────────────────────────
class ViolationSearchScreen extends ConsumerStatefulWidget {
  const ViolationSearchScreen({super.key});
  @override
  ConsumerState<ViolationSearchScreen> createState() => _ViolationSearchScreenState();
}

class _ViolationSearchScreenState extends ConsumerState<ViolationSearchScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() { _searchCtrl.dispose(); _debounce?.cancel(); super.dispose(); }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      ref.read(_searchStateProvider.notifier).update((s) => s.copyWith(query: val.trim()));
    });
  }

  void _showFilters() {
    final state = ref.read(_searchStateProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _FilterSheet(state: state, onApply: (newState) {
        ref.read(_searchStateProvider.notifier).state = newState;
      }),
    );
  }

  void _clearAll() {
    _searchCtrl.clear();
    ref.read(_searchStateProvider.notifier).state = const _SearchState();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(_searchStateProvider);
    final hasFilters  = searchState.status != null || searchState.severity != null ||
                        searchState.dateFrom != null;
    final resultsAsync = ref.watch(violationSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search Violations'),
        actions: [
          if (hasFilters || _searchCtrl.text.isNotEmpty)
            TextButton(
              onPressed: _clearAll,
              child: const Text('Clear', style: TextStyle(color: AppColors.white)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar + filter button
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding, AppSpacing.sm,
                AppSpacing.screenPadding, AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by plate, driver name, violation type...',
                      hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref.read(_searchStateProvider.notifier)
                                    .update((s) => s.copyWith(query: ''));
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.tune_outlined),
                      onPressed: _showFilters,
                      style: IconButton.styleFrom(
                        backgroundColor: hasFilters ? AppColors.primarySurface : AppColors.background,
                        foregroundColor: hasFilters ? AppColors.primary : AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: hasFilters ? AppColors.primary : AppColors.border)),
                      ),
                    ),
                    if (hasFilters)
                      Positioned(
                        top: 6, right: 6,
                        child: Container(width: 8, height: 8,
                            decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle)),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Active filter chips
          if (hasFilters)
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, 0, AppSpacing.screenPadding, AppSpacing.sm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (searchState.status != null)
                      _FilterChip(
                        label: 'Status: ${searchState.status}',
                        onRemove: () => ref.read(_searchStateProvider.notifier)
                            .update((s) => s.copyWith(clearStatus: true)),
                      ),
                    if (searchState.severity != null)
                      _FilterChip(
                        label: 'Severity: ${searchState.severity}',
                        onRemove: () => ref.read(_searchStateProvider.notifier)
                            .update((s) => s.copyWith(clearSeverity: true)),
                      ),
                    if (searchState.dateFrom != null)
                      _FilterChip(
                        label: 'From: ${searchState.dateFrom}',
                        onRemove: () => ref.read(_searchStateProvider.notifier)
                            .update((s) => _SearchState(
                              query: s.query, status: s.status, severity: s.severity)),
                      ),
                  ],
                ),
              ),
            ),

          // Results
          Expanded(
            child: resultsAsync.when(
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                itemBuilder: (_, __) => const SkeletonBox(height: 76, radius: 12),
              ),
              error: (e, _) => ErrorRetry(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(violationSearchProvider)),
              data: (page) {
                if (searchState.query.isEmpty && searchState.status == null &&
                    searchState.severity == null && searchState.dateFrom == null) {
                  return const _SearchPrompt();
                }
                if (page.results.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_outlined,
                    title: 'No Results',
                    message: 'No violations found. Try different search terms or filters.',
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.screenPadding, AppSpacing.sm, AppSpacing.screenPadding, 0),
                      child: Row(children: [
                        Text('${page.count} result${page.count == 1 ? '' : 's'} found',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
                      ]),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.screenPadding),
                        itemCount: page.results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (_, i) => _ViolationTile(ticket: page.results[i]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.primary)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close, size: 14, color: AppColors.primary),
        ),
      ]),
    ),
  );
}

class _ViolationTile extends StatelessWidget {
  const _ViolationTile({required this.ticket});
  final FieldTicket ticket;

  @override
  Widget build(BuildContext context) {
    final color = switch (ticket.severity) {
      'CRITICAL' => AppColors.danger, 'MAJOR' => AppColors.warning, _ => AppColors.info,
    };
    return AppCard(
      onTap: () => context.push('/tickets/${ticket.id}'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long_outlined, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ticket.violationType ?? 'Violation',
                  style: AppTypography.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('Plate: ${ticket.plateNumber}  ·  ${AppFormat.date(ticket.createdAt)}',
                  style: AppTypography.bodySmall),
              if (ticket.driverName != null && ticket.driverName!.isNotEmpty)
                Text('Driver: ${ticket.driverName}',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            SyncBadge(status: ticket.status),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(ticket.severity, style: AppTypography.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
            ),
          ]),
        ],
      ),
    );
  }
}

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.search_outlined, size: 48, color: AppColors.primary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Search Violations', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.xs),
        Text('Enter a plate number, driver name, or\nviolation type to search the database.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      ],
    ),
  );
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.state, required this.onApply});
  final _SearchState state;
  final void Function(_SearchState) onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _status;
  late String? _severity;
  String? _dateFrom;

  @override
  void initState() {
    super.initState();
    _status   = widget.state.status;
    _severity = widget.state.severity;
    _dateFrom = widget.state.dateFrom;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.screenPadding,
        right: AppSpacing.screenPadding,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Filter Violations', style: AppTypography.h3),
            const Spacer(),
            TextButton(
              onPressed: () { setState(() { _status = null; _severity = null; _dateFrom = null; }); },
              child: const Text('Reset'),
            ),
          ]),
          const Divider(),

          Text('Status', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(spacing: 8, children: [
            'DRAFT', 'SUBMITTED', 'CONFIRMED', 'DISMISSED', 'ESCALATED'
          ].map((s) => ChoiceChip(
            label: Text(s, style: AppTypography.labelSmall),
            selected: _status == s,
            onSelected: (v) => setState(() => _status = v ? s : null),
          )).toList()),
          const SizedBox(height: AppSpacing.md),

          Text('Severity', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(spacing: 8, children: [
            ('MINOR', AppColors.info),
            ('MAJOR', AppColors.warning),
            ('CRITICAL', AppColors.danger),
          ].map((s) => ChoiceChip(
            label: Text(s.$1, style: AppTypography.labelSmall),
            selected: _severity == s.$1,
            selectedColor: s.$2.withValues(alpha: 0.2),
            onSelected: (v) => setState(() => _severity = v ? s.$1 : null),
          )).toList()),
          const SizedBox(height: AppSpacing.md),

          Text('Date From', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dateFrom != null ? DateTime.parse(_dateFrom!) : DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _dateFrom = picked.toIso8601String().substring(0, 10));
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(_dateFrom ?? 'Select date',
                    style: AppTypography.bodyMedium.copyWith(
                        color: _dateFrom != null ? AppColors.textPrimary : AppColors.textTertiary)),
              ]),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Apply Filters',
            icon: Icons.check_outlined,
            onPressed: () {
              widget.onApply(_SearchState(
                query:    widget.state.query,
                status:   _status,
                severity: _severity,
                dateFrom: _dateFrom,
              ));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
