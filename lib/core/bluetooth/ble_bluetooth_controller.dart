import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/bluetooth_controller.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/bluetooth_device_model.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/connection_state.dart'
    as app_state;
import 'package:bt_kontrol_robomer/core/bluetooth/models/robot_command.dart';
import 'package:bt_kontrol_robomer/core/constants/bluetooth_constants.dart';

/// BLE Bluetooth implementasyonu
class BleBluetoothController implements BluetoothController {
  BluetoothDevice? _connectedBleDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  bool _useWriteWithoutResponse = false;
  bool _isBleConnected = false;

  // "Latest command wins" write guard
  // flutter_blue_plus write()'ları kendi iç kuyruğuna aldığından,
  // in-flight iken gelen komutları kuyruğa değil _nextCommand'e yaz
  bool _isSending = false;
  RobotCommand? _nextCommand; // Gönderim devam ederken gelen en son komut

  final _devicesController =
      StreamController<List<BluetoothDeviceModel>>.broadcast();
  final _connectionStateController =
      StreamController<app_state.ConnectionState>.broadcast();

  app_state.ConnectionState _currentState =
      app_state.ConnectionState.disconnected;
  BluetoothDeviceModel? _connectedDevice;

  final List<BluetoothDeviceModel> _discoveredDevices = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  @override
  Stream<List<BluetoothDeviceModel>> get devicesStream =>
      _devicesController.stream;

  @override
  Stream<app_state.ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  app_state.ConnectionState get currentConnectionState => _currentState;

  @override
  BluetoothDeviceModel? get connectedDevice => _connectedDevice;

