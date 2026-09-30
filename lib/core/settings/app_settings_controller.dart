import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exchange_rate_service.dart';

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
  static const _updatedAtKey = 'rates_updated_at';
  static const _usdRateKey = 'rate_usd';
  static const _eurRateKey = 'rate_eur';

  AppCurrency _currency = AppCurrency.lkr;
  AppLanguage _language = AppLanguage.system;
  Map<String, double> _rates = const {'lkr': 1, 'usd': 0.0031, 'eur': 0.0028};
  DateTime? _ratesUpdatedAt;

  AppCurrency get currency => _currency;
  AppLanguage get language => _language;
  DateTime? get ratesUpdatedAt => _ratesUpdatedAt;
  Locale? get locale =>
      _language.languageCode == null ? null : Locale(_language.languageCode!);

  double convertFromLkr(double amount) =>
      amount * (_rates[_currency.name] ?? 1);

  double convertToLkr(double amount) => amount / (_rates[_currency.name] ?? 1);

  String formatAmount(double amount) =>
      '${_currency.label} ${convertFromLkr(amount).toStringAsFixed(2)}';

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedCurrency = preferences.getString(_currencyKey);
    final savedLanguage = preferences.getString(_languageKey);
    final savedUpdatedAt = preferences.getString(_updatedAtKey);
    final savedUsdRate = preferences.getDouble(_usdRateKey);
    final savedEurRate = preferences.getDouble(_eurRateKey);

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
    if (savedUpdatedAt != null) {
      _ratesUpdatedAt = DateTime.tryParse(savedUpdatedAt);
    }
    if (savedUsdRate != null && savedEurRate != null) {
      _rates = {'lkr': 1, 'usd': savedUsdRate, 'eur': savedEurRate};
    }
  }

  Future<void> refreshRates({ExchangeRateService? service}) async {
    try {
      _rates = await (service ?? const ExchangeRateService()).fetchRates();
      _ratesUpdatedAt = DateTime.now();
      notifyListeners();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _updatedAtKey,
        _ratesUpdatedAt!.toIso8601String(),
      );
      await preferences.setDouble(_usdRateKey, _rates['usd']!);
      await preferences.setDouble(_eurRateKey, _rates['eur']!);
    } catch (_) {
      // Keep the bundled fallback rates when the network is unavailable.
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
