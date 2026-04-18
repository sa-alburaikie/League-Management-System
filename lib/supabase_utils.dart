import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'dart:typed_data';

class SupabaseUtils {
  static final supabase.SupabaseClient _client = supabase.Supabase.instance.client;

  /// Uploads an image to Supabase Storage and returns the public URL.
  /// Supports both web (Uint8List) and native (File) platforms.
  /// Returns null if the upload fails.
  static Future<String?> uploadImage(dynamic imageData, String userId) async {
    try {
      // إنشاء اسم ملف فريد باستخدام userId وتاريخ الرفع
      final String fileName = "${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final String path = 'images/$fileName';

      if (kIsWeb) {
        // على الويب: imageData هو Uint8List
        await _client.storage.from('images').uploadBinary(
          path,
          imageData as Uint8List,
          fileOptions: const supabase.FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );
      } else {
        // على المنصات الأصلية: imageData هو File
        await _client.storage.from('images').upload(
          path,
          imageData as File,
          fileOptions: const supabase.FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );
      }

      // الحصول على الرابط العام للصورة
      final String publicUrl = _client.storage.from('images').getPublicUrl(path);

      return publicUrl;
    } catch (e, stackTrace) {
      print('Error uploading image to Supabase: $e');
      print('StackTrace: $stackTrace');
      return null;
    }
  }
}