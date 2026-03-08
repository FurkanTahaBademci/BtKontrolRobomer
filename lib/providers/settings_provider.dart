import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama ayarlarını yöneten Provider
class SettingsProvider with ChangeNotifier {
  static const String _keyDefaultSpeed = 'default_speed';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyCommandMode = 'command_mode';
  static const String _keyButtonSize = 'button_size';
  static const String _keyButtonSpacing = 'button_spacing';
  static const String _keyButtonRadius = 'button_radius';
  static const String _keyScreenOrientation = 'screen_orientation';

  int _defaultSpeed = 128; // 0-255, varsayılan orta hız
  bool _vibrationEnabled = true;
  CommandMode _commandMode = CommandMode.simple;
  bool _developerMode = false; // Geçici - sadece runtime, kaydetme yok

  // Buton özelleştirme ayarları
  double _buttonSize = 70.0; // 40-120 arası
  double _buttonSpacing = 8.0; // 0-30 arası
  double _buttonRadius = 14.0; // 0-30 arası

  // Ekran yönlendirme ayarı
  ScreenOrientation _screenOrientation = ScreenOrientation.landscape;

  int get defaultSpeed => _defaultSpeed;
  bool get vibrationEnabled => _vibrationEnabled;
  CommandMode get commandMode => _commandMode;
  bool get developerMode => _developerMode;
  double get buttonSize => _buttonSize;
  double get buttonSpacing => _buttonSpacing;
  double get buttonRadius => _buttonRadius;
  ScreenOrientation get screenOrientation => _screenOrientation;

  /// Ayarları yükle
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _defaultSpeed = prefs.getInt(_keyDefaultSpeed) ?? 128;
      _vibrationEnabled = prefs.getBool(_keyVibrationEnabled) ?? true;
      _buttonSize = prefs.getDouble(_keyButtonSize) ?? 70.0;
      _buttonSpacing = prefs.getDouble(_keyButtonSpacing) ?? 8.0;
      _buttonRadius = prefs.getDouble(_keyButtonRadius) ?? 14.0;

      final orientationName = prefs.getString(_keyScreenOrientation) ?? 'landscape';
      _screenOrientation = ScreenOrientation.values.firstWhere(
        (o) => o.name == orientationName,
        orElse: () => ScreenOrientation.landscape,
      );

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

  /// Buton boyutunu ayarla
  Future<void> setButtonSize(double size) async {
    _buttonSize = size.clamp(40.0, 120.0);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyButtonSize, _buttonSize);
    } catch (e) {}
  }

  /// Buton aralığını ayarla
  Future<void> setButtonSpacing(double spacing) async {
    _buttonSpacing = spacing.clamp(0.0, 30.0);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyButtonSpacing, _buttonSpacing);
    } catch (e) {}
  }

  /// Buton köşe yuvarlaklığını ayarla
  Future<void> setButtonRadius(double radius) async {
    _buttonRadius = radius.clamp(0.0, 30.0);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyButtonRadius, _buttonRadius);
    } catch (e) {}
  }

  /// Ekran yönlendirmesini ayarla
  Future<void> setScreenOrientation(ScreenOrientation orientation) async {
    _screenOrientation = orientation;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyScreenOrientation, orientation.name);
    } catch (e) {}
  }

  /// Tüm ayarları sıfırla
  Future<void> resetToDefaults() async {
    _defaultSpeed = 128;
    _vibrationEnabled = true;
    _commandMode = CommandMode.simple;
    _developerMode = false;
    _buttonSize = 70.0;
    _buttonSpacing = 8.0;
    _buttonRadius = 14.0;
    _screenOrientation = ScreenOrientation.landscape;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyDefaultSpeed);
      await prefs.remove(_keyVibrationEnabled);
      await prefs.remove(_keyCommandMode);
      await prefs.remove(_keyButtonSize);
      await prefs.remove(_keyButtonSpacing);
      await prefs.remove(_keyButtonRadius);
      await prefs.remove(_keyScreenOrientation);
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

/// Ekran yönlendirme seçenekleri
enum ScreenOrientation {
  portrait,  // Sadece dikey
  landscape, // Sadece yatay
  auto,      // Otomatik (her iki yön)
}

extension ScreenOrientationExtension on ScreenOrientation {
  String get displayName {
    switch (this) {
      case ScreenOrientation.portrait:
        return 'Dikey (Portrait)';
      case ScreenOrientation.landscape:
        return 'Yatay (Landscape)';
      case ScreenOrientation.auto:
        return 'Otomatik';
    }
  }

  String get description {
    switch (this) {
      case ScreenOrientation.portrait:
        return 'Sadece dikey mod';
      case ScreenOrientation.landscape:
        return 'Sadece yatay mod';
      case ScreenOrientation.auto:
        return 'Cihaz döndürüldüğünde otomatik değişir';
    }
  }

  String get icon {
    switch (this) {
      case ScreenOrientation.portrait:
        return '📱';
      case ScreenOrientation.landscape:
        return '🖥️';
      case ScreenOrientation.auto:
        return '🔄';
    }
  }
}
