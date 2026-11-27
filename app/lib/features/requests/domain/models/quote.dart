import 'package:equatable/equatable.dart';
import '../../../../core/utils/json_utils.dart';
import 'service_request.dart';

class Quote extends Equatable {
  final String id;
  final String requestId;
  final String artisanId; // artisan profile id
  final String? artisanName;
  final String? artisanUserId;
  final String? artisanPhone;
  final String? artisanSpecialty;
  final double artisanRating;
  final bool artisanVerified;
  final double amount;
  final int estimatedDays;
  final String message;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final DateTime? createdAt;

  /// Populated request (only in the artisan's "my quotes" list).
  final ServiceRequest? request;

  const Quote({
    required this.id,
    required this.requestId,
    required this.artisanId,
    this.artisanName,
    this.artisanUserId,
    this.artisanPhone,
    this.artisanSpecialty,
    this.artisanRating = 0,
    this.artisanVerified = false,
    required this.amount,
    required this.estimatedDays,
    this.message = '',
    this.status = 'pending',
    this.createdAt,
    this.request,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  factory Quote.fromJson(Map<String, dynamic> json) {
    final artisan = asMap(json['artisanId']);
    final user = asMap(artisan?['userId']);
    final request = asMap(json['requestId']);
    return Quote(
      id: readId(json),
      requestId: readId(json['requestId']),
      artisanId: readId(json['artisanId']),
      artisanName: user?['fullName'],
      artisanUserId: user != null ? readId(user) : null,
      artisanPhone: user?['phone'],
      artisanSpecialty: artisan?['specialty'],
      artisanRating: readDouble(artisan?['rating']),
      artisanVerified: artisan?['isVerified'] ?? user?['isVerified'] ?? false,
      amount: readDouble(json['amount']),
      estimatedDays: readInt(json['estimatedDays']) == 0
          ? 1
          : readInt(json['estimatedDays']),
      message: json['message'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: readDate(json['createdAt']),
      request: request != null ? ServiceRequest.fromJson(request) : null,
    );
  }

  @override
  List<Object?> get props =>
      [id, requestId, artisanId, amount, estimatedDays, message, status];
}
