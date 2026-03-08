import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bt_kontrol_robomer/providers/bluetooth_provider.dart';
import 'package:bt_kontrol_robomer/providers/settings_provider.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/robot_command.dart';
import 'package:bt_kontrol_robomer/widgets/direction_button.dart';
import 'package:bt_kontrol_robomer/widgets/connection_status_indicator.dart';

/// Robot kontrol ekranı
class RobotControlScreen extends StatefulWidget {
  const RobotControlScreen({super.key});

  @override
  State<RobotControlScreen> createState() => _RobotControlScreenState();
}

class _RobotControlScreenState extends State<RobotControlScreen> {
  bool _speedChangeInProgress = false;

  @override
  void initState() {
    super.initState();
    // Ekranı yatay (landscape) moda ayarla
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Varsayılan hızı ayarla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = context.read<SettingsProvider>();
      final bluetoothProvider = context.read<BluetoothProvider>();
      bluetoothProvider.updateSpeed(settingsProvider.defaultSpeed);
    });
  }

  @override
  void dispose() {
    // Ekran yönlendirmesini serbest bırak
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bluetoothProvider = context.watch<BluetoothProvider>();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _showDisconnectDialog();
        if (shouldPop == true && mounted) {
          await bluetoothProvider.disconnect();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Robot Kontrol'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldDisconnect = await _showDisconnectDialog();
              if (shouldDisconnect == true && mounted) {
                await bluetoothProvider.disconnect();
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: ConnectionStatusIndicator(
                  state: bluetoothProvider.connectionState,
                  deviceName: bluetoothProvider.connectedDevice?.name,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Row(
            children: [
              // Sol taraf - Hız kontrolü ve Acil Dur
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          56,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Bağlantı durumu bilgisi
                        if (!bluetoothProvider.isConnected)
                          _buildConnectionLostBanner(bluetoothProvider),

                        const SizedBox(height: 8),

                        // Hız kontrolü
                        _buildSpeedControl(bluetoothProvider),

                        const SizedBox(height: 8),

                        // Acil dur butonu
                        _buildStopButton(bluetoothProvider),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),

              // Sağ taraf - Yön kontrolleri
              Expanded(
                flex: 4,
                child: Center(
                  child: _buildDirectionControls(bluetoothProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionLostBanner(BluetoothProvider provider) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isDevMode = settingsProvider.developerMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDevMode ? Colors.orange.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDevMode ? Icons.developer_mode : Icons.warning_amber,
            color: isDevMode ? Colors.orange.shade700 : Colors.red.shade700,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isDevMode
                  ? 'Geliştirici Modu - Cihaz bağlı değil!'
                  : 'Bağlantı kesildi!',
              style: TextStyle(
                color: isDevMode ? Colors.orange.shade900 : Colors.red.shade900,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Geri', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedControl(BluetoothProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.speed, color: Colors.blue, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Motor',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${provider.currentSpeed}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                '0',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
              Expanded(
                child: Slider(
                  value: provider.currentSpeed.toDouble(),
                  min: 0,
                  max: 255,
                  divisions: 51, // 5'er 5'er artacak şekilde
                  label: provider.currentSpeed.toString(),
                  onChanged:
                      provider.isConnected
                          ? (value) {
                            provider.updateSpeed(value.toInt());
                          }
                          : null,
                  onChangeEnd: (value) async {
                    if (!_speedChangeInProgress && provider.isConnected) {
                      _speedChangeInProgress = true;
                      await provider.sendSpeedCommand(value.toInt());
                      _speedChangeInProgress = false;
                    }
                  },
                ),
              ),
              const Text(
                '255',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          Text(
            '${((provider.currentSpeed / 255) * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionControls(BluetoothProvider provider) {
    final settingsProvider = context.watch<SettingsProvider>();
    final vibrationEnabled = settingsProvider.vibrationEnabled;
    final btnSize = settingsProvider.buttonSize;
    final btnSpacing = settingsProvider.buttonSpacing;
    final btnRadius = settingsProvider.buttonRadius;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // İleri
        DirectionButton(
          command: RobotCommand.forward,
          icon: Icons.arrow_upward,
          label: 'İleri',
          onPressed: (cmd) => provider.sendRobotCommand(cmd),
          onReleased: () => provider.sendRobotCommand(RobotCommand.stop),
          enableVibration: vibrationEnabled,
          size: btnSize,
          borderRadius: btnRadius,
        ),
        SizedBox(height: btnSpacing),
        // Sol, Dur, Sağ
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DirectionButton(
              command: RobotCommand.left,
              icon: Icons.arrow_back,
              label: 'Sol',
              onPressed: (cmd) => provider.sendRobotCommand(cmd),
              onReleased: () => provider.sendRobotCommand(RobotCommand.stop),
              enableVibration: vibrationEnabled,
              size: btnSize,
              borderRadius: btnRadius,
            ),
            SizedBox(width: btnSpacing + 12),
            DirectionButton(
              command: RobotCommand.right,
              icon: Icons.arrow_forward,
              label: 'Sağ',
              onPressed: (cmd) => provider.sendRobotCommand(cmd),
              onReleased: () => provider.sendRobotCommand(RobotCommand.stop),
              enableVibration: vibrationEnabled,
              size: btnSize,
              borderRadius: btnRadius,
            ),
          ],
        ),
        SizedBox(height: btnSpacing),
        // Geri
        DirectionButton(
          command: RobotCommand.backward,
          icon: Icons.arrow_downward,
          label: 'Geri',
          onPressed: (cmd) => provider.sendRobotCommand(cmd),
          onReleased: () => provider.sendRobotCommand(RobotCommand.stop),
          enableVibration: vibrationEnabled,
          size: btnSize,
          borderRadius: btnRadius,
        ),
      ],
    );
  }

  Widget _buildStopButton(BluetoothProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        width: double.infinity,
        height: 45,
        child: ElevatedButton(
          onPressed:
              provider.isConnected
                  ? () => provider.sendRobotCommand(RobotCommand.stop)
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.stop_circle, size: 20),
              SizedBox(width: 4),
              Text(
                'DUR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDisconnectDialog() {
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Bağlantıyı Kes'),
            content: const Text(
              'Robot ile bağlantıyı kesmek ve tarama ekranına dönmek istiyor musunuz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Bağlantıyı Kes',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
