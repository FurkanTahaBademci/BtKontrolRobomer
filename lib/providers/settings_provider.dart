import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama ayarlarını yöneten Provider
class SettingsProvider with ChangeNotifier {
  static const String _keyDefaultSpeed = 'default_speed';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyCommandMode = 'command_mode';

  int _defaultSpeed = 128; // 0-255, varsayılan orta hız
  bool _vibrationEnabled = true;
  CommandMode _commandMode = CommandMode.simple;
  bool _developerMode = false; // Geçici - sadece runtime, kaydetme yok

  int get defaultSpeed => _defaultSpeed;
  bool get vibrationEnabled => _vibrationEnabled;
  CommandMode get commandMode => _commandMode;
  bool get developerMode => _developerMode;

  /// Ayarları yükle
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _defaultSpeed = prefs.getInt(_keyDefaultSpeed) ?? 128;
      _vibrationEnabled = prefs.getBool(_keyVibrationEnabled) ?? true;

      final modeName = prefs.getString(_keyCommandMode) ?? 'simple';
      _commandMode = CommandMode.values.firstWhere(
        (mode) => mode.name == modeName,
        orElse: () => CommandMode.simple,
      );

      notifyListeners();
    } catch (e) {
      // Varsayılan değerler kullanılır
    }
  }

  /// Varsayılan hızı ayarla
  Future<void> setDefaultSpeed(int speed) async {
    if (speed < 0 || speed > 255) return;

    _defaultSpeed = speed;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyDefaultSpeed, speed);
    } catch (e) {
      // Kaydetme hatası sessizce işlenir
    }
  }

  /// Vibrasyon ayarını değiştir
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyVibrationEnabled, enabled);
    } catch (e) {
      // Kaydetme hatası sessizce işlenir
    }
  }

  /// Komut modunu değiştir
  Future<void> setCommandMode(CommandMode mode) async {
    _commandMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCommandMode, mode.name);
    } catch (e) {
      // Kaydetme hatası sessizce işlenir
    }
  }

  /// Tüm ayarları sıfırla
  Future<void> resetToDefaults() async {
    _defaultSpeed = 128;
    _vibrationEnabled = true;
    _commandMode = CommandMode.simple;
    _developerMode = false; // Dev modu da kapat
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDefaultSpeed);
      await prefs.remove(_keyVibrationEnabled);
      await prefs.remove(_keyCommandMode);
    } catch (e) {
      // Silme hatası sessizce işlenir
    }
  }

  /// Geliştirici modunu aç/kapat (geçici - sadece runtime)
  void setDeveloperMode(bool enabled) {
    _developerMode = enabled;
    notifyListeners();
  }
}

/// Komut modu seçenekleri
enum CommandMode {
  simple, // F/B/R/L/S (mevcut sistem)
  advanced, // A/B/C/G/I/X/Y/Z (genişletilmiş kontrol)
}

extension CommandModeExtension on CommandMode {
  String get displayName {
    switch (this) {
      case CommandMode.simple:
        return 'Basit Mod (F/B/R/L)';
      case CommandMode.advanced:
        return 'Gelişmiş Mod (A-Z)';
    }
  }

  String get description {
    switch (this) {
      case CommandMode.simple:
        return 'Temel yön kontrolleri';
      case CommandMode.advanced:
        return 'Detaylı motor kontrolü';
    }
  }
}
