import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bt_kontrol_robomer/models/custom_block.dart';

/// Uygulama ayarlarını yöneten Provider
class SettingsProvider with ChangeNotifier {
  static const String _keyDefaultSpeed = 'default_speed';
  static const String _keyVibrationEnabled = 'vibration_enabled';
  static const String _keyCommandMode = 'command_mode';
  static const String _keyButtonSize = 'button_size';
  static const String _keyButtonSpacing = 'button_spacing';
  static const String _keyButtonRadius = 'button_radius';
  static const String _keyScreenOrientation = 'screen_orientation';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyButtonLayout = 'button_layout';
  static const String _keyCustomBlocks = 'custom_blocks_v1';
  static const String _keyCommandTerminator = 'command_terminator';
  static const String _keyBleForceWriteWithoutResponse = 'ble_force_wwr';

  // Varsayılan buton pozisyonları (normalize: 0.0-1.0 ekran oranı)
  // [forward, backward, left, right, stop, speed, horn]
  static const List<Offset> _defaultButtonPositions = [
    Offset(0.5, 0.15), // ileri
    Offset(0.5, 0.75), // geri
    Offset(0.15, 0.45), // sol
    Offset(0.85, 0.45), // sağ
    Offset(0.5, 0.88), // dur
    Offset(0.5, 0.45), // hız
    Offset(0.15, 0.75), // korna
  ];

  int _defaultSpeed = 128; // 0-255, varsayılan orta hız
  bool _vibrationEnabled = false; // Varsayılan kapalı
  CommandMode _commandMode = CommandMode.simple;
  bool _developerMode = false; // Geçici - sadece runtime, kaydetme yok

  // Buton özelleştirme ayarları
  double _buttonSize = 70.0; // 40-120 arası
  double _buttonSpacing = 8.0; // 0-30 arası
  double _buttonRadius = 14.0; // 0-30 arası

  // Ekran yönlendirme ayarı
  ScreenOrientation _screenOrientation = ScreenOrientation.landscape;
  ThemeMode _themeMode = ThemeMode.system;
  List<Offset> _buttonPositions = List.of(_defaultButtonPositions);

  // Özel bloklar
  List<CustomBlock> _customBlocks = [];

  // Bağlantı optimizasyonu
  CommandTerminator _commandTerminator = CommandTerminator.none;
  bool _bleForceWriteWithoutResponse = false;

  int get defaultSpeed => _defaultSpeed;
  bool get vibrationEnabled => _vibrationEnabled;
  CommandMode get commandMode => _commandMode;
  bool get developerMode => _developerMode;
  double get buttonSize => _buttonSize;
  double get buttonSpacing => _buttonSpacing;
  double get buttonRadius => _buttonRadius;
  ScreenOrientation get screenOrientation => _screenOrientation;
  List<CustomBlock> get customBlocks => List.unmodifiable(_customBlocks);
  CommandTerminator get commandTerminator => _commandTerminator;
  bool get bleForceWriteWithoutResponse => _bleForceWriteWithoutResponse;
  ThemeMode get themeMode => _themeMode;
  List<Offset> get buttonPositions => List.unmodifiable(_buttonPositions);
  static List<Offset> get defaultButtonPositions =>
      List.of(_defaultButtonPositions);

  /// Ayarları yükle
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _defaultSpeed = prefs.getInt(_keyDefaultSpeed) ?? 128;
      _vibrationEnabled = prefs.getBool(_keyVibrationEnabled) ?? false;
      _buttonSize = prefs.getDouble(_keyButtonSize) ?? 70.0;
      _buttonSpacing = prefs.getDouble(_keyButtonSpacing) ?? 8.0;
      _buttonRadius = prefs.getDouble(_keyButtonRadius) ?? 14.0;

      final orientationName =
          prefs.getString(_keyScreenOrientation) ?? 'landscape';
      _screenOrientation = ScreenOrientation.values.firstWhere(
        (o) => o.name == orientationName,
        orElse: () => ScreenOrientation.landscape,
      );

      final modeName = prefs.getString(_keyCommandMode) ?? 'simple';
      _commandMode = CommandMode.values.firstWhere(
        (mode) => mode.name == modeName,
        orElse: () => CommandMode.simple,
      );

