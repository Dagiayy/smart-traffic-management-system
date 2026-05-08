import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/app_storage.dart';
import '../../../shared/models/app_user.dart';

// ── Field Ticket Model ─────────────────────────────────────────────────
class FieldTicket {
  final String id;
  final String? localId;
  final String plateNumber;
  final String? vehicleType;
  final String? vehicleColor;
  final String? driverName;
  final String? driverLicense;
  final String? violationTypeId;
  final String? violationType;
  final String severity;
  final String status;
  final double? estimatedFine;
  final String? legalCode;
  final String? notes;
  final double? locationLat;
  final double? locationLng;
  final String? intersectionId;
  final String? locationName;
  final List<String> evidenceUrls;
  final DateTime createdAt;
  final bool isOffline;

  const FieldTicket({
    required this.id,
    this.localId,
    required this.plateNumber,
    this.vehicleType,
    this.vehicleColor,
    this.driverName,
    this.driverLicense,
    this.violationTypeId,
    this.violationType,
    required this.severity,
    required this.status,
    this.estimatedFine,
    this.legalCode,
    this.notes,
    this.locationLat,
    this.locationLng,
    this.intersectionId,
    this.locationName,
    this.evidenceUrls = const [],
    required this.createdAt,
    this.isOffline = false,
  });

