import 'dart:typed_data';

Future<bool> downloadFilePlatform(
  String fileName,
  Uint8List bytes, {
  String mimeType = 'application/zip',
}) async =>
    false;

Future<bool> shareFilePlatform(
  String fileName,
  Uint8List bytes, {
  String mimeType = 'application/zip',
  String? title,
}) async =>
    false;

bool canShareFilesPlatform() => false;

bool openFilePlatform(
  String fileName,
  Uint8List bytes, {
  String mimeType = 'application/octet-stream',
}) =>
    false;

Future<bool> restoreStorageBackupPlatform(String jsonStr) async => false;

Future<String?> extractStorageBackupDataPlatform(String jsonStr) async => null;
