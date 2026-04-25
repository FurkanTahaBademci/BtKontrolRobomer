import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/bluetooth_controller.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/classic_bluetooth_controller.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/ble_bluetooth_controller.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/bluetooth_device_model.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/connection_state.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/robot_command.dart';
import 'package:bt_kontrol_robomer/core/constants/bluetooth_constants.dart';
import 'package:bt_kontrol_robomer/core/permissions/bluetooth_permission_handler.dart';
import 'package:bt_kontrol_robomer/services/log_service.dart';

/// Bluetooth işlemlerini yöneten Provider
class BluetoothProvider with ChangeNotifier {
  BluetoothController? _controller;
  BluetoothDeviceType _currentType = BluetoothDeviceType.classic;

  List<BluetoothDeviceModel> _devices = [];
  ConnectionState _connectionState = ConnectionState.disconnected;
  BluetoothDeviceModel? _connectedDevice;

  int _currentSpeed = 150; // Varsayılan PWM hızı (0-255)
  bool _isScanning = false;
  String? _errorMessage;

  // Gecikme optimizasyonu (SettingsProvider'dan ProxyProvider aracılığıyla beslenir)
  String _commandTerminator = '';
  bool _bleForceWriteWithoutResponse = false;

  // İstatistikler
  int _cmdSent = 0;
  int _cmdFailed = 0;
  int _scanCount = 0;
  int _connectCount = 0;
  int _disconnectCount = 0;
  DateTime? _connectedAt;

  // Gecikme / Hız testi
  bool _isLatencyTesting = false;
  bool _isBurstTesting = false;
  List<int> _latencyResults = [];
  int _burstCommandsPerSec = 0;
  String? _latencyTestError;

  // Getters — istatistikler
  int get cmdSent => _cmdSent;
  int get cmdFailed => _cmdFailed;
  int get scanCount => _scanCount;
  int get connectCount => _connectCount;
  int get disconnectCount => _disconnectCount;
  DateTime? get connectedAt => _connectedAt;

  // Getters — test
  bool get isLatencyTesting => _isLatencyTesting;
  bool get isBurstTesting => _isBurstTesting;
  List<int> get latencyResults => List.unmodifiable(_latencyResults);
  int get burstCommandsPerSec => _burstCommandsPerSec;
  String? get latencyTestError => _latencyTestError;

  StreamSubscription<List<BluetoothDeviceModel>>? _devicesSubscription;
  StreamSubscription<ConnectionState>? _connectionSubscription;

  // Getters
  List<BluetoothDeviceModel> get devices => _devices;
  ConnectionState get connectionState => _connectionState;
  BluetoothDeviceModel? get connectedDevice => _connectedDevice;
  int get currentSpeed => _currentSpeed;
  bool get isScanning => _isScanning;
  bool get isConnected => _connectionState == ConnectionState.connected;
  String? get errorMessage => _errorMessage;
  BluetoothDeviceType get currentType => _currentType;

  /// Bluetooth tipini değiştir (Classic veya BLE)
  void setBluetoothType(BluetoothDeviceType type) {
    if (_currentType != type) {
      LogService.instance.info(
        'BT',
        'Tip değiştirildi: ${type.name.toUpperCase()}',
      );
      _disposeController();

      _currentType = type;
      _devices.clear();
      _errorMessage = null;

      // Yeni controller oluştur
      _initializeController();

      notifyListeners();
    }
  }

