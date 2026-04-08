import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

const int _maxSizeBytes = 250 * 1024; // 250 KB

class ImageResult {
  final Uint8List bytes;
  final String mimeType;
  const ImageResult({required this.bytes, required this.mimeType});
}

class ImageValidationException implements Exception {
  final String message;
  const ImageValidationException(this.message);
  @override
  String toString() => message;
}

/// Returns true if [file] is within the 250 KB limit.
/// If the file exceeds the limit, shows an [AlertDialog] and returns false.
/// Does NOT throw — the caller simply checks the return value.
Future<bool> validateImageSize(BuildContext context, XFile file) async {
  final bytes = await file.readAsBytes();
  if (bytes.length <= _maxSizeBytes) return true;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Image Too Large'),
      content: const Text(
        'The selected image exceeds 250 KB. Please choose a smaller image.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  return false;
}

/// Validates [file] format (jpg/png only) and returns an [ImageResult].
///
/// Assumes the file size has already been validated with [validateImageSize].
/// Throws [ImageValidationException] only for unsupported formats.
Future<ImageResult> validateAndCompressImage(XFile file) async {
  final ext = file.name.split('.').last.toLowerCase();
  if (!['jpg', 'jpeg', 'png'].contains(ext)) {
    throw ImageValidationException('Only JPG/PNG images are allowed.');
  }

  final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
  final format = ext == 'png' ? CompressFormat.png : CompressFormat.jpeg;

  var bytes = await file.readAsBytes();

  if (bytes.length <= _maxSizeBytes) {
    return ImageResult(bytes: bytes, mimeType: mimeType);
  }

  // Progressively reduce quality until the image fits 250 KB.
  for (final quality in [80, 60, 40, 20]) {
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      quality: quality,
      format: format,
    );
    if (compressed.length <= _maxSizeBytes) {
      return ImageResult(bytes: compressed, mimeType: mimeType);
    }
    bytes = compressed;
  }

  // Fallback: return best-compressed result even if slightly over limit.
  return ImageResult(bytes: bytes, mimeType: mimeType);
}
