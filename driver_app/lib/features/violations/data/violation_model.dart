import '../../../core/utils/app_format.dart';

class Violation {
  final String id;
  final String violationType;
  final String typeCode;
  final String plateNumber;
  final DateTime date;
  final String status; // DETECTED | UNDER_REVIEW | CONFIRMED | DISMISSED
  final String severity; // MINOR | MAJOR | CRITICAL
  final double fineAmount;
  final String? evidenceUrl;
  final String? location;
  final String? officerOrSystem;
  final String? referenceNumber;
  final String? legalCode;
  final DateTime? paymentDeadline;
  final String? notes;

  const Violation({
    required this.id,
    required this.violationType,
    required this.typeCode,
    required this.plateNumber,
    required this.date,
    required this.status,
    required this.severity,
    required this.fineAmount,
    this.evidenceUrl,
    this.location,
    this.officerOrSystem,
    this.referenceNumber,
    this.legalCode,
    this.paymentDeadline,
    this.notes,
  });

  factory Violation.fromJson(Map<String, dynamic> j) => Violation(
        id: j['id'].toString(),
        violationType: j['violation_type']?['name'] ?? j['type'] ?? 'Violation',
        typeCode: j['violation_type']?['code'] ?? j['type_code'] ?? '',
        plateNumber: j['plate_number'] ?? j['plate'] ?? '',
        date: DateTime.tryParse(j['created_at'] ?? j['date'] ?? '') ?? DateTime.now(),
        status: j['status'] ?? 'CONFIRMED',
        severity: j['severity'] ?? 'MINOR',
        fineAmount: AppFormat.parseDouble(j['fine_amount'] ?? j['amount'] ?? 0),
        evidenceUrl: j['evidence_url'],
        location: j['location'] ?? j['intersection']?['name'],
        officerOrSystem: j['source'] ?? j['officer']?['name'],
        referenceNumber: j['reference_number'] ?? j['id'].toString(),
        legalCode: j['legal_code'],
        paymentDeadline: j['payment_deadline'] != null
            ? DateTime.tryParse(j['payment_deadline'])
            : null,
        notes: j['notes'],
      );

  bool get isPaid => status == 'PAID';
  bool get isDisputed => status == 'DISPUTED';
  bool get isConfirmed => status == 'CONFIRMED';
}
