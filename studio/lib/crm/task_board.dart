import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'crm_widgets.dart';

/// One column of the board: its status, title and colours.
typedef BoardColumn = ({String status, String label, Color deep, Color soft});

/// Whether a task belongs to the next [days] days: overdue, due by then, or without a date.
/// The launch plan puts tasks on the board until mid-2027; these keep the board to what is near.
bool dueSoon(Map<String, dynamic> task, DateTime today, {int days = 14}) {
  final due = DateTime.tryParse('${task['due'] ?? ''}');
  if (due == null) return true;
  final day = DateTime(today.year, today.month, today.day);
  return !due.isAfter(day.add(Duration(days: days)));
}

/// Board order: the more urgent priority first, then the nearer date (undated last).
int byUrgency(Map<String, dynamic> a, Map<String, dynamic> b) {
  final p = ((a['priority'] as int?) ?? 2).compareTo((b['priority'] as int?) ?? 2);
  if (p != 0) return p;
  final da = '${a['due'] ?? ''}', db = '${b['due'] ?? ''}';
  if (da.isEmpty || db.isEmpty) return da.isEmpty == db.isEmpty ? 0 : (da.isEmpty ? 1 : -1);
  return da.compareTo(db);
}

/// The task board: columns that each scroll down on their own and share the screen.
/// "Szerokość zadań" sets how wide one task is: narrower tasks sit several in a row, so more
/// fit on the screen; wider ones read more easily. "Skala" shrinks or enlarges everything
/// (a phone shows more tasks at once). Both are remembered in this browser.
class TaskBoard extends StatefulWidget {
  const TaskBoard({
    super.key,
    required this.columns,
    required this.tasks,
    required this.cardFor,
    required this.onMove,
    this.header,
  });

  final List<BoardColumn> columns;
  final List<Map<String, dynamic>> tasks;

  /// The card of one task (with its actions).
  final Widget Function(Map<String, dynamic> task) cardFor;
  final void Function(Map<String, dynamic> task, String status) onMove;

  /// Filters above the sliders.
  final Widget? header;

  @override
  State<TaskBoard> createState() => _TaskBoardState();
}

class _TaskBoardState extends State<TaskBoard> {
  static const _widthKey = 'tasks_card_width';
  static const _scaleKey = 'tasks_scale';
  static const minWidth = 170.0;
  static const maxWidth = 640.0;
  static const defaultWidth = 300.0;

  /// Wanted width of one task (before the scale); null: [defaultWidth].
  double? _width;
  double _scale = 1;

