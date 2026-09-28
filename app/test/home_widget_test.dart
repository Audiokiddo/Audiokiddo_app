import 'package:audiokiddo/features/home/home_widget_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('week notes follow the melody staff of the current week', () {
    expect(weekNotes(currentDay: 1, completedDays: 0), 0);
    expect(weekNotes(currentDay: 3, completedDays: 2), 2);
    expect(weekNotes(currentDay: 7, completedDays: 7), 7, reason: 'last day of the week done');
    expect(weekNotes(currentDay: 8, completedDays: 7), 0, reason: 'a new week starts empty');
    expect(weekNotes(currentDay: 10, completedDays: 9), 2);
  });

  test('widget data compares by value, so unchanged weeks are not pushed again', () {
    const a = HomeWidgetData(line: 'Zosia · dzień 3 · 2 z 7 nut', notes: 2, todayDone: false);
    const b = HomeWidgetData(line: 'Zosia · dzień 3 · 2 z 7 nut', notes: 2, todayDone: false);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
