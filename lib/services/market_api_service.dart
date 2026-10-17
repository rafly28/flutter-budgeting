import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Satu snapshot harga pasar untuk satu aset.
///
/// [sell] adalah harga jual (= harga beli dari sisi pengguna), [buyback]
/// adalah harga yang dibayar toko saat pengguna menjual kembali. Untuk emas
/// keduanya berbeda (ada spread), sedangkan kripto/saham tidak punya
/// bid/ask jadi keduanya sama.
class MarketPrice {
  final double sell;
  final double buyback;

  const MarketPrice(this.sell, {double? buyback})
    : buyback = (buyback == null || buyback <= 0) ? sell : buyback;

  /// Harga beli unit. Gold/crypto/stock tidak punya spread selain emas, jadi
  /// harga jual = harga beli dari sisi pengguna.
  double get buyPrice => sell;

  @override
  String toString() => 'MarketPrice(sell: $sell, buyback: $buyback)';
}

class MarketApiService {
  static const int _timeoutSeconds = 10;

  // Endpoint publik gratis untuk harga logam mulia Indonesia (IDR/gram).
  // Mengambil harga Antam dan sumber lain, tanpa API key.
  static const String _logamMuliaEndpoint =
      'https://logam-mulia-api.iamutaki.workers.dev/api/prices/anekalogam';

  // Mengambil harga pasar terbaru dalam Rupiah, lengkap dengan harga jual dan
  // buyback.
  //
  // [symbol] hanya dibutuhkan crypto (coin id) dan saham (ticker). Emas
  // memakai harga Antam per gram sehingga simbol dikosongkan saja.
  // Mengembalikan null kalau tidak ada harga yang bisa dipercaya — pemanggil
  // harus mempertahankan harga terakhir yang tersimpan, bukan memakai angka
  // tebakan.
  static Future<MarketPrice?> fetchPrice(String assetType, String symbol) async {
    try {
      switch (assetType) {
        case 'crypto':
          if (symbol.trim().isEmpty) return null;
          return _fetchCryptoPrice(symbol.trim());
        case 'stock':
          if (symbol.trim().isEmpty) return null;
          return _fetchStockPrice(symbol.trim());
        case 'gold':
          return _fetchGoldPrice();
        default:
          return null;
      }
    } catch (e) {
      // Kegagalan jaringan tidak boleh merusak data: pemanggil akan memakai
      // harga tersimpan terakhir.
      return null;
    }
  }

  // CoinGecko API (Gratis, tanpa key)
  // symbol contoh: "bitcoin", "ethereum"
  static Future<MarketPrice?> _fetchCryptoPrice(String coinId) async {
    final id = coinId.toLowerCase();
    final url = Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price?ids=$id&vs_currencies=idr',
    );
    final response = await http
        .get(url)
        .timeout(const Duration(seconds: _timeoutSeconds));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    if (data is! Map) return null;
    final entry = data[id];
    if (entry is! Map) return null;
    final value = (entry['idr'] as num?)?.toDouble();
    // Kripto tidak punya bid/ask terpisah dari sumber ini, jadi buyback = sell.
    return (value != null && value > 0) ? MarketPrice(value) : null;
  }

  // Yahoo Finance Unofficial API
  // symbol contoh: "BBCA.JK"
  static Future<MarketPrice?> _fetchStockPrice(String ticker) async {
    final url = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/${ticker.toUpperCase()}',
    );
    final response = await http
        .get(url)
        .timeout(const Duration(seconds: _timeoutSeconds));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    if (data is! Map) return null;
    final result = data['chart']?['result'];
    if (result is! List || result.isEmpty) return null;
    final meta = result.first['meta'];
    if (meta is! Map) return null;
    final price = (meta['regularMarketPrice'] as num?)?.toDouble();
    // Saham tidak punya bid/ask terpisah dari sumber ini, jadi buyback = sell.
    return (price != null && price > 0) ? MarketPrice(price) : null;
  }

  // Harga jual + buyback emas Antam 1 gram dalam Rupiah, dari API publik.
  //
  // Pakai harga jual (bukan buyback) sebagai harga beli supaya sebanding
  // dengan avgBuyPrice yang dicatat pengguna sebagai modal beli; buyback
  // dipakai saat pengguna menjual kembali.
  //
  // API mengembalikan beberapa baris `weight: 1`, termasuk Certicard yang
  // gramasi sebenarnya berbeda. Baris Certicard diabaikan supaya harga yang
  // dipakai adalah Antam 1 gram standar. Kenaikan bug: picking baris pertama
  // bisa mengambil Certicard dan menghasilkan harga yang jauh meleset.
  static Future<MarketPrice?> _fetchGoldPrice() async {
    final response = await http
        .get(Uri.parse(_logamMuliaEndpoint))
        .timeout(const Duration(seconds: _timeoutSeconds));
    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body);
    if (body is! Map) return null;
    final rows = body['data'];
    if (rows is! List) return null;

    return parseGoldPrices(rows);
  }

  /// Memisahkan baris Antam 1 gram standar dari baris Certicard.
  ///
  /// Dipisah dari [_fetchGoldPrice] supaya bisa diuji tanpa jaringan.
  @visibleForTesting
  static MarketPrice? parseGoldPrices(List<dynamic> rows) {
    MarketPrice? fallback;
    for (final row in rows) {
      if (row is! Map) continue;
      if (row['weight'] != 1 || row['weightUnit'] != 'gr') continue;
      final sell = (row['sellPrice'] as num?)?.toDouble();
      if (sell == null || sell <= 0) continue;
      final buyback = (row['buybackPrice'] as num?)?.toDouble();
      final isCerticard =
          (row['materialType'] as String? ?? '').toLowerCase().contains(
            'certicard',
          );
      if (isCerticard) {
        fallback ??= MarketPrice(sell, buyback: buyback);
        continue;
      }
      return MarketPrice(sell, buyback: buyback);
    }
    // Semua baris 1 gram adalah Certicard — tetap pakai harga tersebut.
    return fallback;
  }
}