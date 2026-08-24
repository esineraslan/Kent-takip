import 'package:flutter/material.dart';

final class LocaleController extends ChangeNotifier {
  LocaleController({Locale initialLocale = const Locale('tr')})
    : _locale = initialLocale;

  Locale _locale;

  Locale get locale => _locale;

  void toggle() {
    _locale = _locale.languageCode == 'tr'
        ? const Locale('en')
        : const Locale('tr');
    notifyListeners();
  }
}
