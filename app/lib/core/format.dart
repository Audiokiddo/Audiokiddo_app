/// "3,1 MB" with a Polish decimal comma.
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }
  final text = unit == 0 || value >= 100 ? value.round().toString() : value.toStringAsFixed(1);
  return '${text.replaceAll('.', ',')} ${units[unit]}';
}

/// "2:05", or "1:02:05" for an hour and more.
String formatClock(Duration d) {
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  if (d.inHours > 0) return '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:$seconds';
  return '${d.inMinutes}:$seconds';
}