  /// Controller'ı başlat
  void _initializeController() {
    if (_currentType == BluetoothDeviceType.classic) {
      _controller = ClassicBluetoothController();
    } else {
      _controller = BleBluetoothController();
    }

    // Stream'leri dinle
    _devicesSubscription = _controller!.devicesStream.listen((deviceList) {
      _devices = deviceList;
      notifyListeners();
    });

    _connectionSubscription = _controller!.connectionStateStream.listen((
      state,
    ) {
      _connectionState = state;
      _connectedDevice = _controller!.connectedDevice;

      if (state == ConnectionState.error) {
        _errorMessage = 'Bağlantı hatası oluştu';
        LogService.instance.error(
          'BT',
          'Bağlantı hatası: ${_connectedDevice?.name ?? "?"}',
        );
      } else if (state == ConnectionState.disconnected) {
        LogService.instance.warn(
          'BT',
          'Bağlantı kesildi: ${_connectedDevice?.name ?? "?"}',
        );
        _connectedDevice = null;
      } else if (state == ConnectionState.connected) {
        // Bağlantı kurulunca mevcut optimizasyon ayarlarını uygula
        _controller?.setWriteWithoutResponseOverride(_bleForceWriteWithoutResponse);
        LogService.instance.success(
          'BT',
          'Bağlandı: ${_connectedDevice?.name ?? "?"}',
        );
      }

      notifyListeners();
    });
  }

  /// İzinleri kontrol et ve gerekirse iste
  Future<bool> checkAndRequestPermissions() async {
    try {
      bool hasPermissions =
          await BluetoothPermissionHandler.checkBluetoothPermissions();

      if (!hasPermissions) {
        hasPermissions =
            await BluetoothPermissionHandler.requestBluetoothPermissions();
      }

      if (!hasPermissions) {
        _errorMessage = 'Bluetooth izinleri gerekli';
        LogService.instance.error('Permission', 'Bluetooth izni reddedildi');
        notifyListeners();
      }

      return hasPermissions;
    } catch (e) {
      _errorMessage = 'İzin kontrolü hatası: $e';
      notifyListeners();
      return false;
    }
  }

  /// Cihaz taramayı başlat
  Future<void> startScan() async {
    try {
      _errorMessage = null;

      // İzinleri kontrol et
      final hasPermissions = await checkAndRequestPermissions();
      if (!hasPermissions) {
        return;
      }

      // Controller yoksa oluştur
      if (_controller == null) {
        _initializeController();
      }

      // Bluetooth açık mı kontrol et
      final isEnabled = await _controller!.isBluetoothEnabled();
      if (!isEnabled) {
        _errorMessage = 'Bluetooth kapalı';
        LogService.instance.warn('BT', 'Bluetooth kapalı, açılıyor...');
        notifyListeners();
        await _controller!.enableBluetooth();
        return;
      }

      // BLE tarama için konum servisinin açık olması gerekli
      if (_currentType == BluetoothDeviceType.ble) {
        final locationEnabled =
            await BluetoothPermissionHandler.isLocationServiceEnabled();
        if (!locationEnabled) {
          _errorMessage =
              'BLE tarama için konum servisi açık olmalıdır. Lütfen konum servisini açın.';
          LogService.instance.warn(
            'BLE',
            'Konum servisi kapalı, tarama başlatılamıyor',
          );
          notifyListeners();
          return;
        }
      }

      _isScanning = true;
      _devices.clear();
      _scanCount++;
      LogService.instance.info(
        'BT',
        '${_currentType.name.toUpperCase()} tarama başlatıldı (toplam: $_scanCount)',
      );
      notifyListeners();

      await _controller!.startScan();

      // Tarama timeout sonrası isScanning bayrağını sıfırla
      // (controller timeout dolunca provider'a bildirim yapmaz)
      Future.delayed(
        Duration(milliseconds: BluetoothConstants.scanTimeout + 500),
        () {
          if (_isScanning) {
            _isScanning = false;
            LogService.instance.info(
              'BT',
              'Tarama tamamlandı — ${_devices.length} cihaz bulundu',
            );
            notifyListeners();
          }
        },
      );
    } catch (e) {
      _errorMessage = 'Tarama hatası: $e';
      _isScanning = false;
      LogService.instance.error('BT', 'Tarama hatası: $e');
      notifyListeners();
    }
  }

  /// Taramayı durdur
  Future<void> stopScan() async {
    _isScanning = false;
    LogService.instance.info('BT', 'Tarama durduruldu');
    await _controller?.stopScan();
    notifyListeners();
  }

