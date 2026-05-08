import '../../../core/utils/app_format.dart';

class Fine {
  final String id;
  final String violationId;
  final String violationType;
  final String plateNumber;
  final double amount;
  final String status; // UNPAID | PAID | PARTIALLY_PAID | WAIVED
  final DateTime dueDate;
  final DateTime createdAt;
  final String? receiptId;

  const Fine({
    required this.id,
    required this.violationId,
    required this.violationType,
    required this.plateNumber,
    required this.amount,
    required this.status,
    required this.dueDate,
    required this.createdAt,
    this.receiptId,
  });

  factory Fine.fromJson(Map<String, dynamic> j) => Fine(
        id: j['id'].toString(),
        violationId: j['violation']?.toString() ??
            j['violation_id']?.toString() ?? '',
        violationType:
            j['violation_type']?['name'] ?? j['type'] ?? 'Violation',
        plateNumber: j['plate_number'] ?? j['plate'] ?? '',
        amount: AppFormat.parseDouble(j['amount'] ?? j['fine_amount'] ?? 0),
        status: j['status'] ?? 'UNPAID',
        dueDate: DateTime.tryParse(j['due_date'] ?? j['deadline'] ?? '') ??
            DateTime.now().add(const Duration(days: 30)),
        createdAt:
            DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
        receiptId: j['receipt_id']?.toString(),
      );

  bool get isPaid => status == 'PAID' || status == 'WAIVED';
  bool get isOverdue => !isPaid && DateTime.now().isAfter(dueDate);
}

class Receipt {
  final String id;
  final String transactionId;
  final DateTime paidAt;
  final double amount;
  final String paymentMethod;
  final String violationRef;

  const Receipt({
    required this.id,
    required this.transactionId,
    required this.paidAt,
    required this.amount,
    required this.paymentMethod,
    required this.violationRef,
  });

  factory Receipt.fromJson(Map<String, dynamic> j) => Receipt(
        id: j['id'].toString(),
        transactionId: j['transaction_ref'] ?? j['transaction_id'] ?? j['id'].toString(),
        paidAt: DateTime.tryParse(j['paid_at'] ?? j['created_at'] ?? '') ??
            DateTime.now(),
        amount: AppFormat.parseDouble(j['amount'] ?? 0),
        paymentMethod: j['payment_method'] ?? 'MOBILE_MONEY',
        violationRef: j['violation_reference'] ?? j['fine_id']?.toString() ?? '',
      );
}