      final themeModeName = prefs.getString(_keyThemeMode) ?? 'system';
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == themeModeName,
        orElse: () => ThemeMode.system,
      );

      final layoutRaw = prefs.getString(_keyButtonLayout);
      if (layoutRaw != null) {
        final parts = layoutRaw.split(';');
        if (parts.length >= _defaultButtonPositions.length) {
          _buttonPositions =
              parts.take(_defaultButtonPositions.length).map((p) {
                final xy = p.split(',');
                return Offset(
                  double.tryParse(xy[0]) ?? 0.5,
                  double.tryParse(xy[1]) ?? 0.5,
                );
              }).toList();
        } else if (parts.length > 0) {
          // Eski kayıt daha az buton içeriyorsa: mevcut pozisyonları al,
          // eksik slotlar için varsayılan değerleri kullan
          final loaded =
              parts.map((p) {
                final xy = p.split(',');
                return Offset(
                  double.tryParse(xy[0]) ?? 0.5,
                  double.tryParse(xy[1]) ?? 0.5,
                );
              }).toList();
          _buttonPositions = List.of(_defaultButtonPositions);
          for (int i = 0; i < loaded.length; i++) {
            _buttonPositions[i] = loaded[i];
          }
        }
      }

      // Özel blokları yükle
      final blocksRaw = prefs.getString(_keyCustomBlocks);
      if (blocksRaw != null) {
        _customBlocks = CustomBlock.decodeList(blocksRaw);
      }

      // Bağlantı optimizasyonu ayarları
      final terminatorName =
          prefs.getString(_keyCommandTerminator) ?? 'none';
      _commandTerminator = CommandTerminator.values.firstWhere(
        (t) => t.name == terminatorName,
        orElse: () => CommandTerminator.none,
      );
      _bleForceWriteWithoutResponse =
          prefs.getBool(_keyBleForceWriteWithoutResponse) ?? false;

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

  /// Buton pozisyonlarını kaydet
  Future<void> setButtonPositions(List<Offset> positions) async {
    if (positions.length != _defaultButtonPositions.length) return;
    _buttonPositions = List.of(positions);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = positions.map((o) => '${o.dx},${o.dy}').join(';');
      await prefs.setString(_keyButtonLayout, raw);
    } catch (e) {}
  }

  /// Tema modunu ayarla
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, mode.name);
    } catch (e) {}
  }

  /// Tüm ayarları sıfırla
  Future<void> resetToDefaults() async {
    _defaultSpeed = 128;
    _vibrationEnabled = false; // Varsayılan kapalı
    _commandMode = CommandMode.simple;
    _developerMode = false;
    _buttonSize = 70.0;
    _buttonSpacing = 8.0;
    _buttonRadius = 14.0;
    _screenOrientation = ScreenOrientation.landscape;
    _themeMode = ThemeMode.system;
    _buttonPositions = List.of(_defaultButtonPositions);
    _customBlocks = [];
    _commandTerminator = CommandTerminator.none;
    _bleForceWriteWithoutResponse = false;
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
      await prefs.remove(_keyThemeMode);
      await prefs.remove(_keyButtonLayout);
      await prefs.remove(_keyCustomBlocks);
      await prefs.remove(_keyCommandTerminator);
      await prefs.remove(_keyBleForceWriteWithoutResponse);
    } catch (e) {
      // Silme hatası sessizce işlenir
    }
  }

  // ─── Özel Blok CRUD ────────────────────────────────────────────────────────

  /// Yeni özel blok ekle
  Future<void> addCustomBlock(CustomBlock block) async {
    _customBlocks.add(block);
    notifyListeners();
    await _saveCustomBlocks();
  }

  /// Özel bloğu güncelle
  Future<void> updateCustomBlock(CustomBlock block) async {
    final idx = _customBlocks.indexWhere((b) => b.id == block.id);
    if (idx == -1) return;
    _customBlocks[idx] = block;
    notifyListeners();
    await _saveCustomBlocks();
  }

  /// Özel bloğu sil
  Future<void> removeCustomBlock(String id) async {
    _customBlocks.removeWhere((b) => b.id == id);
    notifyListeners();
    await _saveCustomBlocks();
  }

  /// Özel bloğun pozisyonunu güncelle
  Future<void> setCustomBlockPosition(String id, Offset position) async {
    final block = _customBlocks.firstWhere((b) => b.id == id, orElse: () => throw StateError('Block not found'));
    block.position = position;
    notifyListeners();
    await _saveCustomBlocks();
  }

  Future<void> setCommandTerminator(CommandTerminator t) async {
    _commandTerminator = t;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCommandTerminator, t.name);
    } catch (e) {}
  }

  Future<void> setBleForceWriteWithoutResponse(bool value) async {
    _bleForceWriteWithoutResponse = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBleForceWriteWithoutResponse, value);
    } catch (e) {}
  }

  Future<void> _saveCustomBlocks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCustomBlocks, CustomBlock.encodeList(_customBlocks));
    } catch (e) {}
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
  portrait, // Sadece dikey
  landscape, // Sadece yatay
  auto, // Otomatik (her iki yön)
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

/// Komut sonlandırıcı karakter seçenekleri (klon modül uyumu)
enum CommandTerminator { none, lf, crlf }

extension CommandTerminatorExtension on CommandTerminator {
  /// Arduino'ya gönderilecek gerçek karakter(ler)
  String get value {
    switch (this) {
      case CommandTerminator.none:
        return '';
      case CommandTerminator.lf:
        return '\n';
      case CommandTerminator.crlf:
        return '\r\n';
    }
  }

  String get displayName {
    switch (this) {
      case CommandTerminator.none:
        return 'Yok';
      case CommandTerminator.lf:
        return 'LF (\\n)';
      case CommandTerminator.crlf:
        return 'CRLF (\\r\\n)';
    }
  }

  String get description {
    switch (this) {
      case CommandTerminator.none:
        return 'Varsayılan — sonlandırıcı gönderilmez';
      case CommandTerminator.lf:
        return 'Serial.readStringUntil(\\n) kullanan Arduino kodları için';
      case CommandTerminator.crlf:
        return 'Windows tarzı satır sonu gerektiren sistemler için';
    }
  }
}
