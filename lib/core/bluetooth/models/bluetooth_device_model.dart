/// Bluetooth cihaz bilgilerini tutan model
class BluetoothDeviceModel {
  final String name;
  final String address;
  final BluetoothDeviceType type;
  final int? rssi; // Sinyal gücü (sadece BLE için)

  BluetoothDeviceModel({
    required this.name,
    required this.address,
    required this.type,
    this.rssi,
  });

  BluetoothDeviceModel copyWith({int? rssi}) {
    return BluetoothDeviceModel(
      name: name,
      address: address,
      type: type,
      rssi: rssi ?? this.rssi,
    );
  }

  @override
  String toString() =>
      'BluetoothDeviceModel(name: $name, address: $address, type: $type)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BluetoothDeviceModel && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;

  /// JSON'dan nesne oluşturma (bağlantı geçmişi için)
  factory BluetoothDeviceModel.fromJson(Map<String, dynamic> json) {
    return BluetoothDeviceModel(
      name: json['name'] as String,
      address: json['address'] as String,
      type: BluetoothDeviceType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => BluetoothDeviceType.classic,
      ),
      rssi: json['rssi'] as int?,
    );
  }

  /// Nesneyi JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'type': type.toString(),
      'rssi': rssi,
    };
  }
}

/// Bluetooth cihaz tipi
enum BluetoothDeviceType {
  classic, // HC-05, HC-06 gibi klasik Bluetooth
  ble, // BLE modülleri (HM-10, ESP32 vb.)
}
