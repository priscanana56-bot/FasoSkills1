import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../artisans/domain/models/artisan.dart';
import '../../../artisans/domain/repositories/artisan_repository.dart';
import '../../domain/repositories/request_repository.dart';
import '../bloc/request_bloc.dart';

/// Client form: publish a request. Every artisan of the chosen category is notified
/// and can answer with a quote.
class RequestQuoteScreen extends StatefulWidget {
  final String? initialCategoryId;
  const RequestQuoteScreen({super.key, this.initialCategoryId});

  @override
  State<RequestQuoteScreen> createState() => _RequestQuoteScreenState();
}

class _RequestQuoteScreenState extends State<RequestQuoteScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _city = TextEditingController(text: 'Ouagadougou');
  final _address = TextEditingController();

  List<Category> _categories = const [];
  String? _categoryId;
  bool _loadingCategories = true;
  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialCategoryId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final result = await getIt<ArtisanRepository>().getCategories();
    if (!mounted) return;
    setState(() {
      _loadingCategories = false;
      _categories = result.dataOrNull ?? const [];
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _city.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = const {});
    if (_categoryId == null) {
      showFeedback(context, 'Choisissez le type de service', error: true);
      return;
    }
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final result = await getIt<RequestRepository>().createRequest(
      title: _title.text.trim(),
      description: _description.text.trim(),
      categoryId: _categoryId!,
      city: _city.text.trim(),
      address: _address.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    result.when(
      success: (request) {
        context.read<RequestBloc>().add(LoadMyRequests());
        showFeedback(
            context, 'Demande publiée : les artisans du métier sont prévenus');
        context.pushReplacement('/requests/${request.id}');
      },
      failure: (f) {
        if (f is ValidationFailure) {
          setState(() => _fieldErrors = f.fieldErrors);
        }
        showFeedback(context, f.message, error: true);
      },
    );
  }

  InputDecoration _decoration(String label, String field, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: _fieldErrors[field],
        alignLabelWithHint: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Palette.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Palette.border)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: pageAppBar(context, 'Nouvelle demande'),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const Text('Décrivez votre besoin en 1 minute',
                style: TextStyle(fontSize: 14, color: Palette.muted)),
            const SizedBox(height: 16),
            const Text('Type de service',
                style:
                    TextStyle(fontWeight: FontWeight.w800, color: Palette.ink)),
            const SizedBox(height: 8),
            if (_loadingCategories)
              const LinearProgressIndicator(color: Palette.primary)
            else if (_categories.isEmpty)
              TextButton.icon(
                onPressed: _loadCategories,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                    'Impossible de charger les services — réessayer'),
              )
            else
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.15,
                children: [
                  for (final c in _categories)
                    _CategoryTile(
                      category: c,
                      selected: _categoryId == c.id,
                      onTap: () => setState(() => _categoryId = c.id),
                    ),
                ],
              ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Titre', 'title',
                  hint: 'Ex : Fuite d’eau sous l’évier'),
              validator: (v) =>
                  (v ?? '').trim().length < 5 ? 'Au moins 5 caractères' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Description', 'description',
                  hint: 'Que faut-il faire ? Depuis quand ? Urgence ?'),
              validator: (v) => (v ?? '').trim().length < 10
                  ? 'Au moins 10 caractères'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              decoration: _decoration('Ville', 'city'),
              validator: (v) =>
                  (v ?? '').trim().length < 2 ? 'Ville requise' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: _decoration(
                  'Quartier / adresse (facultatif)', 'address',
                  hint: 'Ex : Ouaga 2000, secteur 15'),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: const Text('Publier la demande'),
              style: FilledButton.styleFrom(
                backgroundColor: Palette.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryTile(
      {required this.category, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Palette.primary : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: selected ? Palette.primary : Palette.border),
          ),
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(categoryIcon(category.icon),
                  color: selected ? Colors.white : Palette.primary, size: 26),
              const SizedBox(height: 6),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : Palette.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
