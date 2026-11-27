import 'package:equatable/equatable.dart';

class VerificationDocument extends Equatable {
  final String id;
  final String name;
  final String type;
  final String url;
  final DateTime? uploadedAt;

  const VerificationDocument({
    this.id = '',
    required this.name,
    this.type = 'document',
    required this.url,
    this.uploadedAt,
  });

  factory VerificationDocument.fromJson(Map<String, dynamic> json) {
    return VerificationDocument(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? 'Pièce justificative').toString(),
      type: (json['type'] ?? 'document').toString(),
      url: (json['url'] ?? '').toString(),
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString())
          : null,
    );
  }

  @override
  List<Object?> get props => [id, name, type, url, uploadedAt];
}

class AdminArtisanCategory extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String icon;

  const AdminArtisanCategory({
    required this.id,
    required this.name,
    this.slug = '',
    this.icon = 'build',
  });

  factory AdminArtisanCategory.fromJson(Map<String, dynamic> json) {
    return AdminArtisanCategory(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      icon: (json['icon'] ?? 'build').toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, slug, icon];
}

class AdminArtisan extends Equatable {
  final String id;
  final String userId;
  final String fullName;
  final String? email;
  final String? phone;
  final String? profilePicture;
  final String specialty;
  final String city;
  final AdminArtisanCategory? category;
  final int experienceYears;
  final String bio;
  final String availability;
  final double rating;
  final int reviewsCount;
  final int completedJobs;
  final bool isVerified;
  final String verificationStatus; // 'pending' | 'verified' | 'rejected'
  final String? rejectionReason;
  final List<VerificationDocument> documents;
  final String profileStatus;
  final DateTime? createdAt;
  final DateTime? verifiedAt;
  final DateTime? rejectedAt;

  const AdminArtisan({
    required this.id,
    required this.userId,
    required this.fullName,
    this.email,
    this.phone,
    this.profilePicture,
    required this.specialty,
    required this.city,
    this.category,
    this.experienceYears = 0,
    this.bio = '',
    this.availability = 'Disponible',
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.completedJobs = 0,
    this.isVerified = false,
    this.verificationStatus = 'pending',
    this.rejectionReason,
    this.documents = const [],
    this.profileStatus = 'incomplete',
    this.createdAt,
    this.verifiedAt,
    this.rejectedAt,
  });

  bool get isPending => !isVerified && verificationStatus != 'rejected';
  bool get isRejected => !isVerified && verificationStatus == 'rejected';

  factory AdminArtisan.fromJson(Map<String, dynamic> json) {
    final user = json['userId'] is Map<String, dynamic>
        ? json['userId'] as Map<String, dynamic>
        : null;
    final cat = json['category'] is Map<String, dynamic>
        ? AdminArtisanCategory.fromJson(
            json['category'] as Map<String, dynamic>)
        : null;
    final bool verified = json['isVerified'] ?? false;
    final String rawStatus =
        (json['verificationStatus'] ?? (verified ? 'verified' : 'pending'))
            .toString();

    return AdminArtisan(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      userId: user != null
          ? (user['id'] ?? user['_id'] ?? '').toString()
          : (json['userId'] ?? '').toString(),
      fullName: user != null
          ? (user['fullName'] ?? '').toString()
          : (json['fullName'] ?? '').toString(),
      email:
          user != null ? user['email']?.toString() : json['email']?.toString(),
      phone:
          user != null ? user['phone']?.toString() : json['phone']?.toString(),
      profilePicture: user != null
          ? user['profilePicture']?.toString()
          : json['profilePicture']?.toString(),
      specialty: (json['specialty'] ?? '').toString(),
      city: (json['city'] ?? 'Ouagadougou').toString(),
      category: cat,
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      bio: (json['bio'] ?? '').toString(),
      availability: (json['availability'] ?? 'Disponible').toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
      completedJobs: (json['completedJobs'] as num?)?.toInt() ?? 0,
      isVerified: verified,
      verificationStatus: rawStatus,
      rejectionReason: json['rejectionReason']?.toString(),
      documents: (json['documents'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(VerificationDocument.fromJson)
          .toList(),
      profileStatus: (json['profileStatus'] ?? 'incomplete').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'].toString())
          : null,
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.tryParse(json['rejectedAt'].toString())
          : null,
    );
  }

  AdminArtisan copyWith({
    bool? isVerified,
    String? verificationStatus,
    String? rejectionReason,
  }) {
    return AdminArtisan(
      id: id,
      userId: userId,
      fullName: fullName,
      email: email,
      phone: phone,
      profilePicture: profilePicture,
      specialty: specialty,
      city: city,
      category: category,
      experienceYears: experienceYears,
      bio: bio,
      availability: availability,
      rating: rating,
      reviewsCount: reviewsCount,
      completedJobs: completedJobs,
      isVerified: isVerified ?? this.isVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      documents: documents,
      profileStatus: profileStatus,
      createdAt: createdAt,
      verifiedAt: verifiedAt,
      rejectedAt: rejectedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        fullName,
        email,
        phone,
        profilePicture,
        specialty,
        city,
        category,
        experienceYears,
        bio,
        availability,
        rating,
        reviewsCount,
        completedJobs,
        isVerified,
        verificationStatus,
        rejectionReason,
        documents,
        profileStatus,
        createdAt,
      ];
}

class AdminPagination extends Equatable {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPrevPage;

  const AdminPagination({
    this.page = 1,
    this.limit = 10,
    this.total = 0,
    this.totalPages = 1,
    this.hasNextPage = false,
    this.hasPrevPage = false,
  });

  factory AdminPagination.fromJson(Map<String, dynamic> json) {
    return AdminPagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [page, limit, total, totalPages, hasNextPage, hasPrevPage];
}

class AdminArtisansPage extends Equatable {
  final List<AdminArtisan> items;
  final AdminPagination pagination;

  const AdminArtisansPage({
    required this.items,
    required this.pagination,
  });

  @override
  List<Object?> get props => [items, pagination];
}
