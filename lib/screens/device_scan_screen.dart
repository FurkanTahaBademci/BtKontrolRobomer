import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bt_kontrol_robomer/providers/bluetooth_provider.dart';
import 'package:bt_kontrol_robomer/providers/settings_provider.dart';
import 'package:bt_kontrol_robomer/providers/connection_history_provider.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/bluetooth_device_model.dart';
import 'package:bt_kontrol_robomer/widgets/device_list_tile.dart';
import 'package:bt_kontrol_robomer/screens/robot_control_screen.dart';
import 'package:bt_kontrol_robomer/screens/settings_screen.dart';

/// Bluetooth cihaz tarama ekranı
class DeviceScanScreen extends StatefulWidget {
  const DeviceScanScreen({super.key});

  @override
  State<DeviceScanScreen> createState() => _DeviceScanScreenState();
}

class _DeviceScanScreenState extends State<DeviceScanScreen> {
  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = context.watch<BluetoothProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    context.watch<ConnectionHistoryProvider>(); // yeniden sıralama için dinle

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Robot Kontrol'),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ayarlar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Logo
            _buildAppLogo(),

            // Bluetooth tipi seçimi
            _buildBluetoothTypeSelector(bluetoothProvider),

            // Tarama butonu
            _buildScanButton(bluetoothProvider),

            // Geliştirici Modu - Test Butonu
            if (settingsProvider.developerMode) _buildDevModeButton(),

            // Hata mesajı
            if (bluetoothProvider.errorMessage != null)
              _buildErrorCard(bluetoothProvider),

            // Bulunan cihazlar
            Expanded(child: _buildDeviceList(bluetoothProvider)),
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothTypeSelector(BluetoothProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              'Classic BT',
              Icons.bluetooth,
              BluetoothDeviceType.classic,
              provider,
            ),
          ),
          Expanded(
            child: _buildTypeButton(
              'BLE',
              Icons.bluetooth_searching,
              BluetoothDeviceType.ble,
              provider,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    String label,
    IconData icon,
    BluetoothDeviceType type,
    BluetoothProvider provider,
  ) {
    final isSelected = provider.currentType == type;
    return GestureDetector(
      onTap: () => provider.setBluetoothType(type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton(BluetoothProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed:
              provider.isScanning
                  ? () => provider.stopScan()
                  : () => provider.startScan(),
          icon: Icon(provider.isScanning ? Icons.stop : Icons.search),
          label: Text(
            provider.isScanning ? 'Taramayı Durdur' : 'Cihaz Tara',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: provider.isScanning ? Colors.orange : Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BluetoothProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              provider.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () => provider.clearError(),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BluetoothProvider provider) {
    if (provider.isScanning && provider.devices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cihazlar aranıyor...'),
          ],
        ),
      );
    }

    if (provider.devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bluetooth_disabled,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Cihaz bulunamadı',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tarama butonuna basarak cihaz arayın',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: provider.devices.length,
      itemBuilder: (context, index) {
        final sortedDevices = _sortedDevices(provider);
        final device = sortedDevices[index];
        final lastConnectedAddress =
            context.read<ConnectionHistoryProvider>().history.isNotEmpty
                ? context
                    .read<ConnectionHistoryProvider>()
                    .history
                    .first
                    .address
                : null;
        return DeviceListTile(
          device: device,
          onTap: () => _connectToDevice(device, provider),
          isScanning: provider.isScanning,
          isLastConnected: device.address == lastConnectedAddress,
          isActive:
              !provider.isScanning &&
                      provider.devices.isNotEmpty &&
                      device.rssi == null &&
                      provider.currentType == BluetoothDeviceType.classic
                  ? false
                  : null,
        );
      },
    );
  }

  /// Tarama tamamlanınca listeyi sırala:
  /// 1. Son bağlanan cihaz (geçmişin ilk elemanı)
  /// 2. Aktif cihazlar (RSSI var) — sinyal gücüne göre güçlüden zayıfa
  /// 3. Kapsama dışı cihazlar
  List<BluetoothDeviceModel> _sortedDevices(BluetoothProvider provider) {
    // Tarama devam ederken sıralama yapma
    if (provider.isScanning) return provider.devices;

    final history = context.read<ConnectionHistoryProvider>().history;
    final lastAddress = history.isNotEmpty ? history.first.address : null;

    final sorted = [...provider.devices];
    sorted.sort((a, b) {
      final aIsLast = a.address == lastAddress;
      final bIsLast = b.address == lastAddress;
      if (aIsLast && !bIsLast) return -1;
      if (!aIsLast && bIsLast) return 1;

      final aActive = a.rssi != null;
      final bActive = b.rssi != null;
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;
      if (aActive && bActive) return b.rssi!.compareTo(a.rssi!);

      return 0;
    });
    return sorted;
  }

  Future<void> _connectToDevice(
    BluetoothDeviceModel device,
    BluetoothProvider bluetoothProvider,
  ) async {
    // Bağlantı dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Bağlanıyor...'),
              ],
            ),
          ),
    );

    final success = await bluetoothProvider.connectToDevice(device);

    if (mounted) {
      Navigator.of(context).pop(); // Dialog kapat

      if (success) {
        // Geçmişe kaydet
        context.read<ConnectionHistoryProvider>().saveDevice(device);

        // Kontrol ekranına git
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const RobotControlScreen()),
        );
      } else {
        final errorMsg = bluetoothProvider.errorMessage;
        bluetoothProvider.clearError();
        _showConnectionErrorDialog(
          context,
          device,
          bluetoothProvider,
          errorMsg,
        );
      }
    }
  }

  void _showConnectionErrorDialog(
    BuildContext context,
    BluetoothDeviceModel device,
    BluetoothProvider bluetoothProvider,
    String? errorMsg,
  ) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            icon: const Icon(
              Icons.bluetooth_disabled,
              color: Colors.red,
              size: 40,
            ),
            title: const Text('Bağlantı Başarısız'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cihaz',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        device.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        device.address,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  errorMsg ?? '${device.name} cihazına bağlanılamadı.',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Kapat'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tekrar Dene'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _connectToDevice(device, bluetoothProvider);
                },
              ),
            ],
          ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/app_logo.png',
            height: 36,
            width: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          const Text(
            'Mucit Akademisi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDevModeButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RobotControlScreen()),
          );
        },
        icon: const Icon(Icons.bug_report),
        label: const Text(
          'Test Ekranı (Geliştirici Modu)',
          style: TextStyle(fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 0),
        ),
      ),
    );
  }
}
