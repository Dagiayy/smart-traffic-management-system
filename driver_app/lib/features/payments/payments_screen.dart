import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/app_format.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/state_widgets.dart';
import '../../shared/widgets/status_badge.dart';
import 'data/payment_models.dart';
import 'data/payments_providers.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Payment Center', style: AppTypography.h2),
        bottom: TabBar(
          controller: _tab,
          labelStyle: AppTypography.labelMedium,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Unpaid'),
            Tab(text: 'All Fines'),
            Tab(text: 'Receipts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _UnpaidTab(),
          _AllFinesTab(),
          _ReceiptsTab(),
        ],
      ),
    );
  }
}

// ── Unpaid fines with pay action ─────────────────────────────────────────
class _UnpaidTab extends ConsumerWidget {
  const _UnpaidTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(unpaidFinesProvider);
    return async.when(
      loading: () => _skeleton(),
      error: (e, _) => ErrorRetry(
          message: e.toString(),
          onRetry: () => ref.invalidate(unpaidFinesProvider)),
      data: (page) {
        if (page.results.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle_outline,
            title: 'No Unpaid Fines',
            message: 'All your fines are settled.',
          );
        }
        final total = page.results.fold<double>(0, (s, f) => s + f.amount);
        return Column(
          children: [
            // Summary bar
            Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.dangerSurface,
                borderRadius: AppRadius.radiusMd,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Outstanding',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.dangerText)),
                        Text(AppFormat.currency(total),
                            style: AppTypography.numeric(22, FontWeight.w700,
                                color: AppColors.danger)),
                      ],
                    ),
                  ),
                  Text('${page.results.length} fine${page.results.length == 1 ? '' : 's'}',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.dangerText)),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(unpaidFinesProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0,
                      AppSpacing.md, AppSpacing.xl),
                  itemCount: page.results.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (ctx, i) =>
                      _FineTile(fine: page.results[i], canPay: true),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── All fines ────────────────────────────────────────────────────────────
class _AllFinesTab extends ConsumerWidget {
  const _AllFinesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allFinesProvider);
    return async.when(
      loading: () => _skeleton(),
      error: (e, _) => ErrorRetry(
          message: e.toString(),
          onRetry: () => ref.invalidate(allFinesProvider)),
      data: (page) => page.results.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No Fines Yet',
              message: 'Your fine history will appear here.',
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(allFinesProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: page.results.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (ctx, i) =>
                    _FineTile(fine: page.results[i], canPay: !page.results[i].isPaid),
              ),
            ),
    );
  }
}

// ── Receipts ────────────────────────────────────────────────────────────
class _ReceiptsTab extends ConsumerWidget {
  const _ReceiptsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(receiptsProvider);
    return async.when(
      loading: () => _skeleton(),
      error: (e, _) => ErrorRetry(
          message: e.toString(),
          onRetry: () => ref.invalidate(receiptsProvider)),
      data: (page) => page.results.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_outlined,
              title: 'No Receipts',
              message: 'Payment receipts will appear here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: page.results.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (ctx, i) => _ReceiptTile(receipt: page.results[i]),
            ),
    );
  }
}

