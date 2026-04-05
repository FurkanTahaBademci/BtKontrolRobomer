import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bt_kontrol_robomer/providers/bluetooth_provider.dart';
import 'package:bt_kontrol_robomer/providers/settings_provider.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/robot_command.dart';
import 'package:bt_kontrol_robomer/widgets/direction_button.dart';
import 'package:bt_kontrol_robomer/widgets/connection_status_indicator.dart';
import 'package:bt_kontrol_robomer/screens/settings_screen.dart';

/// Robot kontrol ekranı
class RobotControlScreen extends StatefulWidget {
  const RobotControlScreen({super.key});

  @override
  State<RobotControlScreen> createState() => _RobotControlScreenState();
}

class _RobotControlScreenState extends State<RobotControlScreen> {
  @override
  void initState() {
    super.initState();

    // Varsayılan hızı ayarla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider = context.read<SettingsProvider>();
      final bluetoothProvider = context.read<BluetoothProvider>();
      bluetoothProvider.updateSpeed(settingsProvider.defaultSpeed);

      // Ekran yönlendirmesini ayarla
      _setOrientation(settingsProvider.screenOrientation);
    });
  }

  void _setOrientation(ScreenOrientation orientation) {
    switch (orientation) {
      case ScreenOrientation.portrait:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        break;
      case ScreenOrientation.landscape:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case ScreenOrientation.auto:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
    }
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
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Ayarlar',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final canvasSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              return _buildFreeLayout(bluetoothProvider, canvasSize);
            },
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
        color:
            isDevMode
                ? Theme.of(context).colorScheme.tertiaryContainer
                : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDevMode ? Icons.developer_mode : Icons.warning_amber,
            color:
                isDevMode
                    ? Theme.of(context).colorScheme.onTertiaryContainer
                    : Theme.of(context).colorScheme.error,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              isDevMode
                  ? 'Geliştirici Modu - Cihaz bağlı değil!'
                  : 'Bağlantı kesildi!',
              style: TextStyle(
                color:
                    isDevMode
                        ? Theme.of(context).colorScheme.onTertiaryContainer
                        : Theme.of(context).colorScheme.onErrorContainer,
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

  /// Serbest konumlandırmalı (Stack) ana düzen
  Widget _buildFreeLayout(BluetoothProvider provider, Size canvasSize) {
    final settings = context.watch<SettingsProvider>();
    final positions = settings.buttonPositions;
    final btnSize = settings.buttonSize;
    final btnRadius = settings.buttonRadius;
    final vibration = settings.vibrationEnabled;

    Offset toPx(int idx) => Offset(
      positions[idx].dx * canvasSize.width,
      positions[idx].dy * canvasSize.height,
    );

    return Stack(
      children: [
        // 0 - İleri
        _positionedButton(
          left: toPx(0).dx - btnSize / 2,
          top: toPx(0).dy - btnSize / 2,
          child: _directionBtn(
            provider,
            vibration,
            RobotCommand.forward,
            Icons.arrow_upward,
            'İleri',
            btnSize,
            btnRadius,
          ),
        ),
        // 1 - Geri
        _positionedButton(
          left: toPx(1).dx - btnSize / 2,
          top: toPx(1).dy - btnSize / 2,
          child: _directionBtn(
            provider,
            vibration,
            RobotCommand.backward,
            Icons.arrow_downward,
            'Geri',
            btnSize,
            btnRadius,
          ),
        ),
        // 2 - Sol
        _positionedButton(
          left: toPx(2).dx - btnSize / 2,
          top: toPx(2).dy - btnSize / 2,
          child: _directionBtn(
            provider,
            vibration,
            RobotCommand.left,
            Icons.arrow_back,
            'Sol',
            btnSize,
            btnRadius,
          ),
        ),
        // 3 - Sağ
        _positionedButton(
          left: toPx(3).dx - btnSize / 2,
          top: toPx(3).dy - btnSize / 2,
          child: _directionBtn(
            provider,
            vibration,
            RobotCommand.right,
            Icons.arrow_forward,
            'Sağ',
            btnSize,
            btnRadius,
          ),
        ),
        // 4 - DUR
        _positionedButton(
          left: toPx(4).dx - btnSize / 2,
          top: toPx(4).dy - btnSize / 2,
          child: _directionBtn(
            provider,
            vibration,
            RobotCommand.stop,
            Icons.stop_circle,
            'DUR',
            btnSize,
            btnRadius,
            color: Colors.red,
          ),
        ),
        // 6 - Korna (pozisyon listesi yeterliyse)
        if (positions.length > 6)
          _positionedButton(
            left: toPx(6).dx - btnSize / 2,
            top: toPx(6).dy - btnSize / 2,
            child: _hornBtn(provider, vibration, btnSize, btnRadius),
          ),
        // Bağlantı koptu banner (en üstte)
        if (!provider.isConnected)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildConnectionLostBanner(provider),
          ),
      ],
    );
  }

  Widget _positionedButton({
    required double left,
    required double top,
    required Widget child,
  }) {
    return Positioned(left: left, top: top, child: child);
  }

  Widget _directionBtn(
    BluetoothProvider provider,
    bool vibration,
    RobotCommand cmd,
    IconData icon,
    String label,
    double size,
    double radius, {
    Color? color,
  }) {
    return DirectionButton(
      command: cmd,
      icon: icon,
      label: label,
      onPressed: (c) => provider.sendRobotCommand(c),
      onReleased: () => provider.sendRobotCommand(RobotCommand.stop),
      enableVibration: vibration,
      size: size,
      borderRadius: radius,
      color: color,
    );
  }

  Widget _hornBtn(
    BluetoothProvider provider,
    bool vibration,
    double size,
    double radius,
  ) {
    return DirectionButton(
      command: RobotCommand.hornOn,
      icon: Icons.volume_up,
      label: 'Korna',
      onPressed: (c) => provider.sendRobotCommand(c),
      onReleased: () => provider.sendRobotCommand(RobotCommand.hornOff),
      enableVibration: vibration,
      size: size,
      borderRadius: radius,
      color: Colors.amber.shade700,
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
