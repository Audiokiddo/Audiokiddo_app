import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'download_stub.dart' if (dart.library.js_interop) 'download_web.dart';

/// A file picked for a catalog asset: size and SHA-256 are computed in the browser.
/// In local mode the file itself is not uploaded; Etap 3 uploads it to Supabase Storage.
class PickedAsset {
  const PickedAsset({required this.name, required this.bytes, required this.sha256});

  final String name;
  final int bytes;
  final String sha256;

  String get extension => name.contains('.') ? name.substring(name.lastIndexOf('.')) : '';
}

/// File and storage access, faked in tests.
abstract interface class StudioIo {
  Future<String?> readDraft();
  Future<void> writeDraft(String json);
  Future<String?> pickCatalogJson();
  Future<PickedAsset?> pickAsset({required List<String> extensions});
  void download(String fileName, String content);
}

class BrowserStudioIo implements StudioIo {
  static const _draftKey = 'studio_catalog_draft';

  @override
  Future<String?> readDraft() async => (await SharedPreferences.getInstance()).getString(_draftKey);

  @override
  Future<void> writeDraft(String json) async => (await SharedPreferences.getInstance()).setString(_draftKey, json);

  @override
  Future<String?> pickCatalogJson() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    return file?.readAsString();
  }

  @override
  Future<PickedAsset?> pickAsset({required List<String> extensions}) async {
    final file = await openFile(
      acceptedTypeGroups: [XTypeGroup(label: 'Pliki', extensions: extensions)],
    );
    if (file == null) return null;
    final data = await file.readAsBytes();
    return PickedAsset(name: file.name, bytes: data.length, sha256: sha256.convert(data).toString());
  }

  @override
  void download(String fileName, String content) => downloadTextFile(fileName, content);
}