  /// Cihaza bağlan
  Future<bool> connectToDevice(BluetoothDeviceModel device) async {
    try {
      _errorMessage = null;
      notifyListeners();

      if (_controller == null) {
        _initializeController();
      }

      await stopScan();

      LogService.instance.info(
        'BT',
        'Bağlanılıyor: ${device.name} [${device.address}]',
      );
      final success = await _controller!.connect(device);

      if (!success) {
        if (_currentType == BluetoothDeviceType.classic) {
          _errorMessage =
              'Bağlantı başarısız. Cihazın açık ve menzilde olduğundan, '
              'telefon ayarlarından eşleştirildiğinden emin olun.';
        } else {
          _errorMessage =
              'BLE bağlantısı başarısız. Cihazın açık ve yakın olduğundan emin olun. '
              'Gerekirse cihazı kapatıp tekrar açın.';
        }
        LogService.instance.error(
          'BT',
          'Bağlantı başarısız: ${device.name} — $_errorMessage',
        );
        notifyListeners();
      } else {
        _connectCount++;
        _connectedAt = DateTime.now();
      }

      return success;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('timeout') || msg.contains('Timeout')) {
        _errorMessage =
            'Bağlantı zaman aşımı. Cihaz menzil dışında veya meşgul olabilir.';
      } else if (msg.contains('permission') || msg.contains('Permission')) {
        _errorMessage =
            'Bluetooth izni reddedildi. Uygulama ayarlarını kontrol edin.';
      } else {
        _errorMessage = 'Bağlantı hatası: $msg';
      }
      LogService.instance.error('BT', 'Bağlantı exception: $msg');
      notifyListeners();
      return false;
    }
  }

  /// Bağlantıyı kes
  Future<void> disconnect() async {
    try {
      LogService.instance.info(
        'BT',
        'Bağlantı kesiliyor: ${_connectedDevice?.name ?? "?"}',
      );
      _disconnectCount++;
      _connectedAt = null;
      await _controller?.disconnect();
      _connectedDevice = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Bağlantı kesme hatası: $e';
      LogService.instance.error('BT', 'Bağlantı kesme hatası: $e');
      notifyListeners();
    }
  }

  /// Gecikme optimizasyon ayarlarını güncelle (ChangeNotifierProxyProvider tarafından çağrılır)
  void applyLatencySettings({
    required String terminator,
    required bool bleForceWriteWithoutResponse,
  }) {
    _commandTerminator = terminator;
    if (_bleForceWriteWithoutResponse != bleForceWriteWithoutResponse) {
      _bleForceWriteWithoutResponse = bleForceWriteWithoutResponse;
      _controller?.setWriteWithoutResponseOverride(bleForceWriteWithoutResponse);
    }
  }

  /// Robot komut gönder
  Future<bool> sendRobotCommand(RobotCommand command) async {
    if (_controller == null || !isConnected) {
      return false;
    }
    final bool result;
    if (_commandTerminator.isEmpty) {
      // Normal yol: en-iyi gecikme guard'lı sendCommand
      result = await _controller!.sendCommand(command);
    } else {
      // Sonlandırıcı varsa: ham string olarak gönder (guard sendRawString'de)
      result = await _controller!.sendRawString(command.value + _commandTerminator);
    }
    if (result) {
      _cmdSent++;
    } else {
      _cmdFailed++;
    }
    return result;
  }

  /// Ham string gönder (özel bloklar için)
  Future<bool> sendRawString(String data) async {
    if (_controller == null || !isConnected) return false;
    final result = await _controller!.sendRawString(data + _commandTerminator);
    if (result) {
      _cmdSent++;
    } else {
      _cmdFailed++;
    }
    return result;
  }

  /// Hız komut gönder
  Future<bool> sendSpeedCommand(int speed) async {
    if (speed < 0 || speed > 255) return false;

    _currentSpeed = speed;
    notifyListeners();

    if (_controller == null || !isConnected) {
      return false;
    }

    try {
      final speedCmd = SpeedCommand(speed);
      return await _controller!.sendSpeedCommand(speedCmd);
    } catch (e) {
      _errorMessage = 'Hız komutu hatası: $e';
      notifyListeners();
      return false;
    }
  }

  /// Gecikme testi — N adet 'S' komutu göndererek BT yazma gecikmesini ölçer
  Future<void> runLatencyTest({int samples = 20}) async {
    if (!isConnected || _controller == null) {
      _latencyTestError = 'Test için bağlı cihaz gerekli';
      notifyListeners();
      return;
    }
    _isLatencyTesting = true;
    _latencyResults = [];
    _latencyTestError = null;
    LogService.instance.info(
      'TEST',
      'Gecikme testi başlatıldı ($samples örnek)',
    );
    notifyListeners();
    try {
      for (int i = 0; i < samples; i++) {
        if (!isConnected) break;
        final sw = Stopwatch()..start();
        await _controller!.sendCommand(RobotCommand.stop);
        sw.stop();
        _latencyResults = List.from(_latencyResults)
          ..add(sw.elapsedMilliseconds);
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 60));
      }
      if (_latencyResults.isNotEmpty) {
        final avg =
            _latencyResults.reduce((a, b) => a + b) / _latencyResults.length;
        final mn = _latencyResults.reduce((a, b) => a < b ? a : b);
        final mx = _latencyResults.reduce((a, b) => a > b ? a : b);
        LogService.instance.success(
          'TEST',
          'Gecikme bitti — min:${mn}ms ort:${avg.toStringAsFixed(1)}ms maks:${mx}ms',
        );
      }
    } catch (e) {
      _latencyTestError = 'Hata: $e';
      LogService.instance.error('TEST', 'Gecikme testi hatası: $e');
    } finally {
      _isLatencyTesting = false;
      notifyListeners();
    }
  }

  /// Burst testi — 30 komutu arka arkaya göndererek cmd/s değerini ölçer
  Future<void> runBurstTest({int count = 30}) async {
    if (!isConnected || _controller == null) {
      _latencyTestError = 'Test için bağlı cihaz gerekli';
      notifyListeners();
      return;
    }
    _isBurstTesting = true;
    _burstCommandsPerSec = 0;
    _latencyTestError = null;
    LogService.instance.info('TEST', 'Burst testi başlatıldı ($count komut)');
    notifyListeners();
    try {
      final sw = Stopwatch()..start();
      int sent = 0;
      for (int i = 0; i < count; i++) {
        if (!isConnected) break;
        final ok = await _controller!.sendCommand(RobotCommand.stop);
        if (ok) sent++;
      }
      sw.stop();
      final secs = sw.elapsedMilliseconds / 1000.0;
      _burstCommandsPerSec = secs > 0 ? (sent / secs).round() : 0;
      LogService.instance.success(
        'TEST',
        'Burst bitti — $sent/$count komut, ${sw.elapsedMilliseconds}ms → $_burstCommandsPerSec cmd/s',
      );
    } catch (e) {
      _latencyTestError = 'Burst test hatası: $e';
      LogService.instance.error('TEST', 'Burst test hatası: $e');
    } finally {
      _isBurstTesting = false;
      notifyListeners();
    }
  }

  /// Test sonuçlarını sıfırla
  void clearTestResults() {
    _latencyResults = [];
    _burstCommandsPerSec = 0;
    _latencyTestError = null;
    notifyListeners();
  }

  /// Hız değerini güncelle (local)
  void updateSpeed(int speed) {
    if (speed >= 0 && speed <= 255) {
      _currentSpeed = speed;
      notifyListeners();
    }
  }

  /// Hata mesajını temizle
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Controller'ı temizle
  void _disposeController() {
    _devicesSubscription?.cancel();
    _connectionSubscription?.cancel();
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }
}
