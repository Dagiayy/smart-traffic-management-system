import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_format.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/state_widgets.dart';
import '../../shared/widgets/status_badge.dart';
import 'data/violation_model.dart';
import 'data/violations_providers.dart';

class ViolationsScreen extends ConsumerWidget {
  const ViolationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(violationFiltersProvider);
    final filtersNotifier = ref.watch(violationFiltersProvider.notifier);
    final listAsync = ref.watch(violationsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Violations', style: AppTypography.h2),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: () => _showFilterSheet(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          if (filters.status != null || filters.severity != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
              child: Row(
                children: [
                  if (filters.status != null)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: Chip(
                        label: Text('Status: ${filters.status}',
                            style: AppTypography.labelSmall),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () => filtersNotifier.state =
                            filters.copyWith(status: null),
                      ),
                    ),
                  if (filters.severity != null)
                    Chip(
                      label: Text('Severity: ${filters.severity}',
                          style: AppTypography.labelSmall),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => filtersNotifier.state =
                          filters.copyWith(severity: null),
                    ),
                ],
              ),
            ),
          Expanded(
            child: listAsync.when(
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                itemCount: 6,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, __) =>
                    const SkeletonBox(height: 90, radius: 14),
              ),
              error: (e, _) => ErrorRetry(
                message: e.toString(),
                onRetry: () => ref.invalidate(violationsListProvider),
              ),
              data: (page) => page.results.isEmpty
                  ? const EmptyState(
                      icon: Icons.fact_check_outlined,
                      title: 'No Violations Found',
                      message: 'Your violation records will appear here.',
                    )
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(violationsListProvider),
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.all(AppSpacing.screenPadding),
                        itemCount: page.results.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (ctx, i) =>
                            _ViolationTile(violation: page.results[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(ref: ref),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final filters = ref.watch(violationFiltersProvider);
    final notifier = ref.watch(violationFiltersProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter Violations', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),
          Text('Status', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: ['CONFIRMED', 'UNDER_REVIEW', 'DISMISSED', 'PAID']
                .map((s) => ChoiceChip(
                      label: Text(s.toLowerCase().replaceAll('_', ' '),
                          style: AppTypography.labelSmall),
                      selected: filters.status == s,
                      onSelected: (v) => notifier.state =
                          filters.copyWith(status: v ? s : null),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Severity', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 8,
            children: ['MINOR', 'MAJOR', 'CRITICAL']
                .map((s) => ChoiceChip(
                      label: Text(s[0] + s.substring(1).toLowerCase(),
                          style: AppTypography.labelSmall),
                      selected: filters.severity == s,
                      onSelected: (v) => notifier.state =
                          filters.copyWith(severity: v ? s : null),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply Filters'),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _ViolationTile extends StatelessWidget {
  const _ViolationTile({required this.violation});
  final Violation violation;

  (StatusType, String) _statusBadge() {
    return switch (violation.status) {
      'PAID' => (StatusType.success, 'Paid'),
      'DISPUTED' => (StatusType.info, 'Disputed'),
      'DISMISSED' => (StatusType.neutral, 'Dismissed'),
      'UNDER_REVIEW' => (StatusType.info, 'Under Review'),
      _ => (StatusType.warning, 'Unpaid'),
    };
  }

  (StatusType, String) _severityBadge() {
    return switch (violation.severity) {
      'CRITICAL' => (StatusType.danger, 'Critical'),
      'MAJOR' => (StatusType.warning, 'Major'),
      _ => (StatusType.neutral, 'Minor'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (sType, sLabel) = _statusBadge();
    final (sevType, sevLabel) = _severityBadge();
    return AppCard(
      onTap: () => context.push('/violations/${violation.id}'),
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(violation.violationType,
                    style: AppTypography.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              StatusBadge(label: sLabel, type: sType, compact: true),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.directions_car_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(violation.plateNumber, style: AppTypography.bodySmall),
              const SizedBox(width: AppSpacing.md),
              const Icon(Icons.calendar_today_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(AppFormat.date(violation.date),
                  style: AppTypography.bodySmall),
            ],
          ),
          if (violation.location != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(violation.location!,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              StatusBadge(label: sevLabel, type: sevType, compact: true),
              const Spacer(),
              Text(
                AppFormat.currency(violation.fineAmount),
                style: AppTypography.numeric(16, FontWeight.w700,
                    color: violation.isPaid
                        ? AppColors.success
                        : AppColors.danger),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
