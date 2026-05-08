import 'dart:convert';
import '../../core/constants/app_constants.dart';

/// User entity — matches backend `accounts.CustomUser`
class AppUser {
  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String? nationalId;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.nationalId,
    required this.role,
    this.isActive = true,
    this.createdAt,
    this.avatarUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      fullName: json['full_name'] ?? json['name'] ?? '',
      email: json['email'],
      phoneNumber: json['phone_number'] ?? json['phone'],
      nationalId: json['national_id'],
      role: UserRole.fromString(json['role']),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'national_id': nationalId,
        'role': role.value,
        'is_active': isActive,
        'created_at': createdAt?.toIso8601String(),
        'avatar_url': avatarUrl,
      };

  String get encoded => jsonEncode(toJson());

  static AppUser? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  String get initials {
    final parts = fullName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// Paginated list response — matches backend `{ count, next, previous, results }`
class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  const PaginatedResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parser,
  ) {
    return PaginatedResponse<T>(
      count: json['count'] ?? 0,
      next: json['next'],
      previous: json['previous'],
      results: ((json['results'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(parser)
          .toList(),
    );
  }
}
