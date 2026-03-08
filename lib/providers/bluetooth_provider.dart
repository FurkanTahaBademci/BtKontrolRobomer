import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/bluetooth_controller.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/classic_bluetooth_controller.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/ble_bluetooth_controller.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/bluetooth_device_model.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/connection_state.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/robot_command.dart';
import 'package:bt_kontrol_robomer/core/permissions/bluetooth_permission_handler.dart';

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
      // Mevcut controller'ı temizle
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
      } else if (state == ConnectionState.disconnected) {
        _connectedDevice = null;
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
        notifyListeners();
        await _controller!.enableBluetooth();
        return;
      }

      _isScanning = true;
      _devices.clear();
      notifyListeners();

      await _controller!.startScan();
    } catch (e) {
      _errorMessage = 'Tarama hatası: $e';
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Taramayı durdur
  Future<void> stopScan() async {
    _isScanning = false;
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

      final success = await _controller!.connect(device);

      if (!success) {
        _errorMessage = 'Bağlantı başarısız';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = 'Bağlantı hatası: $e';
      notifyListeners();
      return false;
    }
  }

  /// Bağlantıyı kes
  Future<void> disconnect() async {
    try {
      await _controller?.disconnect();
      _connectedDevice = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Bağlantı kesme hatası: $e';
      notifyListeners();
    }
  }

  /// Robot komut gönder
  Future<bool> sendRobotCommand(RobotCommand command) async {
    if (_controller == null || !isConnected) {
      return false;
    }

    // Hata yakalamadan direkt gönder (hız için)
    return await _controller!.sendCommand(command);
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
