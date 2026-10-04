import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How a task of the case file is answered on the phone.
enum CaseTaskKind {
  /// One of [CaseTask.options]; graded.
  choice,

  /// Typed text or digits; graded against [CaseTask.accepted].
  code,

  /// Drawn, heard or invented: the child checks it with Max and Mila, nothing is graded.
  open,
}

/// One task printed on a page of a Detektyw case file.
class CaseTask {
  const CaseTask({
    required this.page,
    required this.prompt,
    required this.kind,
    this.options = const [],
    this.answerIndex,
    this.accepted = const [],
  });

  factory CaseTask.fromJson(Map<String, Object?> json) {
    final kind = CaseTaskKind.values.byName(json['kind']! as String);
    final answer = json['answer'];
    return CaseTask(
      page: json['page']! as int,
      prompt: json['prompt']! as String,
      kind: kind,
      options: [...?(json['options'] as List?)?.cast<String>()],
      answerIndex: kind == CaseTaskKind.choice ? answer! as int : null,
      accepted: kind == CaseTaskKind.code ? [...(answer! as List).cast<String>()] : const [],
    );
  }

  /// 1-based page of the item's PDF the task is printed on.
  final int page;
  final String prompt;
  final CaseTaskKind kind;
  final List<String> options;
  final int? answerIndex;
  final List<String> accepted;

  /// The answer as shown after "Pokaż odpowiedź".
  String get solution => switch (kind) {
    CaseTaskKind.choice => options[answerIndex!],
    CaseTaskKind.code => accepted.first,
    CaseTaskKind.open => '',
  };

  bool isCorrectChoice(int index) => index == answerIndex;

  /// Typed answers count without case, spaces, punctuation or Polish diacritics,
  /// so "pod lampa jest klucz" opens the same lock as "POD LAMPĄ JEST KLUCZ".
  bool isCorrectCode(String typed) {
    final t = normalizeAnswer(typed);
    return t.isNotEmpty && accepted.any((a) => normalizeAnswer(a) == t);
  }
}

const _plain = {'Ą': 'A', 'Ć': 'C', 'Ę': 'E', 'Ł': 'L', 'Ń': 'N', 'Ó': 'O', 'Ś': 'S', 'Ź': 'Z', 'Ż': 'Z'};

String normalizeAnswer(String s) =>
    s.toUpperCase().split('').map((c) => _plain[c] ?? c).join().replaceAll(RegExp('[^A-Z0-9@]'), '');

/// Tasks per item id, from assets/case_files.json.
Map<String, List<CaseTask>> parseCaseFiles(Map<String, Object?> json) => {
  for (final e in json.entries)
    if (!e.key.startsWith('_'))
      e.key: [for (final t in e.value! as List) CaseTask.fromJson((t as Map).cast<String, Object?>())],
};

final caseFilesProvider = FutureProvider<Map<String, List<CaseTask>>>((ref) async {
  final bytes = await rootBundle.load('assets/case_files.json');
  return parseCaseFiles(
    jsonDecode(utf8.decode(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes)))
        as Map<String, Object?>,
  );
});

/// The interactive tasks of [itemId], or null when the item has none.
final caseTasksProvider = Provider.family<List<CaseTask>?, String>(
  (ref, itemId) => ref.watch(caseFilesProvider).value?[itemId],
);
