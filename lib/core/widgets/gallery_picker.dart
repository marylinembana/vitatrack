import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../services/image_upload_service.dart';
import 'app_image.dart';

/// Vignette cliquable « Importer depuis la galerie » : ouvre la galerie de
/// l'appareil (photos), téléverse les images choisies vers Supabase Storage
/// et retourne leurs URL publiques. Utilisée partout où l'on pouvait coller
/// un lien image (diplômes, photos d'aliments…).
///
/// [multiple] autorise la sélection de plusieurs images. Un bouton « lien »
/// discret reste disponible en repli (appareil sans galerie accessible).
class GalleryImagePickerTile extends StatefulWidget {
  final ValueChanged<List<String>> onPicked;
  final bool multiple;
  final double size;
  final String label;

  const GalleryImagePickerTile({
    super.key,
    required this.onPicked,
    this.multiple = true,
    this.size = 72,
    this.label = 'Galerie',
  });

  @override
  State<GalleryImagePickerTile> createState() => _GalleryImagePickerTileState();
}

class _GalleryImagePickerTileState extends State<GalleryImagePickerTile> {
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = <XFile>[];
      if (widget.multiple) {
        picked.addAll(await ImagePicker().pickMultiImage(
            imageQuality: 85, maxWidth: 1600, maxHeight: 1600));
      } else {
        final one = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1600,
          maxHeight: 1600,
        );
        if (one != null) picked.add(one);
      }
      final urls = <String>[];
      for (final x in picked) {
        final bytes = await x.readAsBytes();
        final url = await ImageUploadService.uploadBytes(
          bytes,
          fileName: x.name.isNotEmpty ? x.name : 'image.jpg',
          contentType: x.mimeType ?? 'image/jpeg',
        );
        if (url != null) {
          urls.add(url);
        } else if (!kIsWeb) {
          // Repli mobile : garder le chemin local, visible via AppImage.
          urls.add(x.path);
        }
      }
      if (urls.isEmpty && picked.isNotEmpty) {
        messenger.showSnackBar(const SnackBar(
            content: Text('Envoi des images impossible. Réessayez.')));
      }
      if (urls.isNotEmpty) widget.onPicked(urls);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Galerie indisponible sur cet appareil.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pasteLink() async {
    final controller = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lien de l\'image'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'https://…/photo.jpg',
            prefixIcon: Icon(Icons.image_outlined),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('Ajouter')),
        ],
      ),
    );
    controller.dispose();
    if (url != null &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      widget.onPicked([url]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: GestureDetector(
                onTap: _busy ? null : _pick,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        style: BorderStyle.solid),
                  ),
                  child: _busy
                      ? const Center(
                          child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary)))
                      : const Icon(Icons.photo_library_outlined,
                          color: AppColors.primary),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: _busy ? null : _pick,
                  child: Text(widget.label,
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: _busy ? null : _pasteLink,
                  child: const Tooltip(
                    message: 'Coller un lien image (repli)',
                    child: Icon(Icons.link,
                        size: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Gestionnaire d'images (diplômes, documents…) : vignettes existantes
/// supprimables + tile d'import galerie. Remplace l'ancien champ « lien URL ».
class GalleryImageListField extends StatelessWidget {
  final List<String> urls;
  final void Function(List<String> added) onAdded;
  final void Function(int index) onRemoved;
  final String emptyHint;

  const GalleryImageListField({
    super.key,
    required this.urls,
    required this.onAdded,
    required this.onRemoved,
    this.emptyHint = 'Aucun document. Importez depuis votre galerie.',
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.paddingSm,
      runSpacing: AppDimensions.paddingSm,
      children: [
        for (var i = 0; i < urls.length; i++)
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: FoodThumb(imageUrl: urls[i], emoji: '📄', size: 72),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () => onRemoved(i),
                    child: const CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        GalleryImagePickerTile(onPicked: onAdded),
      ],
    );
  }
}
