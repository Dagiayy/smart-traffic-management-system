import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            title: Text('Payment Center',
                style: AppTypography.h2.copyWith(color: AppColors.white)),
            flexibleSpace: FlexibleSpaceBar(
              background: _PaymentHeader(),
            ),
            bottom: TabBar(
              controller: _tab,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
              indicatorColor: AppColors.white,
              labelStyle: AppTypography.labelMedium,
              tabs: const [
                Tab(text: 'Unpaid'),
                Tab(text: 'History'),
                Tab(text: 'Receipts'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tab,
          children: const [
            _UnpaidTab(),
            _AllFinesTab(),
            _ReceiptsTab(),
          ],
        ),
      ),
    );
  }
}

class _PaymentHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(unpaidFinesProvider);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF163A6E)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 16),
      child: async.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (page) {
          final total = page.results.fold<double>(0, (s, f) => s + f.amount);
          final count = page.results.length;
          return Row(
            children: [
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Outstanding Balance',
                      style: AppTypography.labelSmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.8))),
                  Text(AppFormat.currency(total),
                      style: AppTypography.numeric(24, FontWeight.w800,
                          color: AppColors.white)),
                ],
              )),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$count fine${count == 1 ? '' : 's'}',
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Unpaid Tab ────────────────────────────────────────────────────────────
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
      data: (page) => page.results.isEmpty
          ? const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'All Clear!',
              message: 'You have no outstanding fines. Keep it up!',
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(unpaidFinesProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: page.results.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (ctx, i) => _FineTile(fine: page.results[i]),
              ),
            ),
    );
  }
}

// ── All Fines Tab ─────────────────────────────────────────────────────────
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
              title: 'No Fine History',
              message: 'Your payment history will appear here.',
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(allFinesProvider),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: page.results.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (ctx, i) => _FineTile(fine: page.results[i]),
              ),
            ),
    );
  }
}

// ── Receipts Tab ──────────────────────────────────────────────────────────
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
              title: 'No Receipts Yet',
              message: 'Receipts will appear here after you make payments.',
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
  const _FineTile({required this.fine});
  final Fine fine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: fine.isPaid
                    ? AppColors.successSurface
                    : fine.isOverdue
                        ? AppColors.dangerSurface
                        : AppColors.warningSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                fine.isPaid
                    ? Icons.check_circle_outline
                    : Icons.receipt_long_outlined,
                color: fine.isPaid
                    ? AppColors.success
                    : fine.isOverdue
                        ? AppColors.danger
                        : AppColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fine.violationType,
                    style: AppTypography.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('Plate: ${fine.plateNumber}',
                    style: AppTypography.bodySmall),
              ],
            )),
            StatusBadge(
              label: fine.isPaid
                  ? 'Paid'
                  : (fine.isOverdue ? 'Overdue' : 'Unpaid'),
              type: fine.isPaid
                  ? StatusType.success
                  : (fine.isOverdue ? StatusType.danger : StatusType.warning),
              compact: true,
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Amount', style: AppTypography.caption),
              Text(AppFormat.currency(fine.amount),
                  style: AppTypography.numeric(18, FontWeight.w700,
                      color:
                          fine.isPaid ? AppColors.success : AppColors.danger)),
            ]),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Due Date', style: AppTypography.caption),
              Text(AppFormat.date(fine.dueDate),
                  style: AppTypography.labelSmall.copyWith(
                      color: fine.isOverdue && !fine.isPaid
                          ? AppColors.danger
                          : AppColors.textSecondary)),
            ]),
          ]),
          if (!fine.isPaid) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showPaySheet(context),
                icon: const Icon(Icons.payment_outlined, size: 18),
                label: const Text('Pay Now'),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPaySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSheet(fine: fine),
    );
  }
}

