import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../io/studio_io.dart';
import '../theme.dart';

/// The AI chats Dawid has, with where to open them.
class AiTool {
  const AiTool(this.id, this.name, this.url, this.color);
  final String id;
  final String name;
  final String url;
  final Color color;

  static const claude = AiTool('claude', 'Claude', 'https://claude.ai/new', Color(0xFFC15F3C));
  static const chatgpt = AiTool('chatgpt', 'ChatGPT', 'https://chatgpt.com/', Color(0xFF10A37F));
  static const gemini = AiTool('gemini', 'Gemini', 'https://gemini.google.com/app', Color(0xFF4285F4));
  static const all = [claude, chatgpt, gemini];

  static AiTool of(String? id) => all.firstWhere((t) => t.id == id, orElse: () => claude);
}

Map<String, dynamic> _data(Map<String, dynamic> item) =>
    item['data'] is Map ? Map<String, dynamic>.from(item['data'] as Map) : const {};

/// The tool for a task: the agent's choice, or a guess from its words for tasks written by hand.
AiTool aiFor(Map<String, dynamic> item) {
  final chosen = _data(item)['ai'];
  if (chosen is String && AiTool.all.any((t) => t.id == chosen)) return AiTool.of(chosen);
  final text = '${item['title']} ${item['body'] ?? ''}'.toLowerCase();
  bool any(List<String> words) => words.any(text.contains);
  if (any([
    'google',
    'play console',
    'youtube',
    'arkusz',
    'sheets',
    'search console',
    'analytics',
    'gmail',
  ])) {
    return AiTool.gemini;
  }
  if (any([
    'grafik',
    'obraz',
    'zdjęci',
    'ikon',
    'screenshot',
    'zrzut',
    'baner',
    'logo',
    'wizual',
    'tabel',
    'konkurenc',
  ])) {
    return AiTool.chatgpt;
  }
  return AiTool.claude;
}

/// Why that tool, when the agent said so.
String? aiWhy(Map<String, dynamic> item) {
  final why = _data(item)['ai_why'];
  return why is String && why.isNotEmpty ? why : null;
}

/// A prompt that works on its own in any chat: the agent's, or one built from the task.
String promptFor(Map<String, dynamic> item) {
  final ready = _data(item)['prompt'];
  if (ready is String && ready.trim().isNotEmpty) return ready.trim();
  final body = '${item['body'] ?? ''}'.trim();
  final due = item['due'] == null ? '' : '\nTermin: ${item['due']}.';
  return 'Pomagasz firmie AudioKiddo: polskie interaktywne audiozabawy dla dzieci w wieku przedszkolnym '
      'i wczesnoszkolnym (aplikacja iOS i Android, sklep audiokiddo.pl). Tworzą ją Nela (treści, nagrania) '
      'i Dawid (technika, sprzedaż, marketing). Maskotka: szop Szop’en. Zasady: aplikacja w kategorii Kids, '
      'bez reklam, RODO, żadnych danych dziecka.\n\n'
      'Zadanie: ${item['title']}${body.isEmpty ? '' : '\n$body'}$due\n\n'
      'Zrób to krok po kroku. Jeśli czegoś nie wiesz, najpierw zadaj mi najwyżej 3 pytania. '
      'Na końcu podaj gotowy wynik do użycia (tekst, lista albo tabela) i krótką listę „co teraz zrobić”. '
      'Pisz po polsku.';
}

/// On a task card: which AI to use, "Kopiuj prompt" and a button that opens that chat.
class TaskAiActions extends StatelessWidget {
  const TaskAiActions(this.item, {super.key});

  final Map<String, dynamic> item;

  Future<void> _copy(BuildContext context, AiTool tool) async {
    await Clipboard.setData(ClipboardData(text: promptFor(item)));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Prompt skopiowany. Otwórz ${tool.name} i wklej (Cmd + V).'),
        action: SnackBarAction(label: 'Otwórz ${tool.name}', onPressed: () => openInBrowser(tool.url)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tool = aiFor(item);
    final why = aiWhy(item);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Tooltip(
          message: why ?? 'Podpowiedź na podstawie treści zadania',
          child: Chip(
            visualDensity: VisualDensity.compact,
            avatar: Icon(Icons.auto_awesome_rounded, size: 16, color: tool.color),
            label: Text('Najlepiej: ${tool.name}', style: const TextStyle(fontSize: 12)),
            backgroundColor: tool.color.withValues(alpha: .10),
            side: BorderSide(color: tool.color.withValues(alpha: .35)),
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Brand.ink,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          onPressed: () => _copy(context, tool),
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Kopiuj prompt'),
        ),
        IconButton(
          tooltip: 'Otwórz ${tool.name}',
          visualDensity: VisualDensity.compact,
          onPressed: () => openInBrowser(tool.url),
          icon: Icon(Icons.open_in_new_rounded, size: 18, color: tool.color),
        ),
      ],
    );
  }
}
