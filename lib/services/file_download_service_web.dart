import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('canShareFiles')
external JSBoolean? _jsCanShareFiles();

@JS('shareBlobFile')
external JSPromise<JSBoolean>? _jsShareBlobFile(
  JSString fileName,
  JSString base64Data,
  JSString mimeType,
  JSString title,
);

@JS('downloadBlobFile')
external JSBoolean? _jsDownloadBlobFile(
  JSString fileName,
  JSString base64Data,
  JSString mimeType,
);

@JS('openBlobFile')
external JSBoolean? _jsOpenBlobFile(
  JSString fileName,
  JSString base64Data,
  JSString mimeType,
);

bool canShareFilesPlatform() {
  try {
    return _jsCanShareFiles()?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

Future<bool> shareFilePlatform(
  String fileName,
  Uint8List bytes, {
  String mimeType = 'application/zip',
  String? title,
}) async {
  try {
    final base64Str = base64Encode(bytes);
    final promise = _jsShareBlobFile(
      fileName.toJS,
      base64Str.toJS,
      mimeType.toJS,
      (title ?? fileName).toJS,
    );
    if (promise == null) return false;
    final jsBool = await promise.toDart;
    return jsBool.toDart;
  } catch (_) {
    return false;
  }
}

Future<bool> downloadFilePlatform(
  String fileName,
  Uint8List bytes, {
  String mimeType = 'application/zip',
}) async {
  try {
    final base64Str = base64Encode(bytes);
    final jsBool = _jsDownloadBlobFile(
      fileName.toJS,
      base64Str.toJS,
      mimeType.toJS,
    );
    return jsBool?.toDart ?? false;
  } catch (_) {
    return false;
  }
}

bool openFilePlatform(
  String fileName,
  Uint8List bytes, {
  String mimeType = 'application/octet-stream',
}) {
  try {
    final base64Str = base64Encode(bytes);
    return _jsOpenBlobFile(
      fileName.toJS,
      base64Str.toJS,
      mimeType.toJS,
    )?.toDart ?? false;
  } catch (_) {
    return false;
  }
}
