import 'package:audiokiddo_studio/crm/task_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the agent\'s prompt and tool win; hand-written tasks get a guess and a prompt of their own', () {
    final fromAgent = {
      'title': 'Opisy do sklepu',
      'data': {'prompt': 'Napisz opisy…', 'ai': 'chatgpt', 'ai_why': 'grafiki'},
    };
    expect(aiFor(fromAgent).name, 'ChatGPT');
    expect(promptFor(fromAgent), 'Napisz opisy…');
    expect(aiWhy(fromAgent), 'grafiki');

    expect(aiFor({'title': 'Założyć konto Google Play Console'}).name, 'Gemini');
    expect(aiFor({'title': 'Przygotować grafiki do sklepu'}).name, 'ChatGPT');
    final mine = {'title': 'Napisać scenariusz', 'body': 'O smoku', 'due': '2026-10-20'};
    expect(aiFor(mine).name, 'Claude');
    expect(
      promptFor(mine),
      allOf(
        contains('AudioKiddo'),
        contains('Zadanie: Napisać scenariusz'),
        contains('O smoku'),
        contains('2026-10-20'),
      ),
    );
  });
}