  factory FieldTicket.fromJson(Map<String, dynamic> j) => FieldTicket(
        id: j['id']?.toString() ?? j['local_id']?.toString() ?? '',
        localId: j['local_id']?.toString(),
        plateNumber: j['plate_number'] ?? '',
        vehicleType: j['vehicle_type'],
        vehicleColor: j['vehicle_color'],
        driverName: j['driver_name'],
        driverLicense: j['driver_license'],
        violationTypeId: j['violation_type_id']?.toString() ?? j['violation_type']?['id']?.toString(),
        violationType: j['violation_type']?['name'] ?? j['violation_type_name'],
        severity: j['severity'] ?? 'MINOR',
        status: j['status'] ?? 'DRAFT',
        estimatedFine: (j['fine_amount'] ?? j['estimated_fine'] ?? 0).toDouble(),
        legalCode: j['legal_code'],
        notes: j['notes'],
        locationLat: (j['location_lat'] ?? j['lat'])?.toDouble(),
        locationLng: (j['location_lng'] ?? j['lng'])?.toDouble(),
        intersectionId: j['intersection_id']?.toString(),
        locationName: j['location_name'] ?? j['intersection']?['name'],
        evidenceUrls: ((j['evidence'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map<String>((e) => e['file_url']?.toString() ?? '')
            .where((u) => u.isNotEmpty)
            .toList(),
        createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
        isOffline: j['is_offline'] ?? false,
      );

  Map<String, dynamic> toOfflineJson() => {
        'local_id': localId ?? id,
        'plate_number': plateNumber,
        'vehicle_type': vehicleType,
        'driver_name': driverName,
        'driver_license': driverLicense,
        'violation_type_id': violationTypeId,
        'severity': severity,
        'status': status,
        'notes': notes,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'intersection_id': intersectionId,
        'created_at': createdAt.toIso8601String(),
        'is_offline': true,
      };
}

// ── Ticket Create/Edit State ──────────────────────────────────────────────
class TicketDraft {
  final String localId;
  String plateNumber;
  String? vehicleType;
  String? vehicleColor;
  String? vehicleCategory;
  String? registrationNumber;
  String? driverName;
  String? driverLicense;
  String? nationalId;
  String? contactNumber;
  String? violationTypeId;
  String? violationTypeName;
  String severity;
  String? legalCode;
  String? notes;
  double? estimatedFine;
  double? locationLat;
  double? locationLng;
  String? intersectionId;
  String? intersectionName;
  String? roadName;
  String? zone;
  List<File> evidenceFiles;
  PlateLookupResult? lookupResult;
  ViolationType? selectedViolationType;

  TicketDraft({
    String? localId,
    this.plateNumber = '',
    this.vehicleType,
    this.vehicleColor,
    this.vehicleCategory,
    this.registrationNumber,
    this.driverName,
    this.driverLicense,
    this.nationalId,
    this.contactNumber,
    this.violationTypeId,
    this.violationTypeName,
    this.severity = 'MINOR',
    this.legalCode,
    this.notes,
    this.estimatedFine,
    this.locationLat,
    this.locationLng,
    this.intersectionId,
    this.intersectionName,
    this.roadName,
    this.zone,
    List<File>? evidenceFiles,
    this.lookupResult,
    this.selectedViolationType,
  })  : localId = localId ?? const Uuid().v4(),
        evidenceFiles = evidenceFiles ?? [];

  TicketDraft copyWith({
    String? plateNumber, String? vehicleType, String? vehicleColor,
    String? vehicleCategory, String? registrationNumber, String? driverName,
    String? driverLicense, String? nationalId, String? contactNumber,
    String? violationTypeId, String? violationTypeName, String? severity,
    String? legalCode, String? notes, double? estimatedFine,
    double? locationLat, double? locationLng, String? intersectionId,
    String? intersectionName, String? roadName, String? zone,
    List<File>? evidenceFiles, PlateLookupResult? lookupResult,
    ViolationType? selectedViolationType,
  }) => TicketDraft(
        localId: localId,
        plateNumber: plateNumber ?? this.plateNumber,
        vehicleType: vehicleType ?? this.vehicleType,
        vehicleColor: vehicleColor ?? this.vehicleColor,
        vehicleCategory: vehicleCategory ?? this.vehicleCategory,
        registrationNumber: registrationNumber ?? this.registrationNumber,
        driverName: driverName ?? this.driverName,
        driverLicense: driverLicense ?? this.driverLicense,
        nationalId: nationalId ?? this.nationalId,
        contactNumber: contactNumber ?? this.contactNumber,
        violationTypeId: violationTypeId ?? this.violationTypeId,
        violationTypeName: violationTypeName ?? this.violationTypeName,
        severity: severity ?? this.severity,
        legalCode: legalCode ?? this.legalCode,
        notes: notes ?? this.notes,
        estimatedFine: estimatedFine ?? this.estimatedFine,
        locationLat: locationLat ?? this.locationLat,
        locationLng: locationLng ?? this.locationLng,
        intersectionId: intersectionId ?? this.intersectionId,
        intersectionName: intersectionName ?? this.intersectionName,
        roadName: roadName ?? this.roadName,
        zone: zone ?? this.zone,
        evidenceFiles: evidenceFiles ?? this.evidenceFiles,
        lookupResult: lookupResult ?? this.lookupResult,
        selectedViolationType: selectedViolationType ?? this.selectedViolationType,
      );

  Map<String, dynamic> toOfflineJson() => {
        'local_id': localId,
        'plate_number': plateNumber,
        'vehicle_type': vehicleType,
        'vehicle_color': vehicleColor,
        'driver_name': driverName,
        'driver_license': driverLicense,
        'violation_type_id': violationTypeId,
        'violation_type_name': violationTypeName,
        'severity': severity,
        'notes': notes,
        'location_lat': locationLat,
        'location_lng': locationLng,
        'intersection_id': intersectionId,
        'road_name': roadName,
        'contact_number': contactNumber,
        'national_id': nationalId,
        'is_offline': true,
      };
}

// ── Tickets Repository ────────────────────────────────────────────────────
class TicketsRepository {
  TicketsRepository(this._api);
  final ApiClient _api;

  Future<PaginatedResponse<FieldTicket>> getTickets({String? status, String? dateFrom, String? dateTo, int page = 1}) async {
    final query = <String, dynamic>{'page': page};
    if (status != null) query['status'] = status;
    if (dateFrom != null) query['date_from'] = dateFrom;
    if (dateTo != null) query['date_to'] = dateTo;
    final res = await _api.get('/officer/tickets/', query: query);
    return PaginatedResponse.fromJson(res.data as Map<String, dynamic>, FieldTicket.fromJson);
  }

  Future<FieldTicket> getTicket(String id) async {
    final res = await _api.get('/officer/tickets/$id/');
    return FieldTicket.fromJson(res.data as Map<String, dynamic>);
  }

  Future<FieldTicket> createTicket(TicketDraft draft) async {
    final form = FormData.fromMap({
      'plate_number': draft.plateNumber,
      'violation_type_id': draft.violationTypeId,
      'severity': draft.severity,
      'notes': draft.notes ?? '',
      if (draft.locationLat != null) 'location_lat': draft.locationLat,
      if (draft.locationLng != null) 'location_lng': draft.locationLng,
      if (draft.intersectionId != null) 'intersection_id': draft.intersectionId,
      if (draft.driverName != null) 'driver_name': draft.driverName,
      if (draft.driverLicense != null) 'driver_license': draft.driverLicense,
      if (draft.vehicleType != null) 'vehicle_type': draft.vehicleType,
      if (draft.vehicleColor != null) 'vehicle_color': draft.vehicleColor,
    });
    // Attach evidence files
    for (final file in draft.evidenceFiles) {
      form.files.add(MapEntry('evidence_files', await MultipartFile.fromFile(file.path, filename: file.path.split('/').last)));
    }
    final res = await _api.postMultipart('/officer/tickets/', form);
    return FieldTicket.fromJson(res.data as Map<String, dynamic>);
  }

  Future<FieldTicket> updateTicket(String id, TicketDraft draft) async {
    final form = FormData.fromMap({
      'plate_number': draft.plateNumber,
      if (draft.violationTypeId != null) 'violation_type_id': draft.violationTypeId,
      'severity': draft.severity,
      'notes': draft.notes ?? '',
      if (draft.locationLat != null) 'location_lat': draft.locationLat,
      if (draft.locationLng != null) 'location_lng': draft.locationLng,
    });
    for (final file in draft.evidenceFiles) {
      form.files.add(MapEntry('evidence_files', await MultipartFile.fromFile(file.path, filename: file.path.split('/').last)));
    }
    final res = await _api.patchMultipart('/officer/tickets/$id/', form);
    return FieldTicket.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> submitTicket(String id) async {
    await _api.post('/officer/tickets/$id/submit/');
  }

  Future<PlateLookupResult> plateLookup(String plate) async {
    final res = await _api.get('/officer/plate-lookup/', query: {'plate': plate});
    return PlateLookupResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ViolationType>> getViolationTypes() async {
    // Check cache first
    final cached = AppStorage.instance.getViolationTypes();
    if (cached != null) {
      try {
        return (jsonDecode(cached) as List)
            .whereType<Map<String, dynamic>>()
            .map(ViolationType.fromJson)
            .toList();
      } catch (_) {}
    }
    final res = await _api.get('/officer/violation-types/');
    final list = ((res.data as Map<String, dynamic>?)?['results'] as List?) ??
        (res.data is List ? res.data as List : []);
    final types = list.whereType<Map<String, dynamic>>().map(ViolationType.fromJson).toList();
    await AppStorage.instance.saveViolationTypes(jsonEncode(list));
    return types;
  }

  Future<List<Intersection>> getIntersections({double? lat, double? lng}) async {
    final query = <String, dynamic>{};
    if (lat != null) query['lat'] = lat;
    if (lng != null) query['lng'] = lng;
    final res = await _api.get('/officer/intersections/', query: query);
    final list = ((res.data as Map<String, dynamic>?)?['results'] as List?) ??
        (res.data is List ? res.data as List : []);
    return list.whereType<Map<String, dynamic>>().map(Intersection.fromJson).toList();
  }

  /// Bulk sync offline queue
  Future<Map<String, dynamic>> bulkSync(List<Map<String, dynamic>> tickets) async {
    final res = await _api.post('/officer/tickets/bulk-sync/', data: {'tickets': tickets});
    return res.data as Map<String, dynamic>;
  }
}

// ── Providers ─────────────────────────────────────────────────────────────
final ticketsRepositoryProvider = Provider<TicketsRepository>((ref) =>
    TicketsRepository(ref.watch(apiClientProvider)));

final ticketsListProvider = FutureProvider.autoDispose<PaginatedResponse<FieldTicket>>((ref) =>
    ref.watch(ticketsRepositoryProvider).getTickets());

final ticketFiltersProvider = StateProvider<({String? status})>((ref) => (status: null));

final filteredTicketsProvider = FutureProvider.autoDispose<PaginatedResponse<FieldTicket>>((ref) {
  final filters = ref.watch(ticketFiltersProvider);
  return ref.watch(ticketsRepositoryProvider).getTickets(status: filters.status);
});

final ticketDetailProvider = FutureProvider.autoDispose.family<FieldTicket, String>((ref, id) =>
    ref.watch(ticketsRepositoryProvider).getTicket(id));

final violationTypesProvider = FutureProvider<List<ViolationType>>((ref) =>
    ref.watch(ticketsRepositoryProvider).getViolationTypes());

final intersectionsProvider = FutureProvider.autoDispose<List<Intersection>>((ref) =>
    ref.watch(ticketsRepositoryProvider).getIntersections());

// Draft state for current ticket being created
final ticketDraftProvider = StateProvider<TicketDraft>((ref) => TicketDraft());

// Offline queue from local storage
final offlineQueueProvider = StateProvider<List<Map<String, dynamic>>>((ref) =>
    AppStorage.instance.getOfflineQueue());
