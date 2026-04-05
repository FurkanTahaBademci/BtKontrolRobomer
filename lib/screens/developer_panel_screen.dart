import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;
import 'package:bt_kontrol_robomer/services/log_service.dart';
import 'package:bt_kontrol_robomer/providers/connection_history_provider.dart';
import 'package:bt_kontrol_robomer/providers/bluetooth_provider.dart';
import 'package:bt_kontrol_robomer/providers/settings_provider.dart';

/// Geliştirici Paneli - Gizli erişim ekranı
class DeveloperPanelScreen extends StatefulWidget {
  const DeveloperPanelScreen({super.key});

  @override
  State<DeveloperPanelScreen> createState() => _DeveloperPanelScreenState();
}

class _DeveloperPanelScreenState extends State<DeveloperPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Log filtre / arama
  LogLevel? _selectedLevel;
  bool _showSearch = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Cihaz / Uygulama bilgisi
  PackageInfo? _packageInfo;
  Map<String, String> _deviceInfo = {};
  bool _deviceInfoLoading = true;
  String? _deviceInfoError;

  // BT Adaptör bilgisi
  Map<String, String> _btAdapterInfo = {};
  bool _btAdapterLoading = true;

  // Gecikme testi
  int _latencySampleCount = 20;

  // Uptime yenilemek için timer
  Timer? _uptimeTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAppAndDeviceInfo();
    _loadBtAdapterInfo();
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _uptimeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAppAndDeviceInfo() async {
    setState(() {
      _deviceInfoLoading = true;
      _deviceInfoError = null;
    });
    try {
      final pkg = await PackageInfo.fromPlatform();
      final deviceInfoPlugin = DeviceInfoPlugin();
      final Map<String, String> info = {};

      if (Platform.isAndroid) {
        final android = await deviceInfoPlugin.androidInfo;
        info['Platform'] =
            'Android ${android.version.release} (SDK ${android.version.sdkInt})';
        info['Marka'] = android.brand;
        info['Model'] = android.model;
        info['Ürün'] = android.product;
        info['Cihaz'] = android.device;
        info['Üretici'] = android.manufacturer;
        info['Donanım'] = android.hardware;
        info['Parmak İzi'] = android.fingerprint;
      } else if (Platform.isIOS) {
        final ios = await deviceInfoPlugin.iosInfo;
        info['Platform'] = 'iOS ${ios.systemVersion}';
        info['Model'] = ios.model;
        info['Cihaz'] = ios.name;
        info['Sistem'] = ios.systemName;
        info['Makine'] = ios.utsname.machine;
      } else {
        info['Platform'] = Platform.operatingSystem;
      }

      if (mounted) {
        setState(() {
          _packageInfo = pkg;
          _deviceInfo = info;
          _deviceInfoLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deviceInfoLoading = false;
          _deviceInfoError = e.toString();
        });
      }
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.developer_mode, size: 20, color: Colors.orange),
            SizedBox(width: 8),
            Text('Geliştirici Paneli'),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Kontrol'),
            Tab(icon: Icon(Icons.article_outlined), text: 'Loglar'),
            Tab(icon: Icon(Icons.phone_android), text: 'Cihaz'),
            Tab(icon: Icon(Icons.history), text: 'Geçmiş'),
            Tab(icon: Icon(Icons.speed), text: 'Test'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildLogsTab(),
          _buildDeviceTab(),
          _buildHistoryTab(),
          _buildTestTab(),
        ],
      ),
    );
  }

  // ─── KONTROL / DASHBOARD TAB ──────────────────────────────────────────────

  Widget _buildDashboardTab() {
    return Consumer<BluetoothProvider>(
      builder: (context, bt, _) {
        final isConnected = bt.isConnected;
        final connectedDevice = bt.connectedDevice;
        final connectedAt = bt.connectedAt;

        // Uptime hesapla
        String uptimeText = '—';
        if (isConnected && connectedAt != null) {
          final diff = DateTime.now().difference(connectedAt);
          final h = diff.inHours;
          final m = diff.inMinutes.remainder(60);
          final s = diff.inSeconds.remainder(60);
          uptimeText =
              h > 0
                  ? '${h}s ${m}d ${s}sn'
                  : m > 0
                  ? '${m}d ${s}sn'
                  : '${s}sn';
        }

        final totalCmds = bt.cmdSent + bt.cmdFailed;
        final successRate =
            totalCmds > 0
                ? '${(bt.cmdSent / totalCmds * 100).toStringAsFixed(1)}%'
                : '—';

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // BT Durum banner
            _btStatusBanner(bt),
            const SizedBox(height: 12),

            // İstatistik ızgarası (3×2)
            Text(
              'İstatistikler',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              childAspectRatio: 1.35,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _statCard(
                  'Tarama',
                  '${bt.scanCount}',
                  Icons.radar,
                  Colors.blue,
                ),
                _statCard(
                  'Bağlantı',
                  '${bt.connectCount}',
                  Icons.link,
                  Colors.green,
                ),
                _statCard(
                  'Kopma',
                  '${bt.disconnectCount}',
                  Icons.link_off,
                  Colors.orange,
                ),
                _statCard(
                  'Gönderilen',
                  '${bt.cmdSent}',
                  Icons.send,
                  Colors.teal,
                ),
                _statCard(
                  'Başarısız',
                  '${bt.cmdFailed}',
                  Icons.error_outline,
                  Colors.red,
                ),
                _statCard('Başarı', successRate, Icons.percent, Colors.purple),
              ],
            ),
            const SizedBox(height: 12),

            // Aktif bağlantı kartı
            if (isConnected && connectedDevice != null) ...[
              Card(
                color: Colors.green.shade50,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.green.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.bluetooth_connected,
                            color: Colors.green,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Aktif Bağlantı',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              uptimeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      _infoRow('Cihaz', connectedDevice.name),
                      _infoRow('Adres', connectedDevice.address),
                      _infoRow('Tip', connectedDevice.type.name.toUpperCase()),
                      if (connectedDevice.rssi != null)
                        _infoRow('RSSI', '${connectedDevice.rssi} dBm'),
                      if (totalCmds > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Komut Başarısı',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${bt.cmdSent}/$totalCmds',
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: bt.cmdSent / totalCmds,
                          backgroundColor: Colors.red.shade100,
                          color: Colors.green,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Log özeti
            ListenableBuilder(
              listenable: LogService.instance,
              builder: (context, _) {
                final entries = LogService.instance.entries;
                final okCount =
                    entries.where((e) => e.level == LogLevel.success).length;
                final infoCount =
                    entries.where((e) => e.level == LogLevel.info).length;
                final warnCount =
                    entries.where((e) => e.level == LogLevel.warning).length;
                final errCount =
                    entries.where((e) => e.level == LogLevel.error).length;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.article_outlined,
                              size: 16,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Log Özeti',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${entries.length} kayıt',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _logCountBadge('OK', okCount, Colors.green),
                            _logCountBadge('INFO', infoCount, Colors.blue),
                            _logCountBadge('WARN', warnCount, Colors.orange),
                            _logCountBadge('HATA', errCount, Colors.red),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.article_outlined,
                                  size: 16,
                                ),
                                label: const Text('Loglara Git'),
                                onPressed: () => _tabController.animateTo(1),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                ),
                                label: const Text('Temizle'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () => LogService.instance.clear(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Hızlı aksiyonlar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.flash_on, size: 16, color: Colors.orange),
                        SizedBox(width: 6),
                        Text(
                          'Hızlı Aksiyonlar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _actionTile(
                      icon: Icons.developer_mode,
                      label: 'Geliştirici Modunu Aç/Kapat',
                      color: Colors.orange,
                      onTap: () {
                        final s = context.read<SettingsProvider>();
                        s.setDeveloperMode(!s.developerMode);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Geliştirici modu: ${s.developerMode ? "AÇIK" : "KAPALI"}',
                            ),
                          ),
                        );
                      },
                    ),
                    _actionTile(
                      icon: Icons.copy,
                      label: 'Logları Panoya Kopyala',
                      color: Colors.blue,
                      onTap: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: LogService.instance.exportAsText(),
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Loglar kopyalandı')),
                        );
                      },
                    ),
                    _actionTile(
                      icon: Icons.delete_sweep,
                      label: 'Tüm Logları Temizle',
                      color: Colors.red,
                      onTap: () {
                        LogService.instance.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Loglar temizlendi')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _btStatusBanner(BluetoothProvider bt) {
    final Color color;
    final String label;
    final IconData icon;

    if (bt.isConnected) {
      color = Colors.green;
      label = 'Bağlı — ${bt.connectedDevice?.name ?? ""}';
      icon = Icons.bluetooth_connected;
    } else if (bt.isScanning) {
      color = Colors.blue;
      label = 'Taranıyor...';
      icon = Icons.radar;
    } else {
      color = Colors.grey;
      label = 'Bağlantısız';
      icon = Icons.bluetooth_disabled;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
          ),
          Text(
            bt.currentType.name.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _logCountBadge(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ─── LOGLAR TAB ──────────────────────────────────────────────────────────

  Widget _buildLogsTab() {
    return ListenableBuilder(
      listenable: LogService.instance,
      builder: (context, _) {
        final allEntries = LogService.instance.entries;
        var filtered =
            _selectedLevel == null
                ? allEntries
                : allEntries.where((e) => e.level == _selectedLevel).toList();

        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          filtered =
              filtered
                  .where(
                    (e) =>
                        e.message.toLowerCase().contains(q) ||
                        e.tag.toLowerCase().contains(q),
                  )
                  .toList();
        }

        return Column(
          children: [
            // Toolbar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip(null, 'Tümü', Colors.grey),
                          const SizedBox(width: 6),
                          _filterChip(LogLevel.success, 'OK', Colors.green),
                          const SizedBox(width: 6),
                          _filterChip(LogLevel.info, 'INFO', Colors.blue),
                          const SizedBox(width: 6),
                          _filterChip(LogLevel.warning, 'WARN', Colors.orange),
                          const SizedBox(width: 6),
                          _filterChip(LogLevel.error, 'HATA', Colors.red),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _showSearch ? Icons.search_off : Icons.search,
                      size: 20,
                      color: _showSearch ? Colors.blue : null,
                    ),
                    tooltip: 'Ara',
                    onPressed:
                        () => setState(() {
                          _showSearch = !_showSearch;
                          if (!_showSearch) {
                            _searchController.clear();
                            _searchQuery = '';
                          }
                        }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    tooltip: 'Logları kopyala',
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: LogService.instance.exportAsText()),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Loglar panoya kopyalandı'),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Logları temizle',
                    onPressed: _confirmClearLogs,
                  ),
                ],
              ),
            ),

            // Arama çubuğu
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Mesaj veya etiket ara...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon:
                        _searchQuery.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed:
                                  () => setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  }),
                            )
                            : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),

            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${filtered.length} / ${allEntries.length} kayıt',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),

            Expanded(
              child:
                  filtered.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            const Text('Kayıt yok'),
                          ],
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        itemCount: filtered.length,
                        itemBuilder:
                            (context, index) => _buildLogItem(filtered[index]),
                      ),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearLogs() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Logları Temizle'),
            content: const Text('Tüm loglar silinecek.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () {
                  LogService.instance.clear();
                  Navigator.pop(ctx);
                },
                child: const Text('Temizle'),
              ),
            ],
          ),
    );
  }

  Widget _filterChip(LogLevel? level, String label, Color color) {
    final isSelected = _selectedLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _selectedLevel = level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.4),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : color.withOpacity(0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildLogItem(LogEntry entry) {
    final color = _levelColor(entry.level);
    return GestureDetector(
      onLongPress: () {
        final text =
            '[${entry.formattedTime}] [${entry.levelLabel.trim()}] [${entry.tag}] ${entry.message}';
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Log satırı kopyalandı'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          border: Border(left: BorderSide(color: color, width: 3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.formattedTime,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        entry.levelLabel.trim(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '[${entry.tag}]',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  entry.message,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
      case LogLevel.success:
        return Colors.green;
    }
  }

  // ─── CİHAZ TAB ───────────────────────────────────────────────────────────

  Widget _buildDeviceTab() {
    if (_deviceInfoLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cihaz bilgisi yükleniyor...'),
          ],
        ),
      );
    }

    if (_deviceInfoError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 52, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                'Cihaz bilgisi yüklenemedi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                _deviceInfoError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                onPressed: _loadAppAndDeviceInfo,
              ),
            ],
          ),
        ),
      );
    }

    String buildCopyText() {
      final buf = StringBuffer();
      buf.writeln('=== UYGULAMA ===');
      if (_packageInfo != null) {
        buf.writeln('Paket: ${_packageInfo!.packageName}');
        buf.writeln('Versiyon: ${_packageInfo!.version}');
        buf.writeln('Build: ${_packageInfo!.buildNumber}');
      }
      buf.writeln('\n=== CİHAZ ===');
      for (final e in _deviceInfo.entries) {
        buf.writeln('${e.key}: ${e.value}');
      }
      final bt = context.read<BluetoothProvider>();
      buf.writeln('\n=== BLUETOOTH ===');
      buf.writeln('Tip: ${bt.currentType.name.toUpperCase()}');
      buf.writeln('Durum: ${bt.connectionState.name}');
      buf.writeln('Bağlı Cihaz: ${bt.connectedDevice?.name ?? "Yok"}');
      return buf.toString();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Uygulama bilgisi
        _infoSection('Uygulama', Icons.apps, [
          if (_packageInfo != null) ...[
            _selectableInfoRow('Paket Adı', _packageInfo!.packageName),
            _selectableInfoRow('Versiyon', _packageInfo!.version),
            _selectableInfoRow('Build Numarası', _packageInfo!.buildNumber),
          ],
        ]),
        const SizedBox(height: 12),

        // Cihaz bilgisi
        _infoSection(
          'Cihaz',
          Icons.phone_android,
          _deviceInfo.entries
              .map((e) => _selectableInfoRow(e.key, e.value))
              .toList(),
        ),
        const SizedBox(height: 12),

        // BT durumu (reaktif)
        Consumer<BluetoothProvider>(
          builder:
              (context, bt, _) =>
                  _infoSection('Bluetooth Durumu', Icons.bluetooth, [
                    _infoRow('Tip', bt.currentType.name.toUpperCase()),
                    _infoRow('Durum', bt.connectionState.name),
                    _infoRow('Bağlı Cihaz', bt.connectedDevice?.name ?? 'Yok'),
                    _infoRow('Taranıyor', bt.isScanning ? 'Evet' : 'Hayır'),
                    _infoRow('Bulunan Cihaz', '${bt.devices.length}'),
                  ]),
        ),
        const SizedBox(height: 16),

        // Kopyala butonu
        FilledButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Tüm Bilgiyi Kopyala'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: buildCopyText()));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cihaz bilgisi kopyalandı')),
            );
          },
        ),
      ],
    );
  }

  // ─── GEÇMİŞ TAB ──────────────────────────────────────────────────────────

  Widget _buildHistoryTab() {
    final historyProvider = context.watch<ConnectionHistoryProvider>();
    final history = historyProvider.history;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            const Text('Bağlantı geçmişi boş'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${history.length} kayıtlı cihaz',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Tümünü Sil'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _confirmClearHistory(historyProvider),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final device = history[index];
              final isFirst = index == 0;
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: Icon(
                    device.type.name == 'classic'
                        ? Icons.bluetooth
                        : Icons.bluetooth_searching,
                    color: isFirst ? Colors.indigo : Colors.blue,
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          device.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isFirst ? Colors.indigo[700] : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFirst) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Son Bağlanan',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    '${device.address}  •  ${device.type.name.toUpperCase()}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: Colors.red,
                    onPressed: () => historyProvider.removeDevice(device),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _confirmClearHistory(ConnectionHistoryProvider provider) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Geçmişi Temizle'),
            content: const Text('Tüm bağlantı geçmişi silinecek.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  provider.clearHistory();
                  Navigator.pop(ctx);
                },
                child: const Text('Sil'),
              ),
            ],
          ),
    );
  }

  // ─── PAYLAŞILAN WIDGET'LAR ───────────────────────────────────────────────

  Widget _infoSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectableInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BT ADAPTÖR BİLGİSİ YÜKLEYİCİ ──────────────────────────────────────

  Future<void> _loadBtAdapterInfo() async {
    setState(() {
      _btAdapterLoading = true;
      _btAdapterInfo = {};
    });
    try {
      final name = await fbs.FlutterBluetoothSerial.instance.name;
      final address = await fbs.FlutterBluetoothSerial.instance.address;
      final state = await fbs.FlutterBluetoothSerial.instance.state;
      final isDiscoverable =
          await fbs.FlutterBluetoothSerial.instance.isDiscoverable;

      final info = <String, String>{
        'Adaptör Adı': name ?? 'Bilinmiyor',
        'MAC Adresi': address ?? 'Bilinmiyor',
        'BT Durumu': _btStateLabel(state),
        'Keşfedilebilir': isDiscoverable == true ? 'Evet' : 'Hayır',
      };

      // SDK'ya göre BT sürümü tahmini
      if (Platform.isAndroid && _deviceInfo.containsKey('Platform')) {
        final match = RegExp(
          r'SDK (\d+)',
        ).firstMatch(_deviceInfo['Platform'] ?? '');
        if (match != null) {
          final sdk = int.tryParse(match.group(1) ?? '') ?? 0;
          info['Tahmini BT Sürümü'] =
              sdk >= 33
                  ? 'BT 5.0+ (API $sdk)'
                  : sdk >= 26
                  ? 'BT 5.0 uyumlu (API $sdk)'
                  : sdk >= 21
                  ? 'BT 4.1+ / BLE (API $sdk)'
                  : 'BT Classic (API $sdk)';
          info['BLE Desteği'] = sdk >= 21 ? 'Evet' : 'Hayır';
          info['Genişletilmiş Reklam'] =
              sdk >= 26 ? 'Muhtemelen Evet' : 'Belirsiz';
        }
      }

      if (mounted) {
        setState(() {
          _btAdapterInfo = info;
          _btAdapterLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _btAdapterInfo = {'Hata': e.toString()};
          _btAdapterLoading = false;
        });
      }
    }
  }

  String _btStateLabel(fbs.BluetoothState state) {
    if (state == fbs.BluetoothState.STATE_ON) return 'AÇIK';
    if (state == fbs.BluetoothState.STATE_OFF) return 'KAPALI';
    if (state == fbs.BluetoothState.STATE_TURNING_ON) return 'Açılıyor...';
    if (state == fbs.BluetoothState.STATE_TURNING_OFF) return 'Kapanıyor...';
    return 'Bilinmiyor';
  }

  // ─── TEST TAB ─────────────────────────────────────────────────────────────

  Widget _buildTestTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // BT Sistem Bilgisi
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bluetooth, size: 18, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'BT Sistem Bilgisi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (!_btAdapterLoading)
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18),
                        tooltip: 'Yenile',
                        onPressed: _loadBtAdapterInfo,
                      ),
                  ],
                ),
                const Divider(height: 16),
                if (_btAdapterLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  ..._btAdapterInfo.entries
                      .map((e) => _selectableInfoRow(e.key, e.value))
                      .toList(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Gecikme Testi
        Consumer<BluetoothProvider>(
          builder: (context, bt, _) {
            final isBusy = bt.isLatencyTesting || bt.isBurstTesting;
            final results = bt.latencyResults;
            int? minMs, maxMs;
            double? avgMs, stdDev;
            if (results.isNotEmpty) {
              minMs = results.reduce((a, b) => a < b ? a : b);
              maxMs = results.reduce((a, b) => a > b ? a : b);
              avgMs = results.reduce((a, b) => a + b) / results.length;
              if (results.length > 1) {
                final variance =
                    results
                        .map((v) => (v - avgMs!) * (v - avgMs))
                        .reduce((a, b) => a + b) /
                    results.length;
                stdDev = variance > 0 ? variance / variance * variance : 0;
                // correct stddev
                stdDev =
                    results.length > 1
                        ? (results
                                    .map((v) => (v - avgMs!) * (v - avgMs))
                                    .reduce((a, b) => a + b) /
                                results.length)
                            .toDouble()
                        : 0;
                stdDev = stdDev > 0 ? stdDev.abs() : 0;
                // sqrt via iteration
                if (stdDev > 0) {
                  double s = stdDev;
                  for (int i = 0; i < 20; i++) {
                    s = (s + stdDev / s) / 2;
                  }
                  stdDev = s;
                }
              }
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Gecikme Testi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        if (results.isNotEmpty && !bt.isLatencyTesting)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: bt.clearTestResults,
                            tooltip: 'Sonuçları Temizle',
                          ),
                      ],
                    ),
                    Text(
                      'BT soket yazma gecikmesini ölçer. Bağlı cihaz gereklidir.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Örnek sayısı seçici
                    if (!bt.isLatencyTesting) ...[
                      Row(
                        children: [
                          Text(
                            'Örnek:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(width: 8),
                          for (final n in [10, 20, 50])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: GestureDetector(
                                onTap:
                                    () =>
                                        setState(() => _latencySampleCount = n),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _latencySampleCount == n
                                            ? Colors.orange.withOpacity(0.2)
                                            : Colors.transparent,
                                    border: Border.all(
                                      color:
                                          _latencySampleCount == n
                                              ? Colors.orange
                                              : Colors.grey.withOpacity(0.4),
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '$n',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                          _latencySampleCount == n
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      color:
                                          _latencySampleCount == n
                                              ? Colors.orange
                                              : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Canlı ilerleme
                    if (bt.isLatencyTesting) ...[
                      Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${results.length} / $_latencySampleCount ölçüm...',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                          if (results.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Son: ${results.last}ms',
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: results.length / _latencySampleCount,
                          minHeight: 8,
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Sonuç istatistikleri
                    if (results.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _latencyStat('MIN', '${minMs}ms', Colors.green),
                          _latencyStat(
                            'ORT',
                            '${avgMs!.toStringAsFixed(1)}ms',
                            Colors.blue,
                          ),
                          _latencyStat('MAKS', '${maxMs}ms', Colors.red),
                          if (stdDev != null)
                            _latencyStat(
                              'σ',
                              '${stdDev.toStringAsFixed(1)}ms',
                              Colors.grey,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildLatencyChart(results),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          results.where((v) => v <= 15).length == results.length
                              ? '✓ Gecikme İYİ'
                              : results.where((v) => v > 30).length >
                                  results.length ~/ 3
                              ? '⚠ Gecikme YÜKSEK'
                              : '~ Gecikme ORTA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color:
                                results.where((v) => v <= 15).length ==
                                        results.length
                                    ? Colors.green
                                    : results.where((v) => v > 30).length >
                                        results.length ~/ 3
                                    ? Colors.red
                                    : Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    if (bt.latencyTestError != null && !bt.isLatencyTesting)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          bt.latencyTestError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.timer_outlined, size: 16),
                        label: Text(
                          bt.isLatencyTesting
                              ? 'Test Çalışıyor...'
                              : 'Gecikme Testi Başlat',
                        ),
                        onPressed:
                            isBusy || !bt.isConnected
                                ? null
                                : () => bt.runLatencyTest(
                                  samples: _latencySampleCount,
                                ),
                      ),
                    ),
                    if (!bt.isConnected)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Test için bir cihaza bağlanın',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Burst Testi
        Consumer<BluetoothProvider>(
          builder: (context, bt, _) {
            final isBusy = bt.isLatencyTesting || bt.isBurstTesting;
            final cps = bt.burstCommandsPerSec;

            Color cpsColor = Colors.grey;
            String cpsLabel = '';
            if (cps > 0) {
              if (cps >= 30) {
                cpsColor = Colors.green;
                cpsLabel = '✓ İYİ (≥30 cmd/s)';
              } else if (cps >= 15) {
                cpsColor = Colors.orange;
                cpsLabel = '⚠ ORTA (15-30 cmd/s)';
              } else {
                cpsColor = Colors.red;
                cpsLabel = '✗ YAVAŞ (<15 cmd/s)';
              }
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.rocket_launch_outlined,
                          size: 16,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Burst Testi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '30 komutu arka arkaya göndererek maksimum komut/saniye değerini ölçer.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (bt.isBurstTesting) ...[
                      const Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Burst testi çalışıyor...',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (cps > 0 && !bt.isBurstTesting) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        width: double.infinity,
                        child: Column(
                          children: [
                            Text(
                              '$cps',
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                                color: cpsColor,
                              ),
                            ),
                            Text(
                              'komut / saniye',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cpsLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: cpsColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(
                          Icons.rocket_launch_outlined,
                          size: 16,
                        ),
                        label: Text(
                          bt.isBurstTesting
                              ? 'Test Çalışıyor...'
                              : 'Burst Testi Başlat',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        onPressed:
                            isBusy || !bt.isConnected
                                ? null
                                : () => bt.runBurstTest(),
                      ),
                    ),
                    if (!bt.isConnected)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Test için bir cihaza bağlanın',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _latencyStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildLatencyChart(List<int> results) {
    if (results.isEmpty) return const SizedBox.shrink();
    final maxVal = results
        .reduce((a, b) => a > b ? a : b)
        .toDouble()
        .clamp(1.0, 1e9);

    return SizedBox(
      height: 64,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            results.map((v) {
              final ratio = (v / maxVal).clamp(0.05, 1.0);
              final color =
                  v <= 10
                      ? Colors.green
                      : v <= 30
                      ? Colors.orange
                      : Colors.red;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: ratio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
