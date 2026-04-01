/// Chave estável do dia civil local `yyyy-MM-dd` (para conclusões por ocorrência).
String localCalendarDayKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

bool isValidCalendarDayKey(String s) {
  if (s.length != 10 || s[4] != '-' || s[7] != '-') return false;
  final y = int.tryParse(s.substring(0, 4));
  final m = int.tryParse(s.substring(5, 7));
  final d = int.tryParse(s.substring(8, 10));
  if (y == null || m == null || d == null) return false;
  if (m < 1 || m > 12 || d < 1 || d > 31) return false;
  return true;
}