// ── Payment Sheet ─────────────────────────────────────────────────────────
class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.fine});
  final Fine fine;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  bool _paying = false;
  bool _verifying = false;
  bool _success = false;
  String? _receiptId;
  String? _receiptNumber;
  String? _txRef;

  @override
  Widget build(BuildContext context) {
    if (_success) {
      return _SuccessSheet(
        amount: widget.fine.amount,
        receiptId: _receiptId,
        receiptNumber: _receiptNumber,
        onDone: () => Navigator.pop(context),
      );
    }
    if (_verifying) {
      return _VerifyingSheet(
          txRef: _txRef,
          fine: widget.fine,
          onVerified: (id, num) {
            setState(() {
              _verifying = false;
              _success = true;
              _receiptId = id;
              _receiptNumber = num;
            });
            ref.invalidate(unpaidFinesProvider);
            ref.invalidate(allFinesProvider);
            ref.invalidate(receiptsProvider);
          },
          onFailed: () {
            setState(() => _verifying = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                      'Payment not confirmed yet. Please try again later.')));
            }
          });
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        top: AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Pay Fine', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),

          // Fine summary card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.dangerSurface,
              borderRadius: AppRadius.radiusMd,
            ),
            child: Row(children: [
              const Icon(Icons.receipt_long_outlined,
                  color: AppColors.danger, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.fine.violationType,
                      style: AppTypography.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text('Plate: ${widget.fine.plateNumber}',
                      style: AppTypography.bodySmall),
                ],
              )),
              Text(AppFormat.currency(widget.fine.amount),
                  style: AppTypography.numeric(20, FontWeight.w800,
                      color: AppColors.danger)),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Chapa payment button (primary)
          _ChapaPayButton(
            amount: widget.fine.amount,
            loading: _paying,
            onPressed: () => _initiateChapa(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Powered by Chapa — Secure Ethiopian Payment Gateway',
              style: AppTypography.caption
                  .copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Future<void> _initiateChapa(BuildContext context) async {
    setState(() => _paying = true);
    try {
      final repo = ref.read(paymentsRepositoryProvider);
      final result = await repo.initiateChapa(fineId: widget.fine.id);
      final checkoutUrl = result['checkout_url'] as String?;
      final txRef = result['tx_ref'] as String?;
      setState(() {
        _paying = false;
        _txRef = txRef;
      });
      if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (mounted) setState(() => _verifying = true);
        } else {
          throw Exception('Cannot open payment URL');
        }
      } else {
        // Simulation mode (backend unavailable)
        if (mounted) setState(() => _verifying = true);
      }
    } catch (e) {
      setState(() => _paying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Payment initiation failed: ${e.toString()}'),
            backgroundColor: AppColors.danger));
      }
    }
  }
}

// ── Chapa Pay Button ───────────────────────────────────────────────────────
class _ChapaPayButton extends StatelessWidget {
  const _ChapaPayButton(
      {required this.amount, required this.loading, required this.onPressed});
  final double amount;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1DBF73),
          foregroundColor: AppColors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: AppColors.white, strokeWidth: 2.5))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.payment_outlined, size: 20),
                const SizedBox(width: 8),
                Text('Pay ${AppFormat.currency(amount)} via Chapa',
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.white)),
              ]),
      ),
    );
  }
}

// ── Verifying Sheet ───────────────────────────────────────────────────────
class _VerifyingSheet extends ConsumerStatefulWidget {
  const _VerifyingSheet({
    required this.txRef,
    required this.fine,
    required this.onVerified,
    required this.onFailed,
  });
  final String? txRef;
  final Fine fine;
  final void Function(String? id, String? num) onVerified;
  final VoidCallback onFailed;

  @override
  ConsumerState<_VerifyingSheet> createState() => _VerifyingSheetState();
}

