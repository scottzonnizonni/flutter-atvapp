import 'package:intl/intl.dart';

class AppDateUtils {
  /// Converte uma data em tempo relativo (ex: "há 2 horas", "Ontem")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Agora mesmo';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'Há $minutes min';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Há ${hours}h';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'Há $days dias';
    } else {
      return DateFormat('dd/MM/yyyy').format(dateTime);
    }
  }

  /// Agrupa datas em categorias (Hoje, Ontem, Esta semana, etc.)
  static String getDateGroup(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'HOJE';
    } else if (difference.inDays == 1) {
      return 'ONTEM';
    } else if (difference.inDays < 7) {
      return 'ESTA SEMANA';
    } else if (difference.inDays < 30) {
      return 'ESTE MÊS';
    } else {
      return DateFormat('MMMM yyyy').format(dateTime).toUpperCase();
    }
  }
}
