// lib/data/services/image_service.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/api_constants.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  final ApiClient   _api;
  ImageService(this._api);

  // Max 5MB, JPEG/PNG/WEBP only
  static const int  _maxBytes  = 5 * 1024 * 1024;
  static const List<String> _allowed = ['jpg','jpeg','png','webp'];

  Future<File?> pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 72,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return null;
      return _validate(File(picked.path));
    } catch (_) {
      return null;
    }
  }

  Future<File?> pickFromCamera() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 72,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return null;
      return _validate(File(picked.path));
    } catch (_) {
      return null;
    }
  }

  Future<List<File>> pickMultiple({int max = 5}) async {
    try {
      final picked = await _picker.pickMultiImage(
        imageQuality: 72, maxWidth: 800, maxHeight: 800,
      );
      final results = <File>[];
      for (final p in picked.take(max)) {
        final f = _validate(File(p.path));
        if (f != null) results.add(f);
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  // Extracts file extension from just the filename, not the full path.
  static String _ext(String path) {
    final filename = path.split('/').last;
    final dot = filename.lastIndexOf('.');
    if (dot == -1) return 'jpg';
    final e = filename.substring(dot + 1).toLowerCase();
    return _allowed.contains(e) ? e : 'jpg';
  }

  File? _validate(File file) {
    final filename = file.path.split('/').last;
    final dot = filename.lastIndexOf('.');
    if (dot != -1) {
      final ext = filename.substring(dot + 1).toLowerCase();
      if (!_allowed.contains(ext)) return null;
    }
    if (file.lengthSync() > _maxBytes) return null;
    return file;
  }

  /// Returns the uploaded photo URL, or null on failure.
  /// Pass [onError] to receive the server's error message for display.
  Future<String?> uploadProfilePhoto(File file, {void Function(String)? onError}) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(file.path,
          filename: 'profile.${_ext(file.path)}'),
    });
    final res = await _api.postForm(ApiConstants.uploadPhoto, form);
    if (!res.success) {
      onError?.call(res.message.isNotEmpty ? res.message : 'Upload failed (status ${res.statusCode})');
      return null;
    }
    return (res.data?['photo_url'] ?? res.data?['profile_photo']) as String?;
  }

  Future<String?> uploadProductImage(File file, {void Function(String)? onError}) async {
    final form = FormData.fromMap({
      'photo': await MultipartFile.fromFile(file.path,
          filename: 'product.${_ext(file.path)}'),
    });
    final res = await _api.postForm(ApiConstants.uploadProductImage, form);
    if (!res.success) {
      onError?.call(res.message.isNotEmpty ? res.message : 'Upload failed (status ${res.statusCode})');
      return null;
    }
    return res.data?['image_url'] as String?;
  }
}