  @override
  Future<void> startScan() async {
    try {
      _discoveredDevices.clear();

      // Önce BLE'nin açık olduğundan emin ol
      final isOn = await FlutterBluePlus.isOn;
      if (!isOn) {
        return;
      }

      // Mevcut tarama varsa durdur
      await FlutterBluePlus.stopScan();

      // Yeni tarama başlat
      await FlutterBluePlus.startScan(
        timeout: Duration(milliseconds: BluetoothConstants.scanTimeout),
      );

      // Tarama sonuçlarını dinle
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          final name = result.device.platformName;
          if (name.isNotEmpty) {
            final newDevice = BluetoothDeviceModel(
              name: name,
              address: result.device.remoteId.toString(),
              type: BluetoothDeviceType.ble,
              rssi: result.rssi,
            );

            // Duplicate kontrolü
            if (!_discoveredDevices.any(
              (d) => d.address == newDevice.address,
            )) {
              _discoveredDevices.add(newDevice);
              _devicesController.add(List.from(_discoveredDevices));
            }
          }
        }
      });
    } catch (e) {
      // Tarama hatası sessizce işlenir
    }
  }

  @override
  Future<void> stopScan() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await FlutterBluePlus.stopScan();
  }

  @override
  Future<bool> connect(BluetoothDeviceModel device) async {
    try {
      _updateConnectionState(app_state.ConnectionState.connecting);

      // Eğer zaten bir bağlantı varsa ve farklı bir cihazsa, önce onu kes
      if (_connectedBleDevice != null &&
          _connectedBleDevice!.remoteId.toString() != device.address) {
        await disconnect();
        // Disconnect sonrası kısa bir bekleme
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Cihazı bul - önce scan sonuçlarından
      BluetoothDevice? targetDevice;
      final scanResults = FlutterBluePlus.lastScanResults;
      for (var result in scanResults) {
        if (result.device.remoteId.toString() == device.address) {
          targetDevice = result.device;
          break;
        }
      }

      // Scan sonuçlarında yoksa, bağlı cihazlardan kontrol et
      if (targetDevice == null) {
        final List<BluetoothDevice> connectedDevices =
            FlutterBluePlus.connectedDevices;
        for (var dev in connectedDevices) {
          if (dev.remoteId.toString() == device.address) {
            targetDevice = dev;
            break;
          }
        }
      }

      if (targetDevice == null) {
        _updateConnectionState(app_state.ConnectionState.error);
        return false;
      }

      _connectedBleDevice = targetDevice;

      // Bağlantı durumu değişikliklerini dinle
      _connectionSubscription = _connectedBleDevice!.connectionState.listen((
        state,
      ) {
        _isBleConnected = (state == BluetoothConnectionState.connected);
        if (state == BluetoothConnectionState.disconnected &&
            _currentState == app_state.ConnectionState.connected) {
          _updateConnectionState(app_state.ConnectionState.disconnected);
        }
      });

      // Bağlan
      await _connectedBleDevice!.connect(
        timeout: Duration(milliseconds: 35000),
        autoConnect: false,
      );

      // Bağlantı stabilitesi için kısa bekleme
      await Future.delayed(const Duration(milliseconds: 400));

      // Connection priority HIGH yap (düşük latency)
      try {
        await _connectedBleDevice!.requestConnectionPriority(
          connectionPriorityRequest: ConnectionPriority.high,
        );
        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e) {
        // Priority ayarlama hatası sessizce işlenir
      }

      // Service discovery
      List<BluetoothService> services =
          await _connectedBleDevice!.discoverServices();

      // Karakteristikleri bul
      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() ==
            BluetoothConstants.bleServiceUuid.toLowerCase()) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() ==
                BluetoothConstants.bleCharacteristicUuid.toLowerCase()) {
              _writeCharacteristic = characteristic;
              break;
            }
          }
        }
      }

      if (_writeCharacteristic == null) {
        // Varsayılan yazılabilir karakteristik ara
        for (BluetoothService service in services) {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.properties.write ||
                characteristic.properties.writeWithoutResponse) {
              _writeCharacteristic = characteristic;
              break;
            }
          }
          if (_writeCharacteristic != null) break;
        }
      }

      if (_writeCharacteristic != null) {
        _connectedDevice = device;
        _isBleConnected = true;
        _updateConnectionState(app_state.ConnectionState.connected);

        // writeWithoutResponse destekleniyorsa zorla kullan
        // (ATT ack beklenmez → gecikme sıfıra düşer)
        _useWriteWithoutResponse =
            _writeCharacteristic!.properties.writeWithoutResponse;

        // MTU negotiate et (Android default 23 byte, daha büyük yazmalar için)
        try {
          await _connectedBleDevice!.requestMtu(128);
        } catch (_) {}

        return true;
      } else {
        await disconnect();
        _updateConnectionState(app_state.ConnectionState.error);
        return false;
      }
    } catch (e) {
      _updateConnectionState(app_state.ConnectionState.error);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _isBleConnected = false;
    _isSending = false;
    _nextCommand = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    if (_connectedBleDevice != null) {
      try {
        await _connectedBleDevice!.disconnect();
      } catch (e) {
        // Disconnect hatası sessizce işlenir
      }
      _connectedBleDevice = null;
    }

    _writeCharacteristic = null;
    _connectedDevice = null;
    _updateConnectionState(app_state.ConnectionState.disconnected);
  }

  @override
  Future<bool> sendCommand(RobotCommand command) async {
    if (_writeCharacteristic == null || !_isBleConnected) return false;

    if (_isSending) {
      // Gönderim devam ediyor: en son komutu kaydet (eskiyi at)
      // STOP her zaman override eder
      if (command == RobotCommand.stop ||
          _nextCommand == null ||
          _nextCommand != RobotCommand.stop) {
        _nextCommand = command;
      }
      return true;
    }

    _isSending = true;
    try {
      await _writeCharacteristic!.write(
        utf8.encode(command.value),
        withoutResponse: _useWriteWithoutResponse,
      );

      // Gönderim tamamlandı: bekleyen komut var mı?
      while (_nextCommand != null && _isBleConnected) {
        final next = _nextCommand!;
        _nextCommand = null;
        await _writeCharacteristic!.write(
          utf8.encode(next.value),
          withoutResponse: _useWriteWithoutResponse,
        );
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      _isSending = false;
      _nextCommand = null;
    }
  }

  @override
  Future<bool> sendSpeedCommand(SpeedCommand speedCommand) async {
    if (_writeCharacteristic == null || !_isBleConnected) return false;

    // Hız komutu: gönderim devam ediyorsa beklemeden dön (tek baytlık değil, önemli)
    if (_isSending) return false;

    _isSending = true;
    try {
      await _writeCharacteristic!.write(
        utf8.encode(speedCommand.toCommandString()),
        withoutResponse: _useWriteWithoutResponse,
      );
      return true;
    } catch (e) {
      return false;
    } finally {
      _isSending = false;
    }
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    try {
      return await FlutterBluePlus.isOn;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> enableBluetooth() async {
    try {
      if (await FlutterBluePlus.isSupported) {
        await FlutterBluePlus.turnOn();
      }
    } catch (e) {
      // Açma hatası sessizce işlenir
    }
  }

  @override
  void dispose() {
    stopScan();
    disconnect();
    _devicesController.close();
    _connectionStateController.close();
  }

  void _updateConnectionState(app_state.ConnectionState newState) {
    _currentState = newState;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(newState);
    }
  }
}
