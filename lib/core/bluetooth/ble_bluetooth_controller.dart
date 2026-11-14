import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/bluetooth_controller.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/bluetooth_device_model.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/connection_state.dart'
    as app_state;
import 'package:bt_kontrol_robomer/core/bluetooth/models/robot_command.dart';
import 'package:bt_kontrol_robomer/core/constants/bluetooth_constants.dart';
import 'package:bt_kontrol_robomer/services/log_service.dart';

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
  SpeedCommand? _nextSpeed; // Gönderim devam ederken gelen en son hız

  // Her connect/disconnect'te artar; gecikmeli işler (ör. 2 sn sonra
  // connection priority tekrar isteği) eski bağlantıya uygulanmasın diye.
  int _connectionGeneration = 0;

  // Robottan gelen veri (FFE1 notify)
  final _incomingController = StreamController<List<int>>.broadcast();
  StreamSubscription<List<int>>? _notifySubscription;

  // sendRawString için ayrı guard
  bool _isRawSending = false;
  String? _nextRawData;

  // Klon modül uyumu: write without response zorla
  bool _writeWithoutResponseForced = false;

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
  Stream<List<int>> get incomingDataStream => _incomingController.stream;

  @override
  app_state.ConnectionState get currentConnectionState => _currentState;

  @override
  BluetoothDeviceModel? get connectedDevice => _connectedDevice;

  @override
  Future<void> startScan() async {
    try {
      _discoveredDevices.clear();

      // Eski subscription'ı iptal et — yeni taramada çift işlem yaşanmasın
      await _scanSubscription?.cancel();
      _scanSubscription = null;

      // Önce BLE'nin açık olduğundan emin ol
      final isOn = await FlutterBluePlus.isOn;
      if (!isOn) {
        return;
      }

      // Halihazırda sistem seviyesinde bağlı BLE cihazları ekle
      // (bunlar scan sonuçlarında çıkmaz)
      final alreadyConnected = FlutterBluePlus.connectedDevices;
      for (final device in alreadyConnected) {
        final name =
            device.platformName.isNotEmpty
                ? device.platformName
                : device.remoteId.toString();
        _discoveredDevices.add(
          BluetoothDeviceModel(
            name: name,
            address: device.remoteId.toString(),
            type: BluetoothDeviceType.ble,
          ),
        );
      }
      if (_discoveredDevices.isNotEmpty) {
        _devicesController.add(List.from(_discoveredDevices));
      }

      // Mevcut tarama varsa durdur
      await FlutterBluePlus.stopScan();

      // Yeni tarama başlat
      await FlutterBluePlus.startScan(
        timeout: Duration(milliseconds: BluetoothConstants.scanTimeout),
        androidScanMode: AndroidScanMode.lowLatency,
      );

      // Tarama sonuçlarını dinle
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        bool changed = false;
        for (ScanResult result in results) {
          // platformName boşsa advertisementData'daki advName'e bak
          final name =
              result.device.platformName.isNotEmpty
                  ? result.device.platformName
                  : result.advertisementData.advName;

          if (name.isEmpty) continue;

          final address = result.device.remoteId.toString();
          final existingIndex = _discoveredDevices.indexWhere(
            (d) => d.address == address,
          );

          if (existingIndex == -1) {
            // Yeni cihaz — ekle
            _discoveredDevices.add(
              BluetoothDeviceModel(
                name: name,
                address: address,
                type: BluetoothDeviceType.ble,
                rssi: result.rssi,
              ),
            );
            changed = true;
          } else {
            // Mevcut cihaz — RSSI güncellenmiş mi kontrol et
            final existing = _discoveredDevices[existingIndex];
            if (existing.rssi != result.rssi) {
              _discoveredDevices[existingIndex] = BluetoothDeviceModel(
                name: existing.name,
                address: existing.address,
                type: BluetoothDeviceType.ble,
                rssi: result.rssi,
              );
              changed = true;
            }
          }
        }
        if (changed) {
          _devicesController.add(List.from(_discoveredDevices));
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
      final generation = ++_connectionGeneration;

      // Bağlantı durumu değişikliklerini dinle
      await _connectionSubscription?.cancel();
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

      // Connection priority HIGH yap (düşük latency) — service discovery'yi
      // de hızlandırır. Discovery/MTU sonrası ve ~2 sn sonra tekrar istenir.
      await _requestHighPriority(generation, 'bağlantı sonrası');
      await Future.delayed(const Duration(milliseconds: 300));

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
        // writeWithoutResponse destekleniyorsa zorla kullan
        // (ATT ack beklenmez → gecikme sıfıra düşer)
        _useWriteWithoutResponse =
            _writeCharacteristic!.properties.writeWithoutResponse;

        // MTU negotiate et (Android default 23 byte, daha büyük yazmalar için)
        try {
          await _connectedBleDevice!.requestMtu(128);
        } catch (e) {
          LogService.instance.warn('BLE', 'MTU isteği başarısız: $e');
        }

        // Discovery + MTU sonrası priority'yi tekrar iste: bazı modüller
        // bu aşamada kendi (uzun) connection interval'larını dayatıyor.
        await _requestHighPriority(generation, 'discovery+MTU sonrası');

        // Notify/indicate destekleniyorsa robottan gelen veriyi dinle
        await _enableNotifications(_writeCharacteristic!);

        _connectedDevice = device;
        _isBleConnected = true;
        _updateConnectionState(app_state.ConnectionState.connected);

        // Peripheral'lar genelde bağlantıdan birkaç sn sonra kendi
        // connection-parameter update isteğini gönderir → ~2 sn sonra
        // HIGH priority'yi bir kez daha iste (connect() dönüşünü bloklamaz).
        unawaited(
          Future<void>.delayed(
            const Duration(seconds: 2),
          ).then((_) => _requestHighPriority(generation, '2 sn sonra')),
        );

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

  /// HIGH connection priority iste. [generation] eski bir bağlantıya aitse
  /// veya cihaz bu arada koptuysa hiçbir şey yapmaz.
  Future<void> _requestHighPriority(int generation, String stage) async {
    final dev = _connectedBleDevice;
    if (dev == null ||
        generation != _connectionGeneration ||
        !dev.isConnected) {
      return;
    }
    try {
      await dev.requestConnectionPriority(
        connectionPriorityRequest: ConnectionPriority.high,
      );
      LogService.instance.info(
        'BLE',
        'ConnectionPriority.high istendi ($stage)',
      );
    } catch (e) {
      LogService.instance.warn(
        'BLE',
        'ConnectionPriority.high isteği başarısız ($stage): $e',
      );
    }
  }

  /// Karakteristik notify/indicate destekliyorsa aboneliği aç ve gelen
  /// veriyi [incomingDataStream]'e aktar.
  Future<void> _enableNotifications(BluetoothCharacteristic c) async {
    await _notifySubscription?.cancel();
    _notifySubscription = null;
    if (!c.properties.notify && !c.properties.indicate) {
      LogService.instance.warn(
        'BLE',
        'Karakteristik notify/indicate desteklemiyor — robottan veri alınamaz',
      );
      return;
    }
    try {
      _notifySubscription = c.onValueReceived.listen((value) {
        if (!_incomingController.isClosed) _incomingController.add(value);
      });
      await c.setNotifyValue(true);
      LogService.instance.info('BLE', 'Notify aboneliği açıldı (${c.uuid})');
    } catch (e) {
      LogService.instance.warn('BLE', 'Notify aboneliği açılamadı: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    _connectionGeneration++;
    _isBleConnected = false;
    _isSending = false;
    _nextCommand = null;
    _nextSpeed = null;
    _isRawSending = false;
    _nextRawData = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    await _notifySubscription?.cancel();
    _notifySubscription = null;

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
      final wwr = _writeWithoutResponseForced || _useWriteWithoutResponse;
      await _writeCharacteristic!.write(
        utf8.encode(command.value),
        withoutResponse: wwr,
      );

      // Gönderim tamamlandı: bekleyen hız/komut var mı?
      await _flushPending(wwr);
      return true;
    } catch (e) {
      return false;
    } finally {
      _isSending = false;
      _nextCommand = null;
      _nextSpeed = null;
    }
  }

  /// _isSending sırasında biriken en son hız ve yön komutlarını gönder.
  /// Hız önce gider ki ardından gelen yön komutu yeni hızla uygulansın.
  Future<void> _flushPending(bool wwr) async {
    while ((_nextSpeed != null || _nextCommand != null) && _isBleConnected) {
      final speed = _nextSpeed;
      _nextSpeed = null;
      if (speed != null) {
        await _writeCharacteristic!.write(
          utf8.encode(speed.toCommandString()),
          withoutResponse: wwr,
        );
        continue; // arada yeni hız gelmiş olabilir; döngü tekrar kontrol eder
      }
      final next = _nextCommand!;
      _nextCommand = null;
      await _writeCharacteristic!.write(
        utf8.encode(next.value),
        withoutResponse: wwr,
      );
    }
  }

  @override
  Future<bool> sendSpeedCommand(SpeedCommand speedCommand) async {
    if (_writeCharacteristic == null || !_isBleConnected) return false;

    if (_isSending) {
      // Gönderim devam ediyor: en son hızı sakla, mevcut yazma bitince
      // gönderilir ("latest wins" — slider ara değerleri atlanır, son değer
      // kaybolmaz).
      _nextSpeed = speedCommand;
      return true;
    }

    _isSending = true;
    try {
      final wwr = _writeWithoutResponseForced || _useWriteWithoutResponse;
      await _writeCharacteristic!.write(
        utf8.encode(speedCommand.toCommandString()),
        withoutResponse: wwr,
      );
      await _flushPending(wwr);
      return true;
    } catch (e) {
      return false;
    } finally {
      _isSending = false;
      _nextCommand = null;
      _nextSpeed = null;
    }
  }

  @override
  Future<bool> sendRawString(String data) async {
    if (_writeCharacteristic == null || !_isBleConnected) return false;
    if (_isRawSending) {
      _nextRawData = data;
      return true;
    }
    _isRawSending = true;
    try {
      final wwr = _writeWithoutResponseForced || _useWriteWithoutResponse;
      await _writeCharacteristic!.write(
        utf8.encode(data),
        withoutResponse: wwr,
      );
      while (_nextRawData != null && _isBleConnected) {
        final next = _nextRawData!;
        _nextRawData = null;
        await _writeCharacteristic!.write(
          utf8.encode(next),
          withoutResponse: wwr,
        );
      }
      return true;
    } catch (e) {
      return false;
    } finally {
      _isRawSending = false;
      _nextRawData = null;
    }
  }

  @override
  void setWriteWithoutResponseOverride(bool forced) {
    _writeWithoutResponseForced = forced;
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
    _incomingController.close();
  }

  void _updateConnectionState(app_state.ConnectionState newState) {
    _currentState = newState;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(newState);
    }
  }
}
