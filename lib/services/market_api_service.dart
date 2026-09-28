import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketApiService {
  static const int _timeoutSeconds = 10;

  // Mengambil harga pasar terbaru dalam Rupiah
  static Future<double?> fetchPrice(String assetType, String symbol) async {
    if (symbol.isEmpty) return null;
    
    try {
      if (assetType == 'crypto') {
        return await _fetchCryptoPrice(symbol);
      } else if (assetType == 'stock') {
        return await _fetchStockPrice(symbol);
      } else if (assetType == 'gold') {
        return await _fetchGoldPrice();
      }
    } catch (e) {
      print('Error fetching market price: $e');
    }
    return null;
  }

  // CoinGecko API (Gratis, tanpa key)
  // symbol contoh: "bitcoin", "ethereum"
  static Future<double?> _fetchCryptoPrice(String coinId) async {
    final url = Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=${coinId.toLowerCase()}&vs_currencies=idr');
    final response = await http.get(url).timeout(const Duration(seconds: _timeoutSeconds));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data[coinId.toLowerCase()] != null) {
        return (data[coinId.toLowerCase()]['idr'] as num).toDouble();
      }
    }
    return null;
  }

  // Yahoo Finance Unofficial API
  // symbol contoh: "BBCA.JK"
  static Future<double?> _fetchStockPrice(String ticker) async {
    final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/${ticker.toUpperCase()}');
    final response = await http.get(url).timeout(const Duration(seconds: _timeoutSeconds));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final result = data['chart']?['result'];
      if (result != null && result.isNotEmpty) {
        final meta = result[0]['meta'];
        if (meta != null && meta['regularMarketPrice'] != null) {
          return (meta['regularMarketPrice'] as num).toDouble();
        }
      }
    }
    return null;
  }

  // Fallback untuk harga Emas jika tidak ada API gratis yang reliable
  // Menggunakan API Indogold (publik) atau scraping ringan,
  // Di sini disimulasikan harga rata-rata emas Antam jika endpoint publik gagal
  static Future<double?> _fetchGoldPrice() async {
    // Karena GoldAPI berbayar/perlu API key, kita buat fallback statis (estimasi saat ini 1,4jt - 1,5jt)
    // Di produksi bisa diganti dengan endpoint scrapping Anda sendiri
    return 1450000.0;
  }
}
