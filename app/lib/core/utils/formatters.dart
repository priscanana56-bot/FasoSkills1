import 'package:intl/intl.dart';

/// Display helpers shared by every screen, so amounts, dates and statuses read the same everywhere.
class Fmt {
  Fmt._();

  static final _money = NumberFormat.decimalPattern('fr_FR');

  static String fcfa(num amount) => '${_money.format(amount.round())} FCFA';

  static String initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  /// "14:25" today, "Hier", weekday this week, otherwise "12 nov.".
  static String chatTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return DateFormat.Hm().format(date);
    if (diff == 1) return 'Hier';
    if (diff < 7) return _weekday(date.weekday);
    return '${date.day} ${_month(date.month)}';
  }

  /// "il y a 5 min", "il y a 2 h", "il y a 3 j", otherwise a date.
  static String relative(DateTime? date) {
    if (date == null) return '';
    final d = DateTime.now().difference(date);
    if (d.inMinutes < 1) return "à l'instant";
    if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
    if (d.inHours < 24) return 'il y a ${d.inHours} h';
    if (d.inDays < 7) return 'il y a ${d.inDays} j';
    return '${date.day} ${_month(date.month)} ${date.year}';
  }

  static String _weekday(int w) =>
      const ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'][w - 1];

  static String _month(int m) => const [
        'janv.',
        'févr.',
        'mars',
        'avr.',
        'mai',
        'juin',
        'juil.',
        'août',
        'sept.',
        'oct.',
        'nov.',
        'déc.'
      ][m - 1];

  static String requestStatus(String status) => switch (status) {
        'pending' => 'En attente de devis',
        'accepted' || 'in_progress' => 'En cours',
        'completed' => 'Terminée',
        'cancelled' => 'Annulée',
        _ => status,
      };

  static String quoteStatus(String status) => switch (status) {
        'pending' => 'En attente',
        'accepted' => 'Accepté',
        'rejected' => 'Non retenu',
        _ => status,
      };
}
