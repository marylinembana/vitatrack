import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/constants/supabase_config.dart';
import 'supabase_bootstrap.dart';

/// Téléverse les images choisies/ capturées depuis l'appareil vers le bucket
/// Supabase `images`, sous le dossier personnel `{uid}/…` (imposé par le RLS).
/// Retourne l'URL publique de l'objet, ou null si l'envoi est impossible.
class ImageUploadService {
  ImageUploadService._();

  static Future<String?> uploadBytes(
    Uint8List bytes, {
    String fileName = 'image.jpg',
    String contentType = 'image/jpeg',
  }) async {
    if (!SupabaseBootstrap.ready) return null;
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;
    final safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = '$uid/${DateTime.now().millisecondsSinceEpoch}_$safe';
    try {
      await client.storage.from(SupabaseConfig.imageBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      return client.storage
          .from(SupabaseConfig.imageBucket)
          .getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }
}
