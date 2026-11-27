import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/models/admin_category.dart';
import '../../domain/repositories/admin_categories_repository.dart';

// ── Events ──────────────────────────────────────────────────────────────────

abstract class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoriesEvent {
  const LoadCategories();
}

class CreateCategorySubmitted extends CategoriesEvent {
  final String name;
  final String? icon;
  final String? description;
  final bool isActive;

  const CreateCategorySubmitted({
    required this.name,
    this.icon,
    this.description,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [name, icon, description, isActive];
}

class UpdateCategorySubmitted extends CategoriesEvent {
  final String id;
  final String? name;
  final String? icon;
  final String? description;
  final bool? isActive;

  const UpdateCategorySubmitted({
    required this.id,
    this.name,
    this.icon,
    this.description,
    this.isActive,
  });

  @override
  List<Object?> get props => [id, name, icon, description, isActive];
}

class ToggleCategoryActiveOptimistic extends CategoriesEvent {
  final String id;
  final bool isActive;

  const ToggleCategoryActiveOptimistic({
    required this.id,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, isActive];
}

class DeleteCategoryRequested extends CategoriesEvent {
  final String id;
  const DeleteCategoryRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class ClearCategoryFormErrors extends CategoriesEvent {
  const ClearCategoryFormErrors();
}

// ── States (F7 + F10) ───────────────────────────────────────────────────────

abstract class CategoriesState extends Equatable {
  const CategoriesState();

  @override
  List<Object?> get props => [];
}

class CategoriesInitial extends CategoriesState {}

class CategoriesLoading extends CategoriesState {}

class CategoriesEmpty extends CategoriesState {
  const CategoriesEmpty();
}

class CategoriesError extends CategoriesState {
  final String message;
  const CategoriesError(this.message);

  @override
  List<Object?> get props => [message];
}

class CategoriesLoaded extends CategoriesState {
  final List<AdminCategory> categories;
  final bool isSubmitting;
  final Map<String, String> formFieldErrors;
  final String? actionMessage;
  final bool actionIsError;
  final bool formSuccess;

  const CategoriesLoaded({
    required this.categories,
    this.isSubmitting = false,
    this.formFieldErrors = const {},
    this.actionMessage,
    this.actionIsError = false,
    this.formSuccess = false,
  });

  CategoriesLoaded copyWith({
    List<AdminCategory>? categories,
    bool? isSubmitting,
    Map<String, String>? formFieldErrors,
    String? actionMessage,
    bool clearActionMessage = false,
    bool? actionIsError,
    bool? formSuccess,
  }) {
    return CategoriesLoaded(
      categories: categories ?? this.categories,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      formFieldErrors: formFieldErrors ?? this.formFieldErrors,
      actionMessage:
          clearActionMessage ? null : (actionMessage ?? this.actionMessage),
      actionIsError: actionIsError ?? this.actionIsError,
      formSuccess: formSuccess ?? false,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        isSubmitting,
        formFieldErrors,
        actionMessage,
        actionIsError,
        formSuccess,
      ];
}

// ── BLoC ────────────────────────────────────────────────────────────────────

class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  final AdminCategoriesRepository _repository;

  CategoriesBloc({required AdminCategoriesRepository repository})
      : _repository = repository,
        super(CategoriesInitial()) {
    on<LoadCategories>(_onLoad);
    on<CreateCategorySubmitted>(_onCreate);
    on<UpdateCategorySubmitted>(_onUpdate);
    on<ToggleCategoryActiveOptimistic>(_onToggleActive);
    on<DeleteCategoryRequested>(_onDelete);
    on<ClearCategoryFormErrors>(_onClearFormErrors);
  }

  Future<void> _onLoad(
    LoadCategories event,
    Emitter<CategoriesState> emit,
  ) async {
    emit(CategoriesLoading());
    final result = await _repository.listCategories();

    result.when(
      success: (list) {
        if (list.isEmpty) {
          emit(const CategoriesEmpty());
        } else {
          emit(CategoriesLoaded(categories: list));
        }
      },
      failure: (failure) => emit(CategoriesError(failure.message)),
    );
  }

  Future<void> _onCreate(
    CreateCategorySubmitted event,
    Emitter<CategoriesState> emit,
  ) async {
    final current = state;
    final previousList = current is CategoriesLoaded
        ? current.categories
        : const <AdminCategory>[];

    emit(
      CategoriesLoaded(
        categories: previousList,
        isSubmitting: true,
        formFieldErrors: const {},
      ),
    );

    final result = await _repository.createCategory(
      name: event.name,
      icon: event.icon,
      description: event.description,
      isActive: event.isActive,
    );

    result.when(
      success: (created) {
        final updated = [
          ...previousList,
          created
        ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        emit(
          CategoriesLoaded(
            categories: updated,
            isSubmitting: false,
            actionMessage: 'Catégorie « ${created.name} » créée',
            actionIsError: false,
            formSuccess: true,
          ),
        );
      },
      failure: (failure) {
        final fieldErrors = failure is ValidationFailure
            ? failure.fieldErrors
            : const <String, String>{};
        emit(
          CategoriesLoaded(
            categories: previousList,
            isSubmitting: false,
            formFieldErrors: fieldErrors,
            actionMessage: failure.message,
            actionIsError: true,
          ),
        );
      },
    );
  }

  Future<void> _onUpdate(
    UpdateCategorySubmitted event,
    Emitter<CategoriesState> emit,
  ) async {
    final current = state;
    if (current is! CategoriesLoaded) return;

    emit(
      current.copyWith(
        isSubmitting: true,
        formFieldErrors: const {},
        clearActionMessage: true,
      ),
    );

    final result = await _repository.updateCategory(
      event.id,
      name: event.name,
      icon: event.icon,
      description: event.description,
      isActive: event.isActive,
    );

    result.when(
      success: (updatedCat) {
        final updatedList = current.categories
            .map((c) => c.id == updatedCat.id ? updatedCat : c)
            .toList()
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        emit(
          CategoriesLoaded(
            categories: updatedList,
            isSubmitting: false,
            actionMessage: 'Catégorie « ${updatedCat.name} » mise à jour',
            actionIsError: false,
            formSuccess: true,
          ),
        );
      },
      failure: (failure) {
        final fieldErrors = failure is ValidationFailure
            ? failure.fieldErrors
            : const <String, String>{};
        emit(
          current.copyWith(
            isSubmitting: false,
            formFieldErrors: fieldErrors,
            actionMessage: failure.message,
            actionIsError: true,
          ),
        );
      },
    );
  }

  Future<void> _onToggleActive(
    ToggleCategoryActiveOptimistic event,
    Emitter<CategoriesState> emit,
  ) async {
    final current = state;
    if (current is! CategoriesLoaded) return;

    final previous = current.categories;
    final optimistic = previous.map((c) {
      return c.id == event.id ? c.copyWith(isActive: event.isActive) : c;
    }).toList();

    emit(current.copyWith(categories: optimistic, clearActionMessage: true));

    final result =
        await _repository.updateCategory(event.id, isActive: event.isActive);

    result.when(
      success: (updatedCat) {
        final synced = optimistic
            .map((c) => c.id == updatedCat.id ? updatedCat : c)
            .toList();
        emit(
          current.copyWith(
            categories: synced,
            actionMessage: updatedCat.isActive
                ? 'Catégorie activée'
                : 'Catégorie désactivée',
            actionIsError: false,
          ),
        );
      },
      failure: (failure) {
        // Rollback on failure
        emit(
          current.copyWith(
            categories: previous,
            actionMessage: 'Échec de la mise à jour : ${failure.message}',
            actionIsError: true,
          ),
        );
      },
    );
  }

  Future<void> _onDelete(
    DeleteCategoryRequested event,
    Emitter<CategoriesState> emit,
  ) async {
    final current = state;
    if (current is! CategoriesLoaded) return;

    final previous = current.categories;
    final result = await _repository.deleteCategory(event.id);

    result.when(
      success: (_) {
        final remaining = previous.where((c) => c.id != event.id).toList();
        if (remaining.isEmpty) {
          emit(const CategoriesEmpty());
        } else {
          emit(
            CategoriesLoaded(
              categories: remaining,
              actionMessage: 'Catégorie supprimée',
              actionIsError: false,
            ),
          );
        }
      },
      failure: (failure) {
        emit(
          current.copyWith(
            actionMessage: failure.message,
            actionIsError: true,
          ),
        );
      },
    );
  }

  void _onClearFormErrors(
    ClearCategoryFormErrors event,
    Emitter<CategoriesState> emit,
  ) {
    final current = state;
    if (current is CategoriesLoaded) {
      emit(
        current.copyWith(
          formFieldErrors: const {},
          clearActionMessage: true,
        ),
      );
    }
  }
}
