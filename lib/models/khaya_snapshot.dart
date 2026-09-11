  class KhayaSnapshot {
  final bool connected;
  final String? account;
  final double? balance;
  final double? equity;
  final double? freeMargin;
  final int? openPositions;
  final String? symbol;
  final double? bid;
  final double? ask;
  final DateTime? serverTime;

  const KhayaSnapshot({
    required this.connected,
    this.account,
    this.balance,
    this.equity,
    this.freeMargin,
    this.openPositions,
    this.symbol,
    this.bid,
    this.ask,
    this.serverTime,
  });

  factory KhayaSnapshot.disconnected() {
    return const KhayaSnapshot(
      connected: false,
    );
  }

  factory KhayaSnapshot.fromJson(Map<String, dynamic> json) {
    return KhayaSnapshot(
      connected: json['connected'] == true,
      account: json['account']?.toString(),
      balance: _toDouble(json['balance']),
      equity: _toDouble(json['equity']),
      freeMargin: _toDouble(json['freeMargin']),
      openPositions: _toInt(json['openPositions']),
      symbol: json['symbol']?.toString(),
      bid: _toDouble(json['bid']),
      ask: _toDouble(json['ask']),
      serverTime: _toDateTime(json['serverTime']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connected': connected,
      'account': account,
      'balance': balance,
      'equity': equity,
      'freeMargin': freeMargin,
      'openPositions': openPositions,
      'symbol': symbol,
      'bid': bid,
      'ask': ask,
      'serverTime': serverTime?.toIso8601String(),
    };
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}