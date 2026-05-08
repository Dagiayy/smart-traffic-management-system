import 'package:flutter/widgets.dart';

import '../../../core/utils/app_format.dart';

/// Dashboard summary — matches GET /api/v1/citizen/violations/summary/
class DashboardSummary {
  final double totalUnpaid;
  final int activeViolations;
  final int complianceScore;
  final String driverStatus; // SAFE | WARNING | HIGH_RISK
  final int unreadNotifications;
  final int recentPayments;

  const DashboardSummary({
    required this.totalUnpaid,
    required this.activeViolations,
    required this.complianceScore,
    required this.driverStatus,
    this.unreadNotifications = 0,
    this.recentPayments = 0,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalUnpaid: AppFormat.parseDouble(json['total_unpaid'] ?? 0),
      activeViolations: json['active_violations'] ?? 0,
      complianceScore: json['compliance_score'] ?? 100,
      driverStatus: json['driver_status'] ?? 'SAFE',
      unreadNotifications: json['unread_notifications'] ?? 0,
      recentPayments: json['recent_payments'] ?? 0,
    );
  }

  factory DashboardSummary.empty() => const DashboardSummary(
        totalUnpaid: 0,
        activeViolations: 0,
        complianceScore: 100,
        driverStatus: 'SAFE',
      );

  String get driverStatusLabel {
    switch (driverStatus) {
      case 'HIGH_RISK':
        return 'High Risk';
      case 'WARNING':
        return 'Warning';
      case 'SAFE':
      default:
        return 'Safe Driver';
    }
  }

  String get scoreCategory {
    if (complianceScore >= 90) return 'Excellent Driver';
    if (complianceScore >= 75) return 'Good Driver';
    if (complianceScore >= 50) return 'Warning';
    return 'High Risk';
  }
}

class SmartInsight {
  final String message;
  final String type;
  final IconData? icon;

  const SmartInsight({required this.message, this.type = 'info', this.icon});

  factory SmartInsight.fromJson(Map<String, dynamic> json) => SmartInsight(
        message: json['message'] ?? '',
        type: json['type'] ?? 'info',
      );
}

class ActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String type;
  final String? status;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.type,
    this.status,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
        id: json['id'].toString(),
        title: json['title'] ?? '',
        subtitle: json['subtitle'] ?? '',
        timestamp:
            DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        type: json['type'] ?? 'NOTIFICATION',
        status: json['status'],
      );
}