// ── Fine Tile ─────────────────────────────────────────────────────────────
class _FineTile extends ConsumerWidget {
  const _FineTile({required this.fine, required this.canPay});
  final Fine fine;
  final bool canPay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(fine.violationType,
                      style: AppTypography.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
              StatusBadge(
                label: fine.isPaid ? 'Paid' : (fine.isOverdue ? 'Overdue' : 'Unpaid'),
                type: fine.isPaid
                    ? StatusType.success
                    : (fine.isOverdue ? StatusType.danger : StatusType.warning),
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.directions_car_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(fine.plateNumber, style: AppTypography.bodySmall),
              const Spacer(),
              Text('Due: ${AppFormat.date(fine.dueDate)}',
                  style: AppTypography.bodySmall.copyWith(
                      color: fine.isOverdue
                          ? AppColors.danger
                          : AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(AppFormat.currency(fine.amount),
                  style: AppTypography.numeric(18, FontWeight.w700,
                      color: fine.isPaid
                          ? AppColors.success
                          : AppColors.danger)),
              const Spacer(),
              if (canPay)
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () =>
                        _showPayDialog(context, ref, fine),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16)),
                    child: const Text('Pay Now'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showPayDialog(
      BuildContext context, WidgetRef ref, Fine fine) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PaymentSheet(fine: fine, ref: ref),
    );
  }
}

// ── Payment Sheet ─────────────────────────────────────────────────────────
class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.fine, required this.ref});
  final Fine fine;
  final WidgetRef ref;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  String _method = 'MOBILE_MONEY';
  bool _paying = false;
  bool _success = false;
  String? _receiptId;

  @override
  Widget build(BuildContext context) {
    if (_success) return _SuccessView(receiptId: _receiptId, amount: widget.fine.amount);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pay Fine', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.xs),
            Text(AppFormat.currency(widget.fine.amount),
                style: AppTypography.numeric(28, FontWeight.w700,
                    color: AppColors.danger)),
            Text(widget.fine.violationType, style: AppTypography.bodySmall),
            const SizedBox(height: AppSpacing.lg),
            Text('Payment Method', style: AppTypography.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            ...[
              ('MOBILE_MONEY', Icons.phone_android_outlined, 'Mobile Money'),
              ('BANK_TRANSFER', Icons.account_balance_outlined, 'Bank Transfer'),
              ('CARD', Icons.credit_card_outlined, 'Card Payment'),
            ].map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: InkWell(
                    borderRadius: AppRadius.radiusMd,
                    onTap: () => setState(() => _method = m.$1),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.radiusMd,
                        border: Border.all(
                          color: _method == m.$1
                              ? AppColors.primary
                              : AppColors.border,
                          width: _method == m.$1 ? 1.5 : 1,
                        ),
                        color: _method == m.$1
                            ? AppColors.primarySurface
                            : AppColors.surface,
                      ),
                      child: Row(children: [
                        Icon(m.$2,
                            color: _method == m.$1
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Text(m.$3, style: AppTypography.bodyMedium),
                        const Spacer(),
                        if (_method == m.$1)
                          const Icon(Icons.check_circle,
                              color: AppColors.primary, size: 18),
                      ]),
                    ),
                  ),
                )),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Confirm & Pay ${AppFormat.currency(widget.fine.amount)}',
              loading: _paying,
              onPressed: _paying ? null : _pay,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      final repo = ref.read(paymentsRepositoryProvider);
      final result = await repo.payFine(
        fineId: widget.fine.id,
        paymentMethod: _method,
        transactionRef: const Uuid().v4(),
      );
      ref.invalidate(unpaidFinesProvider);
      ref.invalidate(allFinesProvider);
      ref.invalidate(receiptsProvider);
      setState(() {
        _paying = false;
        _success = true;
        _receiptId = result['receipt_id']?.toString();
      });
    } catch (e) {
      setState(() => _paying = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.receiptId, required this.amount});
  final String? receiptId;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
                color: AppColors.successSurface, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 40),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Payment Successful', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(AppFormat.currency(amount),
              style: AppTypography.numeric(26, FontWeight.w700,
                  color: AppColors.success)),
          if (receiptId != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Receipt ID: $receiptId',
                style: AppTypography.bodySmall),
          ],
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Done',
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ── Receipt Tile ─────────────────────────────────────────────────────────
class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({required this.receipt});
  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.successSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_outlined,
                color: AppColors.success, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Txn: ${receipt.transactionId}',
                    style: AppTypography.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(AppFormat.dateTime(receipt.paidAt),
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
          Text(AppFormat.currency(receipt.amount),
              style: AppTypography.numeric(16, FontWeight.w700,
                  color: AppColors.success)),
        ],
      ),
    );
  }
}

Widget _skeleton() => ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const SkeletonBox(height: 80, radius: 14),
    );
