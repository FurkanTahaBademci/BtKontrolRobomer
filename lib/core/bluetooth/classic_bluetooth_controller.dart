import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    hide BluetoothDeviceType;
import 'package:bt_kontrol_robomer/core/bluetooth/bluetooth_controller.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/bluetooth_device_model.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/connection_state.dart'
    as app_state;
import 'package:bt_kontrol_robomer/core/bluetooth/models/robot_command.dart';
import 'package:bt_kontrol_robomer/core/constants/bluetooth_constants.dart';

/// Classic Bluetooth (HC-05/HC-06) implementasyonu
class ClassicBluetoothController implements BluetoothController {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _dataSubscription;
  bool _isDisconnecting = false; // Reentrancy guard

  // "Latest command wins" write guard
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
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;

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

      // Önce eşlenmiş cihazları al
      final List<BluetoothDevice> bondedDevices =
          await _bluetooth.getBondedDevices();
      for (var device in bondedDevices) {
        if (device.name != null && device.name!.isNotEmpty) {
          _discoveredDevices.add(
            BluetoothDeviceModel(
              name: device.name!,
              address: device.address,
              type: BluetoothDeviceType.classic,
            ),
          );
        }
      }
      _devicesController.add(List.from(_discoveredDevices));

      // Yeni cihazları tara
      _discoverySubscription = _bluetooth.startDiscovery().listen((result) {
        if (result.device.name != null && result.device.name!.isNotEmpty) {
          final newDevice = BluetoothDeviceModel(
            name: result.device.name!,
            address: result.device.address,
            type: BluetoothDeviceType.classic,
            rssi: result.rssi,
          );

          // Duplicate kontrolü - eşlenmiş cihaz yeniden keşfedilirse rssi güncelle
          final existingIndex = _discoveredDevices.indexWhere(
            (d) => d.address == newDevice.address,
          );
          if (existingIndex >= 0) {
            _discoveredDevices[existingIndex] =
                _discoveredDevices[existingIndex].copyWith(rssi: result.rssi);
          } else {
            _discoveredDevices.add(newDevice);
          }
          _devicesController.add(List.from(_discoveredDevices));
        }
      });

      // Timeout ile taramayı durdur
      Future.delayed(
        Duration(milliseconds: BluetoothConstants.scanTimeout),
        () {
          stopScan();
        },
      );
    } catch (e) {
      // Tarama hatası sessizce işlenir
    }
  }

  @override
  Future<void> stopScan() async {
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;
    // Native Android discovery'yi de durdur (sadece subscription iptal etmek yetmez)
    try {
      await _bluetooth.cancelDiscovery();
    } catch (_) {}
  }

  @override
  Future<bool> connect(BluetoothDeviceModel device) async {
    try {
      _updateConnectionState(app_state.ConnectionState.connecting);

      // Mevcut bağlantıyı kes
      await disconnect();

      // Yeni bağlantı kur
      _connection = await BluetoothConnection.toAddress(
        device.address,
      ).timeout(Duration(milliseconds: BluetoothConstants.connectionTimeout));

      if (_connection != null && _connection!.isConnected) {
        _connectedDevice = device;
        _updateConnectionState(app_state.ConnectionState.connected);

        // Gelen verileri dinle
        _dataSubscription = _connection!.input!.listen(
          (Uint8List data) {
            // Arduino'dan gelen veri burada işlenebilir
          },
          onDone: () {
            // Bağlantı uzak taraftan kesildi—soketi kapamaya çalışma (zaten kapandı)
            if (!_isDisconnecting) {
              _isDisconnecting = true;
              _dataSubscription?.cancel();
              _dataSubscription = null;
              _connection = null;
              _isSending = false;
              _nextCommand = null;
              _connectedDevice = null;
              _updateConnectionState(app_state.ConnectionState.disconnected);
              _isDisconnecting = false;
            }
          },
          onError: (error) {
            _updateConnectionState(app_state.ConnectionState.error);
          },
        );

        return true;
      }

      _updateConnectionState(app_state.ConnectionState.error);
      return false;
    } catch (e) {
      _updateConnectionState(app_state.ConnectionState.error);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    if (_isDisconnecting) return; // Reentrancy guard
    _isDisconnecting = true;

    _isSending = false;
    _nextCommand = null;

    await _dataSubscription?.cancel();
    _dataSubscription = null;

    final conn = _connection;
    _connection = null;
    if (conn != null) {
      try {
        await conn.close().timeout(const Duration(seconds: 2));
      } catch (_) {
        // Zaten kapanmış veya timeout — sessizce geç
      }
    }

    _connectedDevice = null;
    _isDisconnecting = false;
    _updateConnectionState(app_state.ConnectionState.disconnected);
  }

  @override
  Future<bool> sendCommand(RobotCommand command) async {
    if (_connection == null || !_connection!.isConnected) return false;

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
      _connection!.output.add(utf8.encode(command.value));
      await _connection!.output.allSent;

      // Gönderim tamamlandi: bekleyen komut var mi?
      while (_nextCommand != null) {
        final next = _nextCommand!;
        _nextCommand = null;
        if (_connection == null || !_connection!.isConnected) break;
        _connection!.output.add(utf8.encode(next.value));
        await _connection!.output.allSent;
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
    if (_connection == null || !_connection!.isConnected) {
      return false;
    }

    try {
      _connection!.output.add(utf8.encode(speedCommand.toCommandString()));
      await _connection!.output.allSent;
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isBluetoothEnabled() async {
    try {
      return await _bluetooth.isEnabled ?? false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> enableBluetooth() async {
    try {
      await _bluetooth.requestEnable();
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
