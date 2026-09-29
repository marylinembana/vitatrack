import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_colors.dart';
import '../services/image_upload_service.dart';
import 'app_text_field.dart';
import 'profile_avatar.dart';

/// Sélectionne une photo de profil via une feuille d'options :
/// caméra, galerie, saisie d'une URL, ou suppression de la photo actuelle.
///
/// Retourne le chemin fichier local / l'URL choisie, '' pour supprimer,
/// ou null si l'utilisateur annule. Fonctionne sur mobile (caméra + galerie)
/// et sur bureau (galerie via file_selector, URL en repli).
Future<String?> pickPhotoSheet(
  BuildContext context, {
  required String? currentPhoto,
}) async {
  final hasPhoto = currentPhoto != null && currentPhoto.trim().isNotEmpty;

  final choice = await showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            height: 4,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Text('Photo de profil',
              style: Theme.of(sheetContext).textTheme.titleLarge),
          if (hasPhoto)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                currentPhoto.startsWith('http')
                    ? 'Photo actuelle : image en ligne'
                    : 'Photo actuelle : depuis l\'appareil',
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 6),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined,
                color: AppColors.primary),
            title: const Text('Choisir depuis la galerie'),
            onTap: () => Navigator.of(sheetContext).pop('gallery'),
          ),
          if (currentPhoto == null || currentPhoto.startsWith('http'))
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primary),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.of(sheetContext).pop('camera'),
            ),
          ListTile(
            leading: const Icon(Icons.link, color: AppColors.textSecondary),
            title: const Text('Utiliser un lien image (URL)',
                style: TextStyle(color: AppColors.textSecondary)),
            onTap: () => Navigator.of(sheetContext).pop('url'),
          ),
          if (hasPhoto)
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Supprimer la photo',
                  style: TextStyle(color: AppColors.error)),
              onTap: () => Navigator.of(sheetContext).pop(''),
            ),
          const SizedBox(height: 6),
        ],
      ),
    ),
  );
  if (choice == null) return null;
  if (!context.mounted) return null;

  switch (choice) {
    case 'camera':
      return _pickFromPicker(context, ImageSource.camera);
    case 'gallery':
      return _pickFromPicker(context, ImageSource.gallery);
    case 'url':
      return _promptUrl(context);
    default:
      return choice; // '' = suppression
  }
}

Future<String?> _pickFromPicker(
    BuildContext context, ImageSource source) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );
    if (picked == null) return null;
    // Import depuis l'appareil (web comme mobile) : on téléverse les octets
    // vers Supabase Storage et on retourne directement l'URL publique.
    final bytes = await picked.readAsBytes();
    final url = await ImageUploadService.uploadBytes(
      bytes,
      fileName: picked.name,
      contentType: picked.mimeType ?? 'image/jpeg',
    );
    if (url != null) return url;
    // Repli mobile : conserver le chemin local si l'envoi échoue.
    if (!kIsWeb) return File(picked.path).absolute.path;
    messenger.showSnackBar(const SnackBar(
        content: Text('Envoi de l\'image impossible. Réessayez ou utilisez un lien (URL).')));
    return null;
  } catch (_) {
    messenger.showSnackBar(const SnackBar(
        content: Text('Caméra ou galerie indisponible sur cet appareil. '
            'Utilisez le lien image (URL).')));
    return null;
  }
}

Future<String?> _promptUrl(BuildContext context) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Lien de la photo'),
      content: AppTextField(
        controller: controller,
        label: 'https://…/ma-photo.jpg',
        icon: Icons.image_outlined,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null || result.isEmpty) return null;
  if (!result.startsWith('http://') && !result.startsWith('https://')) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Le lien doit commencer par http:// ou https://')));
    }
    return null;
  }
  return result;
}

/// Avatar de profil cliquable avec badge appareil photo : ouvre la feuille
/// de sélection et notifie le résultat ([onChanged] : chemin, URL ou '').
class PhotoPickerAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;
  final ValueChanged<String?> onChanged;

  const PhotoPickerAvatar({
    super.key,
    required this.photoUrl,
    required this.name,
    required this.onChanged,
    this.radius = 46,
  });

  Future<void> _open(BuildContext context) async {
    final result = await pickPhotoSheet(context, currentPhoto: photoUrl);
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ProfileAvatar(
            name: name,
            photoUrl: photoUrl,
            radius: radius,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              height: radius * 0.52,
              width: radius * 0.52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(Icons.photo_camera,
                  size: radius * 0.3, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Libellé discret sous l'avatar indiquant comment changer la photo.
Widget photoHintLabel(BuildContext context) => Text(
      'Touchez l\'avatar pour prendre ou choisir une photo.',
      style: Theme.of(context).textTheme.bodySmall,
      textAlign: TextAlign.center,
    );
