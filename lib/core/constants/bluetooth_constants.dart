/// Bluetooth ile ilgili sabitler
class BluetoothConstants {
  BluetoothConstants._(); // Private constructor

  // BLE UUID'leri (HM-10 default değerleri)
  static const String bleServiceUuid = '0000ffe0-0000-1000-8000-00805f9b34fb';
  static const String bleCharacteristicUuid =
      '0000ffe1-0000-1000-8000-00805f9b34fb';

  // Timeout süreleri (milisaniye)
  static const int scanTimeout = 10000; // 10 saniye tarama
  static const int connectionTimeout = 15000; // 15 saniye bağlantı
  static const int commandRetryCount = 3; // Başarısız komutları 3 kez dene

  // Cihaz isim filtreleri (opsiyonel)
  static const List<String> classicDeviceKeywords = [
    'HC-05',
    'HC-06',
    'BT',
    'Arduino',
  ];

  static const List<String> bleDeviceKeywords = [
    'HM-10',
    'HM-11',
    'HC-08',
    'HC-09',
    'ESP32',
    'BLE',
  ];

  // Bağlantı geçmişi
  static const String connectionHistoryKey = 'bluetooth_connection_history';
  static const int maxHistoryItems = 10; // En fazla 10 cihaz sakla
}
