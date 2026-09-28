import 'package:ak_core/ak_core.dart';
import 'package:audiokiddo/features/content/content_urls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const asset = AssetRef(path: 'audio/wyobraznia/mikstura.m4a', bytes: 1, sha256: 'x');

  test('store builds fetch a signed link per file', () async {
    final resolver = SignedUrlResolver((path) async => Uri.parse('https://pliki.test/get.php?p=$path'));
    expect((await resolver.urlFor(asset)).queryParameters['p'], asset.path);
  });

  test('no link (no access, offline) is a recoverable error, not a crash', () async {
    final resolver = SignedUrlResolver((_) async => null);
    expect(() => resolver.urlFor(asset), throwsA(isA<ContentUnavailable>()));
  });
}
