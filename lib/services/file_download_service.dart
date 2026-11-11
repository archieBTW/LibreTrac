import 'dart:typed_data';

import 'file_download_service_stub.dart'
    if (dart.library.js_interop) 'file_download_service_web.dart';

Future<bool> downloadFileToBrowser(
  String fileName,
  Uint8List bytes, {
  String mimeType = 'application/zip',
}) =>
    downloadFilePlatform(fileName, bytes, mimeType: mimeType);

Future<bool> shareFileOnWeb(
  String fileName,
  Uint8List bytes, {
  String mimeType = 'application/zip',
  String? title,
}) =>
    shareFilePlatform(fileName, bytes, mimeType: mimeType, title: title);

bool canShareFilesOnWeb() => canShareFilesPlatform();

bool openFileInNewTabOnWeb(
  String fileName,
  Uint8List bytes, {
  String mimeType = 'application/octet-stream',
}) =>
    openFilePlatform(fileName, bytes, mimeType: mimeType);

Future<bool> restoreStorageBackupOnWeb(String jsonStr) =>
    restoreStorageBackupPlatform(jsonStr);

Future<String?> extractStorageBackupDataOnWeb(String jsonStr) =>
    extractStorageBackupDataPlatform(jsonStr);
