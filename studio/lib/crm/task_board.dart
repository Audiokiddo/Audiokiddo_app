import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'crm_widgets.dart';

/// One column of the board: its status, title and colours.
typedef BoardColumn = ({String status, String label, Color deep, Color soft});

/// The task board: columns that each scroll down on their own, as wide as the screen allows.
/// "Szerokość kolumn" makes columns wider (cards then sit several in a row) or narrower (the
/// board scrolls sideways); "Skala" shrinks everything so more tasks fit, also on a phone.
/// Both are remembered in this browser.
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
  static const _widthKey = 'tasks_column_width';
  static const _scaleKey = 'tasks_scale';
  static const minWidth = 240.0;
  static const maxWidth = 900.0;

  /// Wanted column width (before the scale); null: fit the screen.
  double? _width;
  double _scale = 1;
  bool _showControls = true;
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
        final controls = Wrap(
          spacing: 20,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _SliderField(
              icon: Icons.view_column_rounded,
              label: _width == null ? 'Szerokość: dopasowana' : 'Szerokość kolumn: ${_width!.round()}',
              value: (_width ?? (phone ? box.maxWidth * .85 : 360.0)).clamp(minWidth, maxWidth).toDouble(),
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
                        tooltip: _showControls ? 'Ukryj suwaki' : 'Pokaż suwaki',
                        onPressed: () => setState(() => _showControls = !_showControls),
                        icon: Icon(_showControls ? Icons.tune_rounded : Icons.tune_outlined),
                      ),
                    ],
                  ),
                  if (_showControls) controls,
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
    final wanted = _width ?? (phone ? area.maxWidth * .85 : 0);
    // Columns fill the screen when they fit; otherwise they keep their width and the board
    // scrolls sideways.
    final fits = wanted * n <= room;
    final width = fits ? room / n : wanted;
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
    // Wide columns show cards side by side.
    const cardWidth = 300.0;
    final perRow = ((width - 20) / cardWidth).floor().clamp(1, 4);
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
        SizedBox(width: 150, child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
        Flexible(
          child: SizedBox(
            width: 170,
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
