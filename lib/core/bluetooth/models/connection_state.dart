/// Bluetooth bağlantı durumu
enum ConnectionState {
  disconnected, // Bağlantı yok
  connecting, // Bağlanıyor
  connected, // Bağlı
  error, // Hata oluştu
}

extension ConnectionStateExtension on ConnectionState {
  /// Kullanıcı dostu metin
  String get displayText {
    switch (this) {
      case ConnectionState.disconnected:
        return 'Bağlantı Kesildi';
      case ConnectionState.connecting:
        return 'Bağlanıyor...';
      case ConnectionState.connected:
        return 'Bağlı';
      case ConnectionState.error:
        return 'Hata';
    }
  }

  /// Durum rengi
  bool get isConnected => this == ConnectionState.connected;
  bool get isConnecting => this == ConnectionState.connecting;
  bool get hasError => this == ConnectionState.error;
}
