/// Officer App — centralized constants.
class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'http://127.0.0.1:8000/api/v1';
  // Physical device: replace with LAN IP e.g. 'http://192.168.1.10:8000/api/v1'
  static const String wsBaseUrl ='ws://127.0.0.1:8000/ws';
  
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage keys
  static const String kAccessToken = 'access_token';
  static const String kRefreshToken = 'refresh_token';
  static const String kUserCache = 'user_cache';
  static const String kRememberMe = 'remember_me';
  static const String kOfflineQueue = 'offline_queue';
  static const String kViolationTypesCache = 'violation_types_cache';
  static const String kIntersectionsCache = 'intersections_cache';

  // Settings keys
  static const String kLanguage = 'settings_language';
  static const String kAutoSync = 'settings_auto_sync';
  static const String kBiometric = 'settings_biometric';
  static const String kAutoLock = 'settings_auto_lock';
  static const String kNotifSync = 'settings_notif_sync';
  static const String kNotifSupervisor = 'settings_notif_supervisor';
  static const String kNotifSystem = 'settings_notif_system';
  static const String kNotifPolicy = 'settings_notif_policy';
  static const String kNotifHighPriority = 'settings_notif_high_priority';
  static const String kLastSyncTime = 'last_sync_time';

  // App info
  static const String appName = 'Traffic Police Field Enforcement';
  static const String appTagline = 'Smart Enforcement. Faster Operations. Safer Roads.';
}

enum UserRole {
  officer('OFFICER'),
  supervisor('SUPERVISOR'),
  admin('ADMIN'),
  citizen('CITIZEN'),
  developer('DEVELOPER');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String? v) => UserRole.values.firstWhere(
        (e) => e.value == v,
        orElse: () => UserRole.officer,
      );
}

enum TicketStatus {
  draft('DRAFT'),
  submitted('SUBMITTED'),
  pendingSync('PENDING_SYNC'),
  synced('SYNCED'),
  underReview('UNDER_REVIEW'),
  acknowledged('ACKNOWLEDGED'),
  escalated('ESCALATED'),
  closed('CLOSED');

  final String value;
  const TicketStatus(this.value);

  static TicketStatus fromString(String? v) => TicketStatus.values.firstWhere(
        (e) => e.value == v,
        orElse: () => TicketStatus.draft,
      );

  String get label => switch (this) {
        TicketStatus.draft => 'Draft',
        TicketStatus.submitted => 'Submitted',
        TicketStatus.pendingSync => 'Pending Sync',
        TicketStatus.synced => 'Synced',
        TicketStatus.underReview => 'Under Review',
        TicketStatus.acknowledged => 'Acknowledged',
        TicketStatus.escalated => 'Escalated',
        TicketStatus.closed => 'Closed',
      };
}

enum Severity {
  minor('MINOR'),
  major('MAJOR'),
  critical('CRITICAL');

  final String value;
  const Severity(this.value);

  static Severity fromString(String? v) => Severity.values.firstWhere(
        (e) => e.value == v,
        orElse: () => Severity.minor,
      );
}
