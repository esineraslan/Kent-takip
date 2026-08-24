import 'package:flutter/widgets.dart';

final class LocaleFormatter {
  const LocaleFormatter(this.locale);
  final Locale locale;

  bool get _tr => locale.languageCode == 'tr';

  String dateTime(DateTime value) {
    final local = value.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    if (_tr) {
      return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
    }
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final suffix = local.hour < 12 ? 'AM' : 'PM';
    return '${two(local.month)}/${two(local.day)}/${local.year} $hour12:${two(local.minute)} $suffix';
  }

  String number(num value, {int fractionDigits = 0}) {
    final fixed = value.toStringAsFixed(fractionDigits);
    return _tr ? fixed.replaceAll('.', ',') : fixed;
  }

  String phone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return raw;
    final local = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    return _tr
        ? '+90 ${local.substring(0, 3)} ${local.substring(3, 6)} ${local.substring(6, 8)} ${local.substring(8)}'
        : '+90 (${local.substring(0, 3)}) ${local.substring(3, 6)}-${local.substring(6)}';
  }

  String maskedPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return raw;
    final tail = digits.substring(digits.length - 4);
    return '+90 ••• ••• $tail';
  }

  String count(int value, {required String singularTr, required String pluralTr, required String singularEn, required String pluralEn}) {
    final label = locale.languageCode == 'tr'
        ? (value == 1 ? singularTr : pluralTr)
        : (value == 1 ? singularEn : pluralEn);
    return '$value $label';
  }
}

extension LocaleFormatterContext on BuildContext {
  LocaleFormatter get localeFormat => LocaleFormatter(Localizations.localeOf(this));
}
