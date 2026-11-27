import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String icon;
  final String description;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.icon = 'build',
    this.description = '',
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      icon: json['icon'] ?? 'build',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'icon': icon,
        'description': description,
      };

  @override
  List<Object?> get props => [id, name, slug, icon, description];
}

class Artisan extends Equatable {
  final String id;
  final String userId;
  final String fullName;
  final String? email;
  final String? phone;
  final String? profilePicture;
  final String specialty;
  final String city;
  final Category? category;
  final int experienceYears;
  final String bio;
  final String availability;
  final double rating;
  final int reviewsCount;
  final int completedJobs;
  final bool isVerified;

  const Artisan({
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
  });

  factory Artisan.fromJson(Map<String, dynamic> json) {
    final user = json['userId'] is Map<String, dynamic> ? json['userId'] : null;
    final cat = json['category'] is Map<String, dynamic>
        ? Category.fromJson(json['category'])
        : null;

    return Artisan(
      id: json['id'] ?? json['_id'] ?? '',
      userId: user != null
          ? (user['id'] ?? user['_id'] ?? '')
          : (json['userId'] ?? ''),
      fullName:
          user != null ? (user['fullName'] ?? '') : (json['fullName'] ?? ''),
      email: user != null ? user['email'] : json['email'],
      phone: user != null ? user['phone'] : json['phone'],
      profilePicture:
          user != null ? user['profilePicture'] : json['profilePicture'],
      specialty: json['specialty'] ?? '',
      city: json['city'] ?? 'Ouagadougou',
      category: cat,
      experienceYears: json['experienceYears'] ?? 0,
      bio: json['bio'] ?? '',
      availability: json['availability'] ?? 'Disponible',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: json['reviewsCount'] ?? 0,
      completedJobs: json['completedJobs'] ?? 0,
      isVerified: json['isVerified'] ??
          (user != null ? (user['isVerified'] ?? false) : false),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'profilePicture': profilePicture,
        'specialty': specialty,
        'city': city,
        'category': category?.toJson(),
        'experienceYears': experienceYears,
        'bio': bio,
        'availability': availability,
        'rating': rating,
        'reviewsCount': reviewsCount,
        'completedJobs': completedJobs,
        'isVerified': isVerified,
      };

  @override
  List<Object?> get props => [
        id,
        userId,
        fullName,
        email,
        phone,
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
      ];
}
