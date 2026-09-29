import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppCurrency {
  lkr('LKR'),
  usd('USD'),
  eur('EUR');

  const AppCurrency(this.label);

  final String label;
}

enum AppLanguage {
  system('System', null),
  english('English', 'en'),
  sinhala('Sinhala', 'si'),
  tamil('Tamil', 'ta');

  const AppLanguage(this.label, this.languageCode);

  final String label;
  final String? languageCode;
}

class AppSettingsController extends ChangeNotifier {
  static const _currencyKey = 'currency';
  static const _languageKey = 'language';

  AppCurrency _currency = AppCurrency.lkr;
  AppLanguage _language = AppLanguage.system;

  AppCurrency get currency => _currency;
  AppLanguage get language => _language;
  Locale? get locale => _language.languageCode == null
      ? null
      : Locale(_language.languageCode!);

  String formatAmount(double amount) =>
      '${_currency.label} ${amount.toStringAsFixed(2)}';

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedCurrency = preferences.getString(_currencyKey);
    final savedLanguage = preferences.getString(_languageKey);

    if (savedCurrency != null) {
      _currency = AppCurrency.values.firstWhere(
        (value) => value.name == savedCurrency,
        orElse: () => AppCurrency.lkr,
      );
    }
    if (savedLanguage != null) {
      _language = AppLanguage.values.firstWhere(
        (value) => value.name == savedLanguage,
        orElse: () => AppLanguage.system,
      );
    }
  }

  Future<void> setCurrency(AppCurrency currency) async {
    if (_currency == currency) return;
    _currency = currency;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_currencyKey, currency.name);
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, language.name);
  }
}
