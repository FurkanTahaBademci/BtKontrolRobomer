import 'package:permission_handler/permission_handler.dart';

/// Bluetooth izinlerini yöneten sınıf
class BluetoothPermissionHandler {
  /// Bluetooth izinlerini kontrol et ve gerekirse iste
  /// Android 12+ (API 31+) için yeni izinler, öncesi için eski izinler
  static Future<bool> requestBluetoothPermissions() async {
    // Android sürümüne göre farklı izinler gerekli
    Map<Permission, PermissionStatus> statuses = {};

    // Android 12+ için yeni izinler
    statuses =
        await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location, // BLE tarama için hala gerekli
        ].request();

    // Tüm izinlerin verilip verilmediğini kontrol et
    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    return allGranted;
  }

  /// Bluetooth izinlerinin durumunu kontrol et
  static Future<bool> checkBluetoothPermissions() async {
    bool scanGranted = await Permission.bluetoothScan.isGranted;
    bool connectGranted = await Permission.bluetoothConnect.isGranted;
    bool locationGranted = await Permission.location.isGranted;

    return scanGranted && connectGranted && locationGranted;
  }

  /// Location servisinin açık olup olmadığını kontrol et
  static Future<bool> isLocationServiceEnabled() async {
    return await Permission.location.serviceStatus.isEnabled;
  }

  /// Ayarlara git
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// İzin kalıcı olarak reddedilmiş mi?
  static Future<bool> isPermissionPermanentlyDenied() async {
    bool scanDenied = await Permission.bluetoothScan.isPermanentlyDenied;
    bool connectDenied = await Permission.bluetoothConnect.isPermanentlyDenied;
    bool locationDenied = await Permission.location.isPermanentlyDenied;

    return scanDenied || connectDenied || locationDenied;
  }

  /// İzin durumunu açıklayıcı mesaj ile al
  static Future<String> getPermissionStatusMessage() async {
    bool hasPermissions = await checkBluetoothPermissions();

    if (hasPermissions) {
      return 'Tüm izinler verildi';
    }

    List<String> missingPermissions = [];

    if (!await Permission.bluetoothScan.isGranted) {
      missingPermissions.add('Bluetooth Tarama');
    }
    if (!await Permission.bluetoothConnect.isGranted) {
      missingPermissions.add('Bluetooth Bağlantı');
    }
    if (!await Permission.location.isGranted) {
      missingPermissions.add('Konum');
    }

    return 'Eksik izinler: ${missingPermissions.join(", ")}';
  }
}
