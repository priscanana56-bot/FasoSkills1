import 'package:equatable/equatable.dart';

class AdminCategory extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String icon;
  final String description;
  final bool isActive;
  final DateTime? createdAt;

  const AdminCategory({
    required this.id,
    required this.name,
    this.slug = '',
    this.icon = 'build',
    this.description = '',
    this.isActive = true,
    this.createdAt,
  });

  factory AdminCategory.fromJson(Map<String, dynamic> json) {
    return AdminCategory(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      icon: (json['icon'] ?? 'build').toString(),
      description: (json['description'] ?? '').toString(),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  AdminCategory copyWith({
    String? name,
    String? slug,
    String? icon,
    String? description,
    bool? isActive,
  }) {
    return AdminCategory(
      id: id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, slug, icon, description, isActive, createdAt];
}
