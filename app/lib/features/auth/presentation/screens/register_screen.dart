import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../artisans/domain/models/artisan.dart';
import '../../../artisans/domain/repositories/artisan_repository.dart';
import '../bloc/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _cityController = TextEditingController(text: 'Ouagadougou');
  String _selectedRole = 'client';
  List<Category> _categories = const [];
  String? _categoryId;

  bool get _isArtisan => _selectedRole == 'artisan';

  @override
  void initState() {
    super.initState();
    getIt<ArtisanRepository>().getCategories().then((r) {
      if (mounted) setState(() => _categories = r.dataOrNull ?? const []);
    });
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: AppTheme.inputFillColor,
      );

  @override
  void dispose() {
    _specialtyController.dispose();
    _cityController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            RegisterSubmitted(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              fullName: _nameController.text.trim(),
              phone: _phoneController.text.trim(),
              role: _selectedRole,
              // An artisan's trade decides which client requests they receive.
              specialty: _isArtisan ? _specialtyController.text.trim() : null,
              city: _isArtisan ? _cityController.text.trim() : null,
              categoryId: _isArtisan ? _categoryId : null,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailureState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.destructiveColor,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'client',
                          label: Text('Client'),
                          icon: Icon(Icons.person),
                        ),
                        ButtonSegment(
                          value: 'artisan',
                          label: Text('Artisan'),
                          icon: Icon(Icons.handyman),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (set) {
                        setState(() => _selectedRole = set.first);
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppTheme.inputFillColor,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Nom requis' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppTheme.inputFillColor,
                      ),
                      validator: (v) => v == null || !v.contains('@')
                          ? 'Email valide requis'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Numéro de téléphone (+226...)',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppTheme.inputFillColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe (min 6 caractères)',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppTheme.inputFillColor,
                      ),
                      validator: (v) =>
                          v == null || v.length < 6 ? 'Min 6 caractères' : null,
                    ),
                    if (_isArtisan) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _categoryId,
                        decoration: _decoration(
                            'Catégorie de métier', Icons.category_outlined),
                        items: [
                          for (final c in _categories)
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                        validator: (v) => _isArtisan && v == null
                            ? 'Choisissez votre métier'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _specialtyController,
                        decoration: _decoration(
                            'Spécialité (ex : Plombier sanitaire)',
                            Icons.handyman_outlined),
                        validator: (v) =>
                            _isArtisan && (v == null || v.trim().length < 2)
                                ? 'Spécialité requise'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cityController,
                        decoration:
                            _decoration('Ville', Icons.location_city_outlined),
                        validator: (v) =>
                            _isArtisan && (v == null || v.trim().length < 2)
                                ? 'Ville requise'
                                : null,
                      ),
                    ],
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Créer mon compte',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Déjà un compte ? Se connecter'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