  /// null: shown on a big screen, hidden on a phone (the button beside the filter toggles).
  bool? _showControls;
  bool _phone = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        final w = p.getDouble(_widthKey);
        _width = w == null || w <= 0 ? null : w.clamp(minWidth, maxWidth);
        _scale = (p.getDouble(_scaleKey) ?? 1).clamp(.5, 1.3);
      });
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_widthKey, _width ?? 0);
    await p.setDouble(_scaleKey, _scale);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, box) {
        final phone = box.maxWidth < 700;
        _phone = phone;
        final shown = _showControls ?? !phone;
        final controls = Wrap(
          spacing: 20,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _SliderField(
              icon: Icons.view_column_rounded,
              label: 'Szerokość zadań: ${(_width ?? defaultWidth).round()}',
              value: (_width ?? defaultWidth).clamp(minWidth, maxWidth).toDouble(),
              min: minWidth,
              max: maxWidth,
              onChanged: (v) => setState(() => _width = v),
              onChangeEnd: (_) => _save(),
            ),
            _SliderField(
              icon: Icons.zoom_out_map_rounded,
              label: 'Skala: ${(_scale * 100).round()}%',
              value: _scale,
              min: .5,
              max: 1.3,
              divisions: 16,
              onChanged: (v) => setState(() => _scale = v),
              onChangeEnd: (_) => _save(),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _width = null;
                  _scale = 1;
                });
                _save();
              },
              icon: const Icon(Icons.fit_screen_rounded),
              label: const Text('Dopasuj do ekranu'),
            ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(phone ? 8 : 16, 8, phone ? 8 : 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.header != null) Expanded(child: widget.header!) else const Spacer(),
                      IconButton(
                        tooltip: shown ? 'Ukryj suwaki' : 'Pokaż suwaki szerokości i skali',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _showControls = !shown),
                        icon: Icon(shown ? Icons.tune_rounded : Icons.tune_outlined),
                      ),
                    ],
                  ),
                  if (shown) controls,
                ],
              ),
            ),
            Expanded(
              child: _Zoom(
                scale: _scale,
                child: LayoutBuilder(builder: (context, area) => _board(context, area, phone, text)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _board(BuildContext context, BoxConstraints area, bool phone, TextTheme text) {
    const gap = 12.0;
    final pad = phone ? 8.0 : 16.0;
    final n = widget.columns.length;
    final room = area.maxWidth - 2 * pad - gap * (n - 1);
    // Columns share the screen; when that leaves them too narrow to read (a phone) each is
    // nearly as wide as the screen and the board scrolls sideways.
    const minColumn = 300.0;
    final fits = room / n >= minColumn;
    final width = fits ? room / n : (phone ? area.maxWidth * .9 : minColumn);
    final columns = [
      for (final (i, c) in widget.columns.indexed)
        Padding(
          padding: EdgeInsets.only(right: i == n - 1 ? 0 : gap),
          child: SizedBox(width: width, child: _column(context, c, width, text)),
        ),
    ];
    final row = Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: columns);
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 4, fits ? pad : 0, 0),
      child: fits
          ? row
          : Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(right: pad),
                child: SizedBox(height: area.maxHeight - 4, child: row),
              ),
            ),
    );
  }

  Widget _feedback(Map<String, dynamic> t, double cardW) => Material(
    color: Colors.transparent,
    child: SizedBox(
      width: cardW.clamp(200, 340),
      child: Transform.rotate(angle: -.03, child: CrmCard(item: t, dense: true)),
    ),
  );

  Widget _column(BuildContext context, BoardColumn c, double width, TextTheme text) {
    final platform = Theme.of(context).platform;
    final touch = platform == TargetPlatform.iOS || platform == TargetPlatform.android || _phone;
    final tasks = [
      for (final t in widget.tasks)
        if (t['status'] == c.status) t,
    ];
    // Narrow tasks sit side by side: as many as fit in the column, stretched to fill the row.
    final target = _width ?? defaultWidth;
    final perRow = ((width - 20 + 10) / (target + 10)).floor().clamp(1, 12);
    final cardW = (width - 20 - 10 * (perRow - 1)) / perRow;
    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (d) => d.data['status'] != c.status,
      onAcceptWithDetails: (d) => widget.onMove(d.data, c.status),
      builder: (context, hovering, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: c.soft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: hovering.isNotEmpty ? c.deep : Colors.transparent, width: 2.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: c.deep),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c.label,
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: c.deep),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                    decoration: BoxDecoration(color: c.deep, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${tasks.length}',
                      style: text.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tasks.isEmpty
                  ? Center(child: Text(hovering.isNotEmpty ? 'Upuść tutaj' : 'Pusto', style: text.bodyMedium))
                  : Scrollbar(
                      child: SingleChildScrollView(
                        // Room at the bottom for the "Dodaj zadanie" button.
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 90),
                        child: Wrap(
                          spacing: 10,
                          children: [
                            for (final t in tasks)
                              SizedBox(
                                width: cardW,
                                // Touch screens: hold to drag, so a swipe still scrolls the column.
                                child: touch
                                    ? LongPressDraggable<Map<String, dynamic>>(
                                        data: t,
                                        feedback: _feedback(t, cardW),
                                        childWhenDragging: Opacity(
                                          opacity: .35,
                                          child: CrmCard(item: t, dense: true),
                                        ),
                                        child: widget.cardFor(t),
                                      )
                                    : Draggable<Map<String, dynamic>>(
                                        data: t,
                                        feedback: _feedback(t, cardW),
                                        childWhenDragging: Opacity(
                                          opacity: .35,
                                          child: CrmCard(item: t, dense: true),
                                        ),
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.grab,
                                          child: widget.cardFor(t),
                                        ),
                                      ),
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lays [child] out as if the screen were 1/[scale] as big, then paints it [scale] times
/// smaller (or bigger): everything shrinks together, text, cards and gaps.
class _Zoom extends StatelessWidget {
  const _Zoom({required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if ((scale - 1).abs() < .001) return child;
    return LayoutBuilder(
      builder: (context, box) => ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: box.maxWidth / scale,
          maxWidth: box.maxWidth / scale,
          minHeight: box.maxHeight / scale,
          maxHeight: box.maxHeight / scale,
          child: Transform.scale(scale: scale, alignment: Alignment.topLeft, child: child),
        ),
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
    this.divisions,
  });

  final IconData icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 340),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 6),
        SizedBox(width: 130, child: Text(label, style: Theme.of(context).textTheme.labelMedium)),
        Flexible(
          child: SizedBox(
            width: 150,
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ),
      ],
    ),
  );
}
