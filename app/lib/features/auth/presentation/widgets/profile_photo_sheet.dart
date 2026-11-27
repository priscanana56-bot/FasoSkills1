import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';

/// Modal bottom sheet allowing users to:
/// 1. Pick a photo from Gallery
/// 2. Take a photo with Camera
/// 3. Remove existing photo (reset to default)
Future<void> showProfilePhotoSheet(BuildContext context, User user) async {
  final picker = ImagePicker();

  Future<void> updatePhoto(String? base64Photo) async {
    final result = await getIt<AuthRepository>()
        .updateProfile(profilePicture: base64Photo ?? '');
    if (!context.mounted) return;
    result.when(
      success: (updatedUser) {
        context.read<AuthBloc>().add(UserUpdated(updatedUser));
        showFeedback(
          context,
          base64Photo == null
              ? 'Photo de profil supprimée'
              : 'Photo de profil mise à jour',
        );
      },
      failure: (f) => showFeedback(context, f.message, error: true),
    );
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Photo de profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choisissez une photo pour personnaliser votre profil FasoSkills',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Palette.muted),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Palette.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library_rounded,
                    color: Palette.primary, size: 22),
              ),
              title: const Text('Choisir dans la galerie',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Importer une photo depuis vos albums',
                  style: TextStyle(fontSize: 12, color: Palette.muted)),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 82,
                  );
                  if (picked == null) return;
                  final bytes = await picked.readAsBytes();
                  final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                  await updatePhoto(b64);
                } catch (e) {
                  if (context.mounted) {
                    showFeedback(
                        context, 'Impossible de charger l’image: $e',
                        error: true);
                  }
                }
              },
            ),
            const Divider(height: 12, indent: 64),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Palette.successSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: Palette.success, size: 22),
              ),
              title: const Text('Prendre une photo',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Utiliser directement votre appareil photo',
                  style: TextStyle(fontSize: 12, color: Palette.muted)),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  final picked = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 82,
                  );
                  if (picked == null) return;
                  final bytes = await picked.readAsBytes();
                  final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                  await updatePhoto(b64);
                } catch (e) {
                  if (context.mounted) {
                    showFeedback(
                        context, 'Impossible d’accéder à l’appareil photo: $e',
                        error: true);
                  }
                }
              },
            ),
            if (user.profilePicture != null &&
                user.profilePicture!.trim().isNotEmpty) ...[
              const Divider(height: 12, indent: 64),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Palette.dangerSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Palette.danger, size: 22),
                ),
                title: const Text('Supprimer la photo',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Palette.danger)),
                subtitle: const Text('Rétablir l’image et les initiales par défaut',
                    style: TextStyle(fontSize: 12, color: Palette.muted)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await updatePhoto(null);
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// A tappable circular avatar with an edit badge, showing profile picture or default.
class EditableProfileAvatar extends StatelessWidget {
  final User user;
  final double size;
  final bool verified;

  const EditableProfileAvatar({
    super.key,
    required this.user,
    this.size = 68,
    this.verified = false,
  });

  @override
  Widget build(BuildContext context) {
    final defaultAsset = user.isArtisan
        ? 'assets/image/artisanphoto.png'
        : 'assets/image/userphoto.png';

    return GestureDetector(
      onTap: () => showProfilePhotoSheet(context, user),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Avatar(
            name: user.fullName,
            size: size,
            verified: verified,
            imageUrl: user.profilePicture,
            defaultAsset: defaultAsset,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Palette.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
