import 'dart:convert';
import '../../core/constants/app_constants.dart';

class AppUser {
  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? badgeNumber;
  final String? assignedZone;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.badgeNumber,
    this.assignedZone,
    required this.role,
    this.isActive = true,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'].toString(),
        fullName: j['full_name'] ?? j['name'] ?? '',
        email: j['email'],
        phoneNumber: j['phone_number'] ?? j['phone'],
        badgeNumber: j['badge_number'],
        assignedZone: j['profile']?['assigned_zone'] ?? j['assigned_zone'],
        role: UserRole.fromString(j['role']),
        isActive: j['is_active'] ?? true,
        createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id, 'full_name': fullName, 'email': email,
        'phone_number': phoneNumber, 'badge_number': badgeNumber,
        'assigned_zone': assignedZone, 'role': role.value, 'is_active': isActive,
      };

  String get encoded => jsonEncode(toJson());
  static AppUser? decode(String? raw) {
    if (raw == null) return null;
    try { return AppUser.fromJson(jsonDecode(raw)); } catch (_) { return null; }
  }

  String get initials {
    final parts = fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  bool get isOfficer    => role == UserRole.officer;
  bool get isSupervisor => role == UserRole.supervisor || role == UserRole.admin;
}

class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  const PaginatedResponse({required this.count, this.next, this.previous, required this.results});

  factory PaginatedResponse.fromJson(Map<String, dynamic> j, T Function(Map<String, dynamic>) parser) =>
      PaginatedResponse(
        count: j['count'] ?? 0,
        next: j['next'],
        previous: j['previous'],
        results: ((j['results'] as List?) ?? []).whereType<Map<String, dynamic>>().map(parser).toList(),
      );
}

class PlateLookupResult {
  final String plateNumber;
  final String? vehicleType;
  final String? vehicleMake;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? ownerName;
  final String? licenseStatus;
  final int violationHistoryCount;
  final double outstandingFines;

  const PlateLookupResult({
    required this.plateNumber,
    this.vehicleType,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleColor,
    this.ownerName,
    this.licenseStatus,
    this.violationHistoryCount = 0,
    this.outstandingFines = 0,
  });

  factory PlateLookupResult.fromJson(Map<String, dynamic> j) => PlateLookupResult(
        plateNumber: j['vehicle']?['plate_number'] ?? j['plate_number'] ?? '',
        vehicleType: j['vehicle']?['type'],
        vehicleMake: j['vehicle']?['make'],
        vehicleModel: j['vehicle']?['model'],
        vehicleColor: j['vehicle']?['color'],
        ownerName: j['owner_name'],
        licenseStatus: j['license_status'],
        violationHistoryCount: j['violation_history_count'] ?? 0,
        outstandingFines: (j['outstanding_fines'] ?? 0).toDouble(),
      );
}

class ViolationType {
  final String id;
  final String name;
  final String code;
  final String description;
  final double defaultFine;
  final String defaultSeverity;
  final String? legalReference;

  const ViolationType({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.defaultFine,
    required this.defaultSeverity,
    this.legalReference,
  });

  factory ViolationType.fromJson(Map<String, dynamic> j) => ViolationType(
        id: j['id'].toString(),
        name: j['name'] ?? '',
        code: j['code'] ?? '',
        description: j['description'] ?? '',
        defaultFine: (j['default_fine_amount'] ?? j['amount'] ?? 0).toDouble(),
        defaultSeverity: j['default_severity'] ?? 'MINOR',
        legalReference: j['legal_reference'],
      );
}

class Intersection {
  final String id;
  final String name;
  final double lat;
  final double lng;

  const Intersection({required this.id, required this.name, required this.lat, required this.lng});

  factory Intersection.fromJson(Map<String, dynamic> j) => Intersection(
        id: j['id'].toString(),
        name: j['name'] ?? '',
        lat: (j['latitude'] ?? j['lat'] ?? 0).toDouble(),
        lng: (j['longitude'] ?? j['lng'] ?? 0).toDouble(),
      );
}
