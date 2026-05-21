import 'package:intl/intl.dart';

final _money = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
final _date = DateFormat('MM-dd HH:mm');

String formatMoney(num? value) {
  if (value == null) return '面议';
  return _money.format(value);
}

String formatDate(DateTime? value) {
  if (value == null) return '';
  return _date.format(value.toLocal());
}
