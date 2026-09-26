/// Shared AudioKiddo domain logic: catalog, access rules, offline lease, game scripts.
library;

export 'src/access.dart';
export 'src/audio/detectors.dart';
export 'src/catalog.dart';
export 'src/content.dart';
export 'src/json.dart' show FormatError, wireName;
export 'src/lease.dart';
export 'src/script/model.dart';
export 'src/script/runner.dart';
export 'src/script/validator.dart';
