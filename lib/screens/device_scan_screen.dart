import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bt_kontrol_robomer/providers/bluetooth_provider.dart';
import 'package:bt_kontrol_robomer/providers/connection_history_provider.dart';
import 'package:bt_kontrol_robomer/providers/settings_provider.dart';
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
  void initState() {
    super.initState();
    // Bağlantı geçmişini yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionHistoryProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = context.watch<BluetoothProvider>();
    final historyProvider = context.watch<ConnectionHistoryProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

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
          if (historyProvider.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Geçmişi Temizle',
              onPressed:
                  () => _showClearHistoryDialog(context, historyProvider),
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

            // Bağlantı geçmişi
            if (historyProvider.history.isNotEmpty &&
                !bluetoothProvider.isScanning)
              _buildHistorySection(historyProvider, bluetoothProvider),

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

  Widget _buildHistorySection(
    ConnectionHistoryProvider historyProvider,
    BluetoothProvider bluetoothProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                'Son Bağlantılar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: historyProvider.history.length,
            itemBuilder: (context, index) {
              final device = historyProvider.history[index];
              // Mevcut tarama sonuçlarında bu cihaz var mı?
              final bool? isActive =
                  bluetoothProvider.devices.isEmpty
                      ? null
                      : bluetoothProvider.devices.any(
                        (d) => d.address == device.address,
                      );
              return SizedBox(
                width: 260,
                child: DeviceListTile(
                  device: device,
                  isFromHistory: true,
                  isActive: isActive,
                  onDelete: () => historyProvider.removeDevice(device),
                  onTap:
                      () => _connectToDevice(
                        device,
                        bluetoothProvider,
                        historyProvider,
                      ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 32),
      ],
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
        final device = provider.devices[index];
        return DeviceListTile(
          device: device,
          onTap:
              () => _connectToDevice(
                device,
                provider,
                context.read<ConnectionHistoryProvider>(),
              ),
        );
      },
    );
  }

  Future<void> _connectToDevice(
    BluetoothDeviceModel device,
    BluetoothProvider bluetoothProvider,
    ConnectionHistoryProvider historyProvider,
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
        // Geçmişe ekle
        await historyProvider.saveDevice(device);

        // Kontrol ekranına git
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const RobotControlScreen()),
        );
      } else {
        // Sadece altta snackbar göster, üstteki hata kartını temizle
        bluetoothProvider.clearError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${device.name} cihazına bağlanılamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearHistoryDialog(
    BuildContext context,
    ConnectionHistoryProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Geçmişi Temizle'),
            content: const Text(
              'Tüm bağlantı geçmişi silinecek. Emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () {
                  provider.clearHistory();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Temizle',
                  style: TextStyle(color: Colors.red),
                ),
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
