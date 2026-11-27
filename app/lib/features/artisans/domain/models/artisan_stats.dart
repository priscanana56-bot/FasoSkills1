import 'package:equatable/equatable.dart';
import '../../../../core/utils/json_utils.dart';

class ArtisanStats extends Equatable {
  final int openRequests;
  final int pendingQuotes;
  final int acceptedQuotes;
  final int activeMissions;
  final int completedJobs;
  final double rating;
  final int reviewsCount;
  final double earnings;
  final String verificationStatus; // 'pending' | 'verified' | 'rejected'
  final String profileStatus; // 'incomplete' | 'complete'

  const ArtisanStats({
    this.openRequests = 0,
    this.pendingQuotes = 0,
    this.acceptedQuotes = 0,
    this.activeMissions = 0,
    this.completedJobs = 0,
    this.rating = 0,
    this.reviewsCount = 0,
    this.earnings = 0,
    this.verificationStatus = 'pending',
    this.profileStatus = 'incomplete',
  });

  factory ArtisanStats.fromJson(Map<String, dynamic> json) => ArtisanStats(
        openRequests: readInt(json['openRequests']),
        pendingQuotes: readInt(json['pendingQuotes']),
        acceptedQuotes: readInt(json['acceptedQuotes']),
        activeMissions: readInt(json['activeMissions']),
        completedJobs: readInt(json['completedJobs']),
        rating: readDouble(json['rating']),
        reviewsCount: readInt(json['reviewsCount']),
        earnings: readDouble(json['earnings']),
        verificationStatus: json['verificationStatus'] ?? 'pending',
        profileStatus: json['profileStatus'] ?? 'incomplete',
      );

  @override
  List<Object?> get props => [
        openRequests,
        pendingQuotes,
        acceptedQuotes,
        activeMissions,
        completedJobs,
        rating,
        reviewsCount,
        earnings,
        verificationStatus,
        profileStatus,
      ];
}

class ArtisanReview extends Equatable {
  final String id;
  final String clientName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const ArtisanReview({
    required this.id,
    required this.clientName,
    required this.rating,
    this.comment = '',
    this.createdAt,
  });

  factory ArtisanReview.fromJson(Map<String, dynamic> json) => ArtisanReview(
        id: readId(json),
        clientName: asMap(json['clientId'])?['fullName'] ?? 'Client',
        rating: readInt(json['rating']),
        comment: json['comment'] ?? '',
        createdAt: readDate(json['createdAt']),
      );

  @override
  List<Object?> get props => [id, rating, comment];
}
