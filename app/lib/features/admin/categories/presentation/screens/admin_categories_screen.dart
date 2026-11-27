import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../presentation/widgets/admin_shared_widgets.dart';
import '../../domain/models/admin_category.dart';
import '../bloc/categories_bloc.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<CategoriesBloc>();
    if (bloc.state is CategoriesInitial) {
      bloc.add(const LoadCategories());
    }
  }

  void _openCategorySheet(BuildContext context, {AdminCategory? existing}) {
    context.read<CategoriesBloc>().add(const ClearCategoryFormErrors());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<CategoriesBloc>(),
        child: _CategoryFormSheet(existing: existing),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AdminCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la catégorie'),
        content: Text(
          'Voulez-vous vraiment supprimer « ${category.name} » ? '
          'Cette action échoue si des artisans ou demandes utilisent déjà ce métier.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.adminDanger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<CategoriesBloc>().add(DeleteCategoryRequested(category.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPad = width >= 760 ? 24.0 : 16.0;

    return AdminShellScaffold(
      currentIndex: 2,
      body: BlocConsumer<CategoriesBloc, CategoriesState>(
        listener: (context, state) {
          if (state is CategoriesLoaded && state.actionMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.actionMessage!),
                  backgroundColor: state.actionIsError
                      ? AppTheme.adminDanger
                      : AppTheme.adminSuccess,
                ),
              );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPad,
                  16,
                  horizontalPad,
                  12,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Catégories de métiers',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.adminIndigo,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Activez, modifiez ou ajoutez les corps de métier',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openCategorySheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.adminIndigo,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text(
                        'Ajouter',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _buildBody(context, state, width, horizontalPad),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CategoriesState state,
    double width,
    double horizontalPad,
  ) {
    if (state is CategoriesLoading || state is CategoriesInitial) {
      return const AdminLoadingView(message: 'Chargement des catégories...');
    }

    if (state is CategoriesError) {
      return AdminErrorView(
        message: state.message,
        onRetry: () =>
            context.read<CategoriesBloc>().add(const LoadCategories()),
      );
    }

    if (state is CategoriesEmpty) {
      return AdminEmptyView(
        icon: Icons.category_outlined,
        title: 'Aucune catégorie configurée',
        subtitle:
            'Ajoutez votre premier corps de métier pour structurer le catalogue.',
        actionLabel: 'Actualiser',
        onAction: () =>
            context.read<CategoriesBloc>().add(const LoadCategories()),
      );
    }

    final loaded = state as CategoriesLoaded;
    final columns = width >= 1040 ? 3 : (width >= 680 ? 2 : 1);

    return RefreshIndicator(
      color: AppTheme.adminIndigo,
      onRefresh: () async =>
          context.read<CategoriesBloc>().add(const LoadCategories()),
      child: columns == 1
          ? ListView.separated(
              padding: EdgeInsets.fromLTRB(
                horizontalPad,
                4,
                horizontalPad,
                24,
              ),
              itemCount: loaded.categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final category = loaded.categories[index];
                return _CategoryCard(
                  category: category,
                  onEdit: () => _openCategorySheet(context, existing: category),
                  onDelete: () => _confirmDelete(context, category),
                  onToggle: (val) => context.read<CategoriesBloc>().add(
                        ToggleCategoryActiveOptimistic(
                          id: category.id,
                          isActive: val,
                        ),
                      ),
                );
              },
            )
          : GridView.builder(
              padding: EdgeInsets.fromLTRB(
                horizontalPad,
                4,
                horizontalPad,
                24,
              ),
              itemCount: loaded.categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 146,
              ),
              itemBuilder: (_, index) {
                final category = loaded.categories[index];
                return _CategoryCard(
                  category: category,
                  onEdit: () => _openCategorySheet(context, existing: category),
                  onDelete: () => _confirmDelete(context, category),
                  onToggle: (val) => context.read<CategoriesBloc>().add(
                        ToggleCategoryActiveOptimistic(
                          id: category.id,
                          isActive: val,
                        ),
                      ),
                );
              },
            ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final AdminCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: category.isActive
              ? AppTheme.adminCardBorder
              : AppTheme.textMuted.withValues(alpha: 0.35),
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: category.isActive
                      ? AppTheme.adminAmberSoft
                      : AppTheme.adminBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  AdminFormatters.categoryIcon(category.icon),
                  color: category.isActive
                      ? AppTheme.adminOrange
                      : AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.adminIndigo,
                      ),
                    ),
                    Text(
                      category.slug.isNotEmpty ? '/${category.slug}' : '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: category.isActive,
                activeTrackColor: AppTheme.adminSuccess,
                onChanged: onToggle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            category.description.isNotEmpty
                ? category.description
                : 'Aucune description renseignée.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AdminStatusChip(
                label: category.isActive ? 'Active' : 'Inactive',
                backgroundColor: category.isActive
                    ? AppTheme.adminMintSoft
                    : AppTheme.adminBackground,
                textColor: category.isActive
                    ? AppTheme.adminSuccess
                    : AppTheme.textSecondary,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Modifier',
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 19,
                  color: AppTheme.adminIndigo,
                ),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: 'Supprimer',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                  color: AppTheme.adminDanger,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  final AdminCategory? existing;
  const _CategoryFormSheet({this.existing});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _selectedIcon;
  late bool _isActive;

  static const _icons = [
    ('build', 'Général'),
    ('plumbing', 'Plomberie'),
    ('electrical_services', 'Électricité'),
    ('carpenter', 'Menuiserie'),
    ('format_paint', 'Peinture'),
    ('ac_unit', 'Froid / Clim'),
    ('construction', 'Maçonnerie'),
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.existing?.description ?? '');
    _selectedIcon = widget.existing?.icon ?? 'build';
    _isActive = widget.existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<CategoriesBloc>();
    if (widget.existing == null) {
      bloc.add(
        CreateCategorySubmitted(
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          description: _descriptionController.text.trim(),
          isActive: _isActive,
        ),
      );
    } else {
      bloc.add(
        UpdateCategorySubmitted(
          id: widget.existing!.id,
          name: _nameController.text.trim(),
          icon: _selectedIcon,
          description: _descriptionController.text.trim(),
          isActive: _isActive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return BlocConsumer<CategoriesBloc, CategoriesState>(
      listener: (context, state) {
        if (state is CategoriesLoaded && state.formSuccess) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final loaded = state is CategoriesLoaded ? state : null;
        final isSubmitting = loaded?.isSubmitting ?? false;
        final fieldErrors = loaded?.formFieldErrors ?? const <String, String>{};

        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.existing == null
                        ? 'Nouvelle catégorie'
                        : 'Modifier « ${widget.existing!.name} »',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.adminIndigo,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // F10: Client validation + server 422 field errors under each field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom du métier *',
                      hintText: 'Ex: Plomberie Sanitaire',
                      errorText: fieldErrors['name'],
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 2) {
                        return 'Le nom doit contenir au moins 2 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Courte description des prestations couvertes',
                      errorText: fieldErrors['description'],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Icône associée',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.adminIndigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _icons.map((item) {
                      final selected = _selectedIcon == item.$1;
                      return ChoiceChip(
                        avatar: Icon(
                          AdminFormatters.categoryIcon(item.$1),
                          size: 16,
                          color: selected ? Colors.white : AppTheme.adminIndigo,
                        ),
                        label: Text(item.$2),
                        selected: selected,
                        selectedColor: AppTheme.adminIndigo,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : AppTheme.adminIndigo,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) =>
                            setState(() => _selectedIcon = item.$1),
                      );
                    }).toList(),
                  ),
                  if (fieldErrors['icon'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      fieldErrors['icon']!,
                      style: const TextStyle(
                        color: AppTheme.adminDanger,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Catégorie active',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.adminIndigo,
                      ),
                    ),
                    subtitle: const Text(
                      'Visible dans le catalogue client et artisan',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _isActive,
                    activeTrackColor: AppTheme.adminSuccess,
                    onChanged: (val) => setState(() => _isActive = val),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.adminIndigo,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.existing == null
                                ? 'Créer la catégorie'
                                : 'Enregistrer les modifications',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
