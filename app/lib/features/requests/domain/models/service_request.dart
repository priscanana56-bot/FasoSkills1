import 'package:equatable/equatable.dart';
import '../../../../core/utils/json_utils.dart';
import 'quote.dart';

class ServiceRequest extends Equatable {
  final String id;
  final String clientId;
  final String categoryId;
  final String title;
  final String description;
  final String city;
  final String address;
  final List<String> photos;
  final String
      status; // 'pending' | 'accepted' | 'in_progress' | 'completed' | 'cancelled'
  final String? acceptedQuoteId;
  final DateTime? createdAt;

  // Enrichments returned by the API (null/0 when not provided).
  final String? clientName;
  final String? clientPhone;
  final String? categoryName;
  final String? categoryIcon;
  final int quotesCount;
  final Quote? acceptedQuote;

  /// The current artisan's own quote on this request (artisan views only).
  final Quote? myQuote;
  final int? reviewRating;
  final String? reviewComment;

  const ServiceRequest({
    required this.id,
    required this.clientId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.city,
    this.address = '',
    this.photos = const [],
    this.status = 'pending',
    this.acceptedQuoteId,
    this.createdAt,
    this.clientName,
    this.clientPhone,
    this.categoryName,
    this.categoryIcon,
    this.quotesCount = 0,
    this.acceptedQuote,
    this.myQuote,
    this.reviewRating,
    this.reviewComment,
  });

  bool get isPending => status == 'pending';
  bool get isActive => status == 'in_progress' || status == 'accepted';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get hasReview => reviewRating != null;

  ServiceRequest copyWith({
    String? id,
    String? clientId,
    String? categoryId,
    String? title,
    String? description,
    String? city,
    String? address,
    List<String>? photos,
    String? status,
    String? acceptedQuoteId,
    DateTime? createdAt,
  }) {
    return ServiceRequest(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      city: city ?? this.city,
      address: address ?? this.address,
      photos: photos ?? this.photos,
      status: status ?? this.status,
      acceptedQuoteId: acceptedQuoteId ?? this.acceptedQuoteId,
      createdAt: createdAt ?? this.createdAt,
      clientName: clientName,
      clientPhone: clientPhone,
      categoryName: categoryName,
      categoryIcon: categoryIcon,
      quotesCount: quotesCount,
      acceptedQuote: acceptedQuote,
      myQuote: myQuote,
      reviewRating: reviewRating,
      reviewComment: reviewComment,
    );
  }

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    final client = asMap(json['clientId']);
    final category = asMap(json['categoryId']);
    final accepted = asMap(json['acceptedQuote']);
    final mine = asMap(json['myQuote']);
    final review = asMap(json['review']);
    return ServiceRequest(
      id: readId(json),
      clientId: readId(json['clientId']),
      categoryId: readId(json['categoryId']),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      photos: (json['photos'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      status: json['status'] ?? 'pending',
      acceptedQuoteId: json['acceptedQuoteId'] != null
          ? readId(json['acceptedQuoteId'])
          : null,
      createdAt: readDate(json['createdAt']),
      clientName: client?['fullName'],
      clientPhone: client?['phone'],
      categoryName: category?['name'],
      categoryIcon: category?['icon'],
      quotesCount: readInt(json['quotesCount']),
      acceptedQuote: accepted != null ? Quote.fromJson(accepted) : null,
      myQuote: mine != null ? Quote.fromJson(mine) : null,
      reviewRating: review != null ? readInt(review['rating']) : null,
      reviewComment: review?['comment'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientId': clientId,
        'categoryId': categoryId,
        'title': title,
        'description': description,
        'city': city,
        'address': address,
        'photos': photos,
        'status': status,
        'acceptedQuoteId': acceptedQuoteId,
      };

  @override
  List<Object?> get props => [
        id,
        clientId,
        categoryId,
        title,
        description,
        city,
        address,
        photos,
        status,
        acceptedQuoteId,
        quotesCount,
        acceptedQuote,
        myQuote,
        reviewRating,
      ];
}
