import 'package:equatable/equatable.dart';

class UserStats extends Equatable {
  final int total;
  final int clients;
  final int artisans;
  final int admins;

  const UserStats({
    this.total = 0,
    this.clients = 0,
    this.artisans = 0,
    this.admins = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      clients: (json['clients'] as num?)?.toInt() ?? 0,
      artisans: (json['artisans'] as num?)?.toInt() ?? 0,
      admins: (json['admins'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'clients': clients,
        'artisans': artisans,
        'admins': admins,
      };

  @override
  List<Object?> get props => [total, clients, artisans, admins];
}

class ArtisanStats extends Equatable {
  final int total;
  final int verified;
  final int pending;
  final int rejected;

  const ArtisanStats({
    this.total = 0,
    this.verified = 0,
    this.pending = 0,
    this.rejected = 0,
  });

  factory ArtisanStats.fromJson(Map<String, dynamic> json) {
    return ArtisanStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      verified: (json['verified'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'verified': verified,
        'pending': pending,
        'rejected': rejected,
      };

  @override
  List<Object?> get props => [total, verified, pending, rejected];
}

class RequestStats extends Equatable {
  final int total;
  final int pending;
  final int inProgress;
  final int completed;
  final int cancelled;

  const RequestStats({
    this.total = 0,
    this.pending = 0,
    this.inProgress = 0,
    this.completed = 0,
    this.cancelled = 0,
  });

  factory RequestStats.fromJson(Map<String, dynamic> json) {
    return RequestStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      inProgress: (json['inProgress'] as num?)?.toInt() ?? 0,
      completed: (json['completed'] as num?)?.toInt() ?? 0,
      cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'pending': pending,
        'inProgress': inProgress,
        'completed': completed,
        'cancelled': cancelled,
      };

  @override
  List<Object?> get props => [total, pending, inProgress, completed, cancelled];
}

class QuoteStats extends Equatable {
  final int total;
  final int pending;
  final int accepted;
  final int rejected;
  final int totalAcceptedAmount;
  final int averageAmount;

  const QuoteStats({
    this.total = 0,
    this.pending = 0,
    this.accepted = 0,
    this.rejected = 0,
    this.totalAcceptedAmount = 0,
    this.averageAmount = 0,
  });

  factory QuoteStats.fromJson(Map<String, dynamic> json) {
    return QuoteStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      accepted: (json['accepted'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
      totalAcceptedAmount: (json['totalAcceptedAmount'] as num?)?.toInt() ?? 0,
      averageAmount: (json['averageAmount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total': total,
        'pending': pending,
        'accepted': accepted,
        'rejected': rejected,
        'totalAcceptedAmount': totalAcceptedAmount,
        'averageAmount': averageAmount,
      };

  @override
  List<Object?> get props =>
      [total, pending, accepted, rejected, totalAcceptedAmount, averageAmount];
}

class CategoryStats extends Equatable {
  final int total;
  final int active;

  const CategoryStats({this.total = 0, this.active = 0});

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'total': total, 'active': active};

  @override
  List<Object?> get props => [total, active];
}

class ReportStats extends Equatable {
  final int total;
  final int pending;

  const ReportStats({this.total = 0, this.pending = 0});

  factory ReportStats.fromJson(Map<String, dynamic> json) {
    return ReportStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      pending: (json['pending'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'total': total, 'pending': pending};

  @override
  List<Object?> get props => [total, pending];
}

class CategoryChartPoint extends Equatable {
  final String categoryId;
  final String name;
  final String slug;
  final int count;

  const CategoryChartPoint({
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.count,
  });

  factory CategoryChartPoint.fromJson(Map<String, dynamic> json) {
    return CategoryChartPoint(
      categoryId: (json['categoryId'] ?? '').toString(),
      name: (json['name'] ?? 'Autre').toString(),
      slug: (json['slug'] ?? 'autre').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'name': name,
        'slug': slug,
        'count': count,
      };

  @override
  List<Object?> get props => [categoryId, name, slug, count];
}

class CityChartPoint extends Equatable {
  final String city;
  final int count;
  final int verifiedCount;

  const CityChartPoint({
    required this.city,
    required this.count,
    required this.verifiedCount,
  });

  factory CityChartPoint.fromJson(Map<String, dynamic> json) {
    return CityChartPoint(
      city: (json['city'] ?? 'Inconnue').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
      verifiedCount: (json['verifiedCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'city': city,
        'count': count,
        'verifiedCount': verifiedCount,
      };

  @override
  List<Object?> get props => [city, count, verifiedCount];
}

class StatusChartPoint extends Equatable {
  final String status;
  final int count;

  const StatusChartPoint({required this.status, required this.count});

  factory StatusChartPoint.fromJson(Map<String, dynamic> json) {
    return StatusChartPoint(
      status: (json['status'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'status': status, 'count': count};

  @override
  List<Object?> get props => [status, count];
}

class AdminCharts extends Equatable {
  final List<CategoryChartPoint> requestsByCategory;
  final List<CityChartPoint> artisansByCity;
  final List<StatusChartPoint> requestsByStatus;

  const AdminCharts({
    this.requestsByCategory = const [],
    this.artisansByCity = const [],
    this.requestsByStatus = const [],
  });

  factory AdminCharts.fromJson(Map<String, dynamic> json) {
    return AdminCharts(
      requestsByCategory: (json['requestsByCategory'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CategoryChartPoint.fromJson)
          .toList(),
      artisansByCity: (json['artisansByCity'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CityChartPoint.fromJson)
          .toList(),
      requestsByStatus: (json['requestsByStatus'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(StatusChartPoint.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'requestsByCategory':
            requestsByCategory.map((e) => e.toJson()).toList(),
        'artisansByCity': artisansByCity.map((e) => e.toJson()).toList(),
        'requestsByStatus': requestsByStatus.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props =>
      [requestsByCategory, artisansByCity, requestsByStatus];
}

class AdminStats extends Equatable {
  final UserStats users;
  final ArtisanStats artisans;
  final RequestStats requests;
  final QuoteStats quotes;
  final CategoryStats categories;
  final ReportStats reports;
  final AdminCharts charts;

  const AdminStats({
    this.users = const UserStats(),
    this.artisans = const ArtisanStats(),
    this.requests = const RequestStats(),
    this.quotes = const QuoteStats(),
    this.categories = const CategoryStats(),
    this.reports = const ReportStats(),
    this.charts = const AdminCharts(),
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      users: UserStats.fromJson(
          (json['users'] as Map<String, dynamic>?) ?? const {}),
      artisans: ArtisanStats.fromJson(
          (json['artisans'] as Map<String, dynamic>?) ?? const {}),
      requests: RequestStats.fromJson(
          (json['requests'] as Map<String, dynamic>?) ?? const {}),
      quotes: QuoteStats.fromJson(
          (json['quotes'] as Map<String, dynamic>?) ?? const {}),
      categories: CategoryStats.fromJson(
          (json['categories'] as Map<String, dynamic>?) ?? const {}),
      reports: ReportStats.fromJson(
          (json['reports'] as Map<String, dynamic>?) ?? const {}),
      charts: AdminCharts.fromJson(
          (json['charts'] as Map<String, dynamic>?) ?? const {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'users': users.toJson(),
        'artisans': artisans.toJson(),
        'requests': requests.toJson(),
        'quotes': quotes.toJson(),
        'categories': categories.toJson(),
        'reports': reports.toJson(),
        'charts': charts.toJson(),
      };

  @override
  List<Object?> get props =>
      [users, artisans, requests, quotes, categories, reports, charts];
}
