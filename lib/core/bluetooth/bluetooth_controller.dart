import 'dart:async';
import 'package:bt_kontrol_robomer/core/bluetooth/models/bluetooth_device_model.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/connection_state.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/robot_command.dart';

/// Bluetooth kontrol için soyut sınıf
/// Hem Classic hem BLE implementasyonları bu interface'i implement edecek
abstract class BluetoothController {
  /// Cihaz taramayı başlat
  Future<void> startScan();

  /// Cihaz taramayı durdur
  Future<void> stopScan();

  /// Bulunan cihazlar stream'i
  Stream<List<BluetoothDeviceModel>> get devicesStream;

  /// Cihaza bağlan
  Future<bool> connect(BluetoothDeviceModel device);

  /// Bağlantıyı kes
  Future<void> disconnect();

  /// Bağlantı durumu stream'i
  Stream<ConnectionState> get connectionStateStream;

  /// Mevcut bağlantı durumu
  ConnectionState get currentConnectionState;

  /// Bağlı cihaz bilgisi
  BluetoothDeviceModel? get connectedDevice;

  /// Robot komut gönder (F, B, R, L, S)
  Future<bool> sendCommand(RobotCommand command);

  /// Hız komutu gönder (0-255)
  Future<bool> sendSpeedCommand(SpeedCommand speedCommand);

  /// Bluetooth etkin mi?
  Future<bool> isBluetoothEnabled();

  /// Bluetooth'u aç (sistem ayarlarına yönlendirir)
  Future<void> enableBluetooth();

  /// Controller'ı temizle ve kaynakları serbest bırak
  void dispose();
}
