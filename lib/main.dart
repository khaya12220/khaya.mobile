import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// KHAYA MOBILE â€” REAL DATA ONLY
// The app reads the live KHAYA API. It never invents balance, trades,
// prices, P/L, signals, or connection states.

const String defaultApiUrl = 'http://';
const Duration pollInterval = Duration(seconds: 3);

void main() {
  runApp(const KhayaApp());
}

class KhayaApp extends StatelessWidget {
  const KhayaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KHAYA Mobile',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF02090A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00FF88),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const KhayaHome(),
    );
  }
}

class KhayaHome extends StatefulWidget {
  const KhayaHome({super.key});

  @override
  State<KhayaHome> createState() => _KhayaHomeState();
}

class _KhayaHomeState extends State<KhayaHome> {
  final TextEditingController apiController =
      TextEditingController(text: defaultApiUrl);

  Timer? _timer;
  Map<String, dynamic>? _payload;
  String? _error;
  bool _loading = true;
  int _selectedIndex = 0;
  DateTime? _lastSuccessfulFetch;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(pollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    apiController.dispose();
    super.dispose();
  }

  String get _baseUrl {
    var value = apiController.text.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }

  Map<String, dynamic>? get _ea {
    final value = _payload?['ea'];
    return value is Map<String, dynamic> ? value : null;
  }

  bool get _apiConnected => _payload != null && _error == null;

