import 'package:equatable/equatable.dart';
import '../../../artisans/domain/models/admin_artisan.dart';

class ReportActor extends Equatable {
  final String id;
  final String fullName;
  final String? email;
  final String? role;

  const ReportActor({
    required this.id,
    required this.fullName,
    this.email,
    this.role,
  });

  factory ReportActor.fromJson(Map<String, dynamic> json) {
    return ReportActor(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      fullName: (json['fullName'] ?? 'Utilisateur').toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, role];
}

class AdminReport extends Equatable {
  final String id;
  final String targetType; // 'request' | 'review' | 'message'
  final String targetId;
  final String reason;
  final String description;
  final String status; // 'pending' | 'dismissed' | 'action_taken'
  final ReportActor? reporter;
  final ReportActor? resolvedBy;
  final DateTime? resolvedAt;
  final String? resolutionNote;
  final Map<String, dynamic> targetSnapshot;
  final Map<String, dynamic>? target;
  final DateTime? createdAt;

  const AdminReport({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.description = '',
    this.status = 'pending',
    this.reporter,
    this.resolvedBy,
    this.resolvedAt,
    this.resolutionNote,
    this.targetSnapshot = const {},
    this.target,
    this.createdAt,
  });

  bool get isPending => status == 'pending';

  String get displayTitle {
    if (targetType == 'request') {
      return (target?['title'] ?? targetSnapshot['title'] ?? 'Demande signalée')
          .toString();
    }
    if (targetType == 'review') {
      final rating = target?['rating'] ?? targetSnapshot['rating'];
      return rating != null ? 'Avis $rating ★' : 'Avis signalé';
    }
    return 'Message signalé';
  }

  String get displayExcerpt {
    if (targetType == 'request') {
      return (target?['description'] ?? targetSnapshot['description'] ?? '')
          .toString();
    }
    if (targetType == 'review') {
      return (target?['comment'] ?? targetSnapshot['comment'] ?? '').toString();
    }
    return (target?['text'] ?? targetSnapshot['text'] ?? '').toString();
  }

  String? get authorName {
    final liveClient = target?['clientId'];
    if (liveClient is Map && liveClient['fullName'] != null) {
      return liveClient['fullName'].toString();
    }
    final liveSender = target?['senderId'];
    if (liveSender is Map && liveSender['fullName'] != null) {
      return liveSender['fullName'].toString();
    }
    return targetSnapshot['authorName']?.toString();
  }

  factory AdminReport.fromJson(Map<String, dynamic> json) {
    final rep = json['reporterId'] is Map<String, dynamic>
        ? ReportActor.fromJson(json['reporterId'] as Map<String, dynamic>)
        : null;
    final resBy = json['resolvedBy'] is Map<String, dynamic>
        ? ReportActor.fromJson(json['resolvedBy'] as Map<String, dynamic>)
        : null;

    return AdminReport(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      targetType: (json['targetType'] ?? 'request').toString(),
      targetId: (json['targetId'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      reporter: rep,
      resolvedBy: resBy,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
      resolutionNote: json['resolutionNote']?.toString(),
      targetSnapshot:
          (json['targetSnapshot'] as Map<String, dynamic>?) ?? const {},
      target: json['target'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  AdminReport copyWith({String? status, String? resolutionNote}) {
    return AdminReport(
      id: id,
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      description: description,
      status: status ?? this.status,
      reporter: reporter,
      resolvedBy: resolvedBy,
      resolvedAt: resolvedAt,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      targetSnapshot: targetSnapshot,
      target: target,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        targetType,
        targetId,
        reason,
        description,
        status,
        reporter,
        resolvedBy,
        resolvedAt,
        resolutionNote,
        targetSnapshot,
        target,
        createdAt,
      ];
}

class AdminReportsPage extends Equatable {
  final List<AdminReport> items;
  final AdminPagination pagination;

  const AdminReportsPage({
    required this.items,
    required this.pagination,
  });

  @override
  List<Object?> get props => [items, pagination];
}

class ModerationLogEntry extends Equatable {
  final String id;
  final String adminName;
  final String? adminEmail;
  final String action;
  final String targetType;
  final String targetId;
  final String reason;
  final DateTime? createdAt;

  const ModerationLogEntry({
    required this.id,
    required this.adminName,
    this.adminEmail,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.createdAt,
  });

  factory ModerationLogEntry.fromJson(Map<String, dynamic> json) {
    final admin = json['adminId'] is Map<String, dynamic>
        ? json['adminId'] as Map<String, dynamic>
        : null;
    return ModerationLogEntry(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      adminName: (admin?['fullName'] ?? 'Administrateur').toString(),
      adminEmail: admin?['email']?.toString(),
      action: (json['action'] ?? '').toString(),
      targetType: (json['targetType'] ?? '').toString(),
      targetId: (json['targetId'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        adminName,
        adminEmail,
        action,
        targetType,
        targetId,
        reason,
        createdAt
      ];
}
