import 'json.dart';
import 'script/model.dart';

enum ContentKind { audioGame, song, interactiveGame }

enum ContentAccess { free, paid }

/// Everyday situations used by the "Co robicie?" shelf and filters.
enum Situation { podroz, przedSnem, wDomu, czekanie }

/// What a family needs for a given activity; shown on the details screen.
enum Requirement { mikrofon, miejsceDoRuchu, kartkaIOlowek, wydrukPdf }

/// A downloadable file referenced by the catalog.
class AssetRef {
  const AssetRef({required this.path, required this.bytes, required this.sha256});

  factory AssetRef.fromJson(JsonReader r) =>
      AssetRef(path: r.string('path'), bytes: r.integer('bytes', min: 1), sha256: r.string('sha256'));

  /// Path inside the storage bucket, e.g. `audio/wyobraznia/magiczny-sklep.m4a`.
  final String path;
  final int bytes;
  final String sha256;
}

class Pack {
  const Pack({
    required this.id,
    required this.title,
    required this.ageMin,
    required this.colorToken,
    required this.description,
    this.storeProductId,
    this.cover,
    this.releasedOn,
    this.guide,
  });

  factory Pack.fromJson(JsonReader r) => Pack(
    id: r.string('id'),
    title: r.string('title'),
    ageMin: r.integer('age_min', min: 0, max: 18),
    colorToken: r.string('color'),
    description: r.string('description'),
    storeProductId: r.optString('store_product_id'),
    cover: r.optObject('cover') == null ? null : AssetRef.fromJson(r.object('cover')),
    releasedOn: r.optDate('released'),
    guide: r.optObject('guide') == null ? null : AssetRef.fromJson(r.object('guide')),
  );

  final String id;
  final String title;
  final int ageMin;

  /// The pack's product guide for parents (PDF): what is inside and how to play. A free file,
  /// so it can be read before buying.
  final AssetRef? guide;

  /// When the pack went on sale; "Nowe" for a while after (see [isNewAt]).
  final DateTime? releasedOn;

  /// Name of a brand colour token (e.g. `lavender`), resolved by the app theme.
  final String colorToken;
  final String description;
  final String? storeProductId;
  final AssetRef? cover;
}

class ContentItem {
  const ContentItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.parentDescription,
    required this.ageMin,
    required this.durationSec,
    required this.access,
    required this.audio,
    this.packId,
    this.subtitle,
    this.ageMax,
    this.playersMin,
    this.playersMax,
    this.situations = const [],
    this.skills = const [],
    this.requirements = const [],
    this.cover,
    this.pdf = const [],
    this.script,
    this.minEngineVersion = 1,
    this.timingSensitive = false,
    this.storeProductId,
    this.preview,
    this.releasedOn,
  });

  factory ContentItem.fromJson(JsonReader r) {
    final kind = r.enumValue('kind', ContentKind.values);
    final script = r.optObject('script');
    if (kind == ContentKind.interactiveGame && script == null) {
      throw FormatError('${r.path}.script', 'interactive games need a script');
    }
    return ContentItem(
      id: r.string('id'),
      kind: kind,
      packId: r.optString('pack_id'),
      title: r.string('title'),
      subtitle: r.optString('subtitle'),
      parentDescription: r.string('parent_description'),
      ageMin: r.integer('age_min', min: 0, max: 18),
      ageMax: r.optInteger('age_max', min: 0, max: 18),
      durationSec: r.integer('duration_sec', min: 1),
      playersMin: r.optInteger('players_min', min: 1),
      playersMax: r.optInteger('players_max', min: 1),
      situations: [
        for (final s in r.strings('situations')) _parseEnum(s, Situation.values, '${r.path}.situations'),
      ],
      skills: r.strings('skills'),
      requirements: [
        for (final s in r.strings('requirements'))
          _parseEnum(s, Requirement.values, '${r.path}.requirements'),
      ],
      access: r.enumValue('access', ContentAccess.values),
      cover: r.optObject('cover') == null ? null : AssetRef.fromJson(r.object('cover')),
      audio: [
        for (final (i, a) in r.list('audio').indexed)
          AssetRef.fromJson(JsonReader.of(a, '${r.path}.audio[$i]')),
      ],
      pdf: [
        for (final (i, a) in r.list('pdf').indexed) AssetRef.fromJson(JsonReader.of(a, '${r.path}.pdf[$i]')),
      ],
      script: script == null ? null : GameScript.fromJson(script),
      minEngineVersion: r.optInteger('min_engine_version', min: 1) ?? 1,
      timingSensitive: r.boolean('timing_sensitive'),
      storeProductId: r.optString('store_product_id'),
      preview: r.optObject('preview') == null ? null : AssetRef.fromJson(r.object('preview')),
      releasedOn: r.optDate('released'),
    );
  }

  final String id;
  final ContentKind kind;
  final String? packId;
  final String title;
  final String? subtitle;

  /// What the activity is and what it practises, written for the parent.
  final String parentDescription;
  final int ageMin;
  final int? ageMax;
  final int durationSec;

  /// Only set when the number of players is actually defined for the activity.
  final int? playersMin;
  final int? playersMax;
  final List<Situation> situations;
  final List<String> skills;
  final List<Requirement> requirements;
  final ContentAccess access;
  final AssetRef? cover;

  /// Plain audio: one file. Interactive games keep their segments in [script].
  final List<AssetRef> audio;
  final List<AssetRef> pdf;
  final GameScript? script;
  final int minEngineVersion;

  /// Playback speed changes are disabled for timing-sensitive content.
  final bool timingSensitive;
  final String? storeProductId;

  bool get isFree => access == ContentAccess.free;

  /// A short free excerpt of a paid recording, so a parent can hear it before buying.
  final AssetRef? preview;

  /// When the item was published; "Nowe" for a while after (see [isNewAt]).
  final DateTime? releasedOn;

  /// Total bytes to download for offline use.
  int get downloadBytes => [...audio, ...pdf, ...?script?.assets.values].fold(0, (sum, a) => sum + a.bytes);
}

T _parseEnum<T extends Enum>(String raw, List<T> values, String path) {
  for (final v in values) {
    if (wireName(v) == raw) return v;
  }
  throw FormatError(path, 'unknown value "$raw"');
}

/// How long something counts as new after its release.
const newForDays = 30;

/// Whether content released on [releasedOn] is still "new" at [now].
bool isNewAt(DateTime? releasedOn, DateTime now) =>
    releasedOn != null && !releasedOn.isAfter(now) && now.difference(releasedOn).inDays < newForDays;