  Future<void> _refresh() async {
    if (_baseUrl.isEmpty) return;

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/ea/status'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid KHAYA API response');
      }

      if (!mounted) return;
      setState(() {
        _payload = decoded;
        _error = null;
        _loading = false;
        _lastSuccessfulFetch = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Backend unreachable';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _dashboard(),
      _markets(),
      _trades(),
      _risk(),
      _settings(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedIndex]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF030B0C),
        indicatorColor: const Color(0x1F00FF88),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF00FF88)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart, color: Color(0xFF00FF88)),
            label: 'Markets',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_vert_outlined),
            selectedIcon: Icon(Icons.swap_vert, color: Color(0xFF00FF88)),
            label: 'Trades',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield, color: Color(0xFF00FF88)),
            label: 'Risk',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: Color(0xFF00FF88)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _dashboard() {
    final ea = _ea;
    final hasLiveEa = ea != null && ea['ea_running'] == true;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          _header(),
          const SizedBox(height: 22),
          _sectionTitle('KHAYA CONTROL CENTER'),
          const SizedBox(height: 10),
          _connectionCard(),
          const SizedBox(height: 12),
          _eaCard(ea),
          const SizedBox(height: 12),
          _marketCard(ea),
          const SizedBox(height: 12),
          _accountCard(ea),
          const SizedBox(height: 12),
          _infrastructureCard(ea),
          const SizedBox(height: 16),
          if (!hasLiveEa) _waitingCard(),
        ],
      ),
    );
  }

  Widget _header() {
    final connected = _apiConnected;
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFF00FF88), width: 1.5),
          ),
          child: const Center(
            child: Text(
              'K1',
              style: TextStyle(
                color: Color(0xFF00FF88),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KHAYA',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'MOBILE',
                style: TextStyle(
                  color: Color(0xFF00FF88),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ),
        _statusPill(connected ? 'CONNECTED' : 'OFFLINE', connected),
      ],
    );
  }

  Widget _connectionCard() {
    final connected = _apiConnected;
    return _card(
      icon: connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
      iconColor: connected ? const Color(0xFF00FF88) : const Color(0xFFFF3344),
      title: 'BACKEND CONNECTION',
      value: connected ? 'CONNECTED' : 'UNREACHABLE',
      valueColor: connected ? const Color(0xFF00FF88) : const Color(0xFFFF3344),
      subtitle: _baseUrl,
    );
  }

  Widget _eaCard(Map<String, dynamic>? ea) {
    if (ea == null) {
      return _card(
        icon: Icons.smart_toy_outlined,
        iconColor: const Color(0xFFFFB020),
        title: 'EXPERT ADVISOR',
        value: 'WAITING FOR EA',
        valueColor: const Color(0xFFFFB020),
        subtitle: 'No live EA status is available.',
      );
    }

    final running = ea['ea_running'] == true;
    final autoTrading = ea['auto_trading'] == true;
    final session = ea['session_open'] == true;
    final market = ea['market_connected'] == true;
    final tradingAllowed = ea['trading_allowed'] == true;

    return _card(
      icon: Icons.smart_toy_outlined,
      iconColor: running ? const Color(0xFF00FF88) : const Color(0xFFFF3344),
      title: 'EXPERT ADVISOR',
      value: running ? 'RUNNING' : 'NOT RUNNING',
      valueColor: running ? const Color(0xFF00FF88) : const Color(0xFFFF3344),
      children: [
        _line('EA Running', _yesNo(running), running),
        _line('Auto Trading', _yesNo(autoTrading), autoTrading),
        _line('Session', session ? 'OPEN' : 'CLOSED', session),
        _line('Market', market ? 'CONNECTED' : 'DISCONNECTED', market),
        _line('Trading', tradingAllowed ? 'READY' : 'WAITING', tradingAllowed),
      ],
    );
  }

  Widget _marketCard(Map<String, dynamic>? ea) {
    if (ea == null) {
      return _card(
        icon: Icons.candlestick_chart_outlined,
        iconColor: const Color(0xFFFFB020),
        title: 'MARKET CONNECTION',
        value: 'WAITING FOR EA',
        valueColor: const Color(0xFFFFB020),
      );
    }

    return _card(
      icon: Icons.candlestick_chart_outlined,
      iconColor: ea['market_connected'] == true
          ? const Color(0xFF00FF88)
          : const Color(0xFFFF3344),
      title: 'MARKET CONNECTION',
      children: [
        _line('Market', ea['market_connected'] == true ? 'CONNECTED' : 'DISCONNECTED',
            ea['market_connected'] == true),
        _line('Symbols Monitored', _display(ea['symbols_monitored'])),
        _line('Symbols Ready', _display(ea['symbols_ready'])),
        _line('Bullish', _display(ea['bullish_symbols'])),
        _line('Bearish', _display(ea['bearish_symbols'])),
      ],
    );
  }

  Widget _accountCard(Map<String, dynamic>? ea) {
    final hasAccount = ea != null &&
        (ea.containsKey('account_balance') ||
            ea.containsKey('account_equity') ||
            ea.containsKey('account_currency') ||
            ea.containsKey('open_positions'));

    return _card(
      icon: Icons.account_balance_wallet_outlined,
      iconColor: hasAccount
          ? const Color(0xFF00FF88)
          : const Color(0xFF7E9B96),
      title: 'ACCOUNT DATA',
      value: hasAccount ? null : 'NOT PUBLISHED BY EA',
      valueColor: const Color(0xFF7E9B96),
      children: [
        _line('Balance', _number(ea?['account_balance'])),
        _line('Equity', _number(ea?['account_equity'])),
        _line('Currency', _display(ea?['account_currency'])),
        _line('Open Positions', _display(ea?['open_positions'])),
      ],
    );
  }

  Widget _infrastructureCard(Map<String, dynamic>? ea) {
    return _card(
      icon: Icons.dns_outlined,
      iconColor: const Color(0xFF00FF88),
      title: 'INFRASTRUCTURE',
      children: [
        _line('Terminal', _display(ea?['terminal_name'])),
        _line('Broker', _display(ea?['broker_server'])),
        _line('VPS', _display(ea?['terminal_vps'])),
        _line('Terminal Build', _display(ea?['terminal_build'])),
        _line('Last Update', _display(_payload?['last_update'])),
      ],
    );
  }

  Widget _waitingCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101008),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8A6A10)),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_empty_rounded, color: Color(0xFFFFB020)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'WAITING FOR EA\nLive trading data will appear when the KHAYA EA publishes its heartbeat.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _markets() {
    final ea = _ea;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        _pageTitle('Markets', Icons.show_chart_rounded),
        const SizedBox(height: 18),
        _marketCard(ea),
        const SizedBox(height: 12),
        _card(
          icon: Icons.radar_outlined,
          iconColor: const Color(0xFF00FF88),
          title: 'MARKET DATA',
          value: ea == null ? 'WAITING FOR EA' : 'LIVE EA TELEMETRY',
          valueColor: ea == null
              ? const Color(0xFFFFB020)
              : const Color(0xFF00FF88),
          subtitle: ea == null
              ? 'No market figures are shown until the EA is connected.'
              : 'Counts below come directly from the EA status endpoint.',
        ),
      ],
    );
  }

  Widget _trades() {
    final ea = _ea;
    final openPositions = ea?['open_positions'];
    final hasFeed = openPositions != null ||
        (ea?.containsKey('positions') ?? false) ||
        (ea?.containsKey('trades') ?? false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        _pageTitle('Live Trades', Icons.swap_vert_rounded),
        const SizedBox(height: 18),
        _card(
          icon: Icons.receipt_long_outlined,
          iconColor: const Color(0xFF00FF88),
          title: 'LIVE POSITIONS',
          value: hasFeed ? _display(openPositions) : 'NO POSITION FEED',
          valueColor: hasFeed
              ? const Color(0xFF00FF88)
              : const Color(0xFF7E9B96),
          subtitle: hasFeed
              ? 'Position count supplied by the EA.'
              : 'No simulated trades are displayed.',
        ),
      ],
    );
  }

  Widget _risk() {
    final ea = _ea;
    final allowed = ea?['trading_allowed'] == true;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        _pageTitle('Risk Controls', Icons.shield_outlined),
        const SizedBox(height: 18),
        _card(
          icon: Icons.security_outlined,
          iconColor: allowed
              ? const Color(0xFF00FF88)
              : const Color(0xFFFFB020),
          title: 'TRADING PERMISSION',
          value: ea == null
              ? 'WAITING FOR EA'
              : (allowed ? 'READY' : 'WAITING'),
          valueColor: ea == null
              ? const Color(0xFFFFB020)
              : (allowed ? const Color(0xFF00FF88) : const Color(0xFFFFB020)),
          subtitle: 'The app does not invent or change risk limits. Values appear only when supplied by the live API.',
        ),
      ],
    );
  }

  Widget _settings() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        _pageTitle('Settings', Icons.settings_outlined),
        const SizedBox(height: 18),
        _card(
          icon: Icons.link_outlined,
          iconColor: const Color(0xFF00FF88),
          title: 'KHAYA API',
          children: [
            TextField(
              controller: apiController,
              keyboardType: TextInputType.url,
              onSubmitted: (_) => _refresh(),
              decoration: InputDecoration(
                labelText: 'Backend URL',
                hintText: 'http://10.223.173.27:8000',
                filled: true,
                fillColor: const Color(0xFF091416),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.sync),
                label: const Text('CONNECT / REFRESH'),
              ),
            ),
            const SizedBox(height: 12),
            _line('Polling', 'Every 3 seconds'),
            _line('Last successful fetch',
                _lastSuccessfulFetch?.toLocal().toString() ?? 'â€”'),
            _line('API status', _apiConnected ? 'CONNECTED' : 'OFFLINE',
                _apiConnected),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFFF3344)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          icon: Icons.info_outline,
          iconColor: const Color(0xFF7E9B96),
          title: 'REAL DATA POLICY',
          value: 'NO FAKE VALUES',
          valueColor: const Color(0xFF00FF88),
          subtitle:
              'Balance, equity, positions, prices and signals are shown only when the live EA/API supplies them.',
        ),
      ],
    );
  }

  Widget _pageTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00FF88), size: 30),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF7E9B96),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _statusPill(String text, bool good) {
    final color = good ? const Color(0xFF00FF88) : const Color(0xFFFF3344);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? value,
    Color? valueColor,
    String? subtitle,
    List<Widget> children = const [],
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF061416),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF123B3A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF7E9B96),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          if (value != null) ...[
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
          if (children.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _line(String label, String value, [bool? positive]) {
    final color = positive == null
        ? Colors.white
        : (positive ? const Color(0xFF00FF88) : const Color(0xFFFF3344));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF7E9B96), fontSize: 11),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _display(dynamic value) {
    if (value == null) return 'â€”';
    if (value is bool) return value ? 'YES' : 'NO';
    return value.toString();
  }

  String _number(dynamic value) {
    if (value == null) return 'â€”';
    if (value is num) return value.toStringAsFixed(2);
    return value.toString();
  }

  String _yesNo(bool value) => value ? 'YES' : 'NO';
}