class _VerifyingSheetState extends ConsumerState<_VerifyingSheet> {
  int _attempts = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Verifying Payment...', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.xs),
          Text('Please wait while we confirm your payment with Chapa.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Check Payment Status',
            variant: AppButtonVariant.secondary,
            onPressed: _verify,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: widget.onFailed,
            child: const Text('Cancel'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Future<void> _verify() async {
    if (_attempts >= 5) {
      widget.onFailed();
      return;
    }
    _attempts++;
    try {
      final repo = ref.read(paymentsRepositoryProvider);
      final result = await repo.verifyChapaPayment(
          fineId: widget.fine.id, txRef: widget.txRef ?? '');
      if (result['status'] == 'PAID') {
        widget.onVerified(result['receipt_id']?.toString(),
            result['receipt_number']?.toString());
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Payment not yet confirmed. Please try again.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Verification error. Please try again.')));
      }
    }
  }
}

// ── Success Sheet ─────────────────────────────────────────────────────────
class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet({
    required this.amount,
    required this.receiptId,
    required this.receiptNumber,
    required this.onDone,
  });
  final double amount;
  final String? receiptId;
  final String? receiptNumber;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
                color: AppColors.successSurface, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 44),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Payment Successful!', style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(AppFormat.currency(amount),
              style: AppTypography.numeric(28, FontWeight.w800,
                  color: AppColors.success)),
          const SizedBox(height: AppSpacing.lg),
          if (receiptNumber != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: AppRadius.radiusMd,
              ),
              child: Row(children: [
                const Icon(Icons.receipt_outlined,
                    color: AppColors.success, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receipt Number', style: AppTypography.labelSmall),
                    Text(receiptNumber!,
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.success)),
                  ],
                )),
              ]),
            ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Done',
            onPressed: onDone,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ── Receipt Tile ──────────────────────────────────────────────────────────
class _ReceiptTile extends ConsumerWidget {
  const _ReceiptTile({required this.receipt});
  final Receipt receipt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      elevated: true,
      onTap: () => _showReceiptDetail(context),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: AppColors.success, size: 24),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(receipt.receiptNumber ?? 'Receipt',
                  style: AppTypography.labelLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(AppFormat.dateTime(receipt.paidAt),
                  style: AppTypography.bodySmall),
              Text(_prettyMethod(receipt.paymentMethod),
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textTertiary)),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(AppFormat.currency(receipt.amount),
                style: AppTypography.numeric(16, FontWeight.w700,
                    color: AppColors.success)),
            const SizedBox(height: 4),
            const StatusBadge(
                label: 'Paid', type: StatusType.success, compact: true),
          ]),
        ],
      ),
    );
  }

  String _prettyMethod(String m) => switch (m) {
        'MOBILE_MONEY' => 'Mobile Money',
        'TELEBIRR' => 'TeleBirr',
        'CBE_BIRR' => 'CBE Birr',
        'BANK_TRANSFER' => 'Bank Transfer',
        'CARD' => 'Card',
        _ => m,
      };

  void _showReceiptDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReceiptDetailSheet(receipt: receipt),
    );
  }
}

// ── Receipt Detail Sheet ──────────────────────────────────────────────────
class _ReceiptDetailSheet extends StatelessWidget {
  const _ReceiptDetailSheet({required this.receipt});
  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2)),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
                color: AppColors.successSurface, shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_outlined,
                color: AppColors.success, size: 32),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Official Receipt', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.xs),
          Text(receipt.receiptNumber ?? '',
              style:
                  AppTypography.labelLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.lg),
          _DetailRow('Amount Paid', AppFormat.currency(receipt.amount)),
          _DetailRow('Payment Method', _prettyMethod(receipt.paymentMethod)),
          _DetailRow('Transaction ID', receipt.transactionId),
          _DetailRow('Date & Time', AppFormat.dateTime(receipt.paidAt)),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              borderRadius: AppRadius.radiusMd,
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.verified_outlined,
                  color: AppColors.success, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'This receipt is issued by the Integrated Traffic Management System',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.success))),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
              label: 'Close',
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.pop(context)),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  String _prettyMethod(String m) => switch (m) {
        'MOBILE_MONEY' => 'Mobile Money',
        'TELEBIRR' => 'TeleBirr',
        'CBE_BIRR' => 'CBE Birr',
        'BANK_TRANSFER' => 'Bank Transfer',
        'CARD' => 'Card',
        _ => m,
      };
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(children: [
          SizedBox(
              width: 130,
              child: Text(label,
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.textSecondary))),
          Expanded(child: Text(value, style: AppTypography.bodyMedium)),
        ]),
      );
}

Widget _skeleton() => ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => const SkeletonBox(height: 120, radius: 14),
    );
