import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic details;

  const Failure(this.message, {this.code, this.details});

  @override
  List<Object?> get props => [message, code, details];
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message,
      {super.code, super.details, this.statusCode});
}

class ValidationFailure extends Failure {
  final List<dynamic>? errors;
  const ValidationFailure(super.message, {this.errors})
      : super(code: 'VALIDATION_ERROR', details: errors);

  /// Extrait les erreurs 422 sous forme `{champ: message}` pour l'affichage sous les champs (F10).
  Map<String, String> get fieldErrors {
    final map = <String, String>{};
    if (errors == null) return map;
    for (final item in errors!) {
      if (item is Map) {
        final field = item['field']?.toString();
        final msg = item['message']?.toString();
        if (field != null &&
            field.isNotEmpty &&
            msg != null &&
            msg.isNotEmpty) {
          map[field] = msg;
        }
      }
    }
    return map;
  }
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentification requise'])
      : super(code: 'UNAUTHORIZED');
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message = 'Accès non autorisé'])
      : super(code: 'FORBIDDEN');
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Problème de connexion internet'])
      : super(code: 'NETWORK_ERROR');
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Erreur de cache local'])
      : super(code: 'CACHE_ERROR');
}
