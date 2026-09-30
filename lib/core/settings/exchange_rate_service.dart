import 'dart:convert';

import 'package:http/http.dart' as http;

class ExchangeRateService {
  const ExchangeRateService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<Map<String, double>> fetchRates() async {
    final response = await (_client ?? http.Client())
        .get(Uri.parse('https://open.er-api.com/v6/latest/LKR'))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('Exchange rate request failed');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final rates = payload['rates'] as Map<String, dynamic>?;
    if (rates == null) throw Exception('Exchange rate response was incomplete');

    final usd = (rates['USD'] as num?)?.toDouble();
    final eur = (rates['EUR'] as num?)?.toDouble();
    if (usd == null || eur == null) {
      throw Exception('Exchange rate response was incomplete');
    }

    return {'lkr': 1, 'usd': usd, 'eur': eur};
  }
}
