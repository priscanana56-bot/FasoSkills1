import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stream_transform/stream_transform.dart';
import '../../domain/models/artisan.dart';
import '../../domain/repositories/artisan_repository.dart';

// Event transformer for debouncing search input - Requirement F8
EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounce(duration).switchMap(mapper);
}

// Events
abstract class ArtisanListEvent extends Equatable {
  const ArtisanListEvent();
  @override
  List<Object?> get props => [];
}

class LoadArtisans extends ArtisanListEvent {
  final String? categoryId;
  final String? city;
  const LoadArtisans({this.categoryId, this.city});
  @override
  List<Object?> get props => [categoryId, city];
}

class SearchQueryChanged extends ArtisanListEvent {
  final String query;
  final String? categoryId;
  final String? city;
  const SearchQueryChanged(this.query, {this.categoryId, this.city});
  @override
  List<Object?> get props => [query, categoryId, city];
}

class RefreshArtisans extends ArtisanListEvent {
  final String? categoryId;
  final String? city;
  const RefreshArtisans({this.categoryId, this.city});
  @override
  List<Object?> get props => [categoryId, city];
}

// States (Requirement F7: distinct loading, empty, error with retry, and content states)
abstract class ArtisanListState extends Equatable {
  const ArtisanListState();
  @override
  List<Object?> get props => [];
}

class ArtisanListInitial extends ArtisanListState {}

class ArtisanListLoading extends ArtisanListState {}

class ArtisanListLoaded extends ArtisanListState {
  final List<Artisan> artisans;
  final bool isFromCache;
  const ArtisanListLoaded(this.artisans, {this.isFromCache = false});
  @override
  List<Object?> get props => [artisans, isFromCache];
}

class ArtisanListEmpty extends ArtisanListState {
  final String message;
  const ArtisanListEmpty([this.message = 'Aucun artisan trouvé']);
  @override
  List<Object?> get props => [message];
}

class ArtisanListError extends ArtisanListState {
  final String message;
  const ArtisanListError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ArtisanListBloc extends Bloc<ArtisanListEvent, ArtisanListState> {
  final ArtisanRepository _repository;

  ArtisanListBloc({required ArtisanRepository repository})
      : _repository = repository,
        super(ArtisanListInitial()) {
    on<LoadArtisans>(_onLoadArtisans);
    on<RefreshArtisans>(_onRefreshArtisans);
    // Requirement F8: Deliberate event transformer (debounce 300ms)
    on<SearchQueryChanged>(_onSearchQueryChanged,
        transformer: debounce(const Duration(milliseconds: 300)));
  }

  Future<void> _onLoadArtisans(
      LoadArtisans event, Emitter<ArtisanListState> emit) async {
    emit(ArtisanListLoading());

    // F9: Cache then network pattern. The cache holds the unfiltered list,
    // so it is only shown when no filter is applied.
    final unfiltered = event.categoryId == null && event.city == null;
    final cached = unfiltered ? await _repository.getCachedArtisans() : null;
    if (cached != null && cached.isNotEmpty) {
      emit(ArtisanListLoaded(cached, isFromCache: true));
    }

    final result = await _repository.getArtisans(
      categoryId: event.categoryId,
      city: event.city,
    );

    result.when(
      success: (artisans) {
        if (artisans.isEmpty) {
          emit(const ArtisanListEmpty());
        } else {
          emit(ArtisanListLoaded(artisans, isFromCache: false));
        }
      },
      failure: (failure) {
        // If we already emitted cached items, don't clobber with error
        if (state is! ArtisanListLoaded) {
          emit(ArtisanListError(failure.message));
        }
      },
    );
  }

  Future<void> _onRefreshArtisans(
      RefreshArtisans event, Emitter<ArtisanListState> emit) async {
    final result = await _repository.getArtisans(
      categoryId: event.categoryId,
      city: event.city,
    );

    result.when(
      success: (artisans) {
        if (artisans.isEmpty) {
          emit(const ArtisanListEmpty());
        } else {
          emit(ArtisanListLoaded(artisans, isFromCache: false));
        }
      },
      failure: (failure) => emit(ArtisanListError(failure.message)),
    );
  }

  Future<void> _onSearchQueryChanged(
      SearchQueryChanged event, Emitter<ArtisanListState> emit) async {
    emit(ArtisanListLoading());

    final result = await _repository.getArtisans(
      search: event.query,
      categoryId: event.categoryId,
      city: event.city,
    );

    result.when(
      success: (artisans) {
        if (artisans.isEmpty) {
          emit(ArtisanListEmpty('Aucun résultat pour "${event.query}"'));
        } else {
          emit(ArtisanListLoaded(artisans, isFromCache: false));
        }
      },
      failure: (failure) => emit(ArtisanListError(failure.message)),
    );
  }
}
