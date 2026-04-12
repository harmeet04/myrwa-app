import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  static final _storage = FirebaseStorage.instance;
  static final _picker = ImagePicker();

  /// Pick image from camera or gallery. Returns the File or null.
  static Future<File?> pickImage({required ImageSource source}) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  /// Upload a file to Firebase Storage and return the download URL.
  static Future<String?> uploadImage(File file, String path) async {
    try {
      debugPrint('StorageService: uploading to $path');
      final ref = _storage.ref().child(path);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      debugPrint('StorageService: upload success, URL = $url');
      return url;
    } catch (e) {
      debugPrint('StorageService: upload FAILED — $e');
      return null;
    }
  }

  /// Show a bottom sheet to choose camera or gallery, then pick image.
  static Future<File?> showImagePicker(BuildContext context) async {
    ImageSource? source;
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                source = ImageSource.camera;
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                source = ImageSource.gallery;
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    return pickImage(source: source!);
  }
}
