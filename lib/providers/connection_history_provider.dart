import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/bluetooth_device_model.dart';
import 'package:bt_kontrol_robomer/core/constants/bluetooth_constants.dart';

/// Bağlantı geçmişini yöneten Provider
class ConnectionHistoryProvider with ChangeNotifier {
  List<BluetoothDeviceModel> _history = [];

  List<BluetoothDeviceModel> get history => _history;

  /// Geçmişi yükle
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(
        BluetoothConstants.connectionHistoryKey,
      );

      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(historyJson);
        _history =
            decoded
                .map(
                  (item) => BluetoothDeviceModel.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList();
        notifyListeners();
      }
    } catch (e) {
      _history = [];
    }
  }

  /// Cihazı geçmişe ekle
  Future<void> saveDevice(BluetoothDeviceModel device) async {
    try {
      // Duplicate kontrolü
      _history.removeWhere((d) => d.address == device.address);

      // Listenin başına ekle
      _history.insert(0, device);

      // Maksimum limit kontrolü
      if (_history.length > BluetoothConstants.maxHistoryItems) {
        _history = _history.sublist(0, BluetoothConstants.maxHistoryItems);
      }

      // Kaydet
      await _saveToPreferences();
      notifyListeners();
    } catch (e) {
      // Kaydetme hatası sessizce işlenir
    }
  }

  /// Geçmişi temizle
  Future<void> clearHistory() async {
    try {
      _history.clear();
      await _saveToPreferences();
      notifyListeners();
    } catch (e) {
      // Temizleme hatası sessizce işlenir
    }
  }

  /// Geçmişten cihaz kaldır
  Future<void> removeDevice(BluetoothDeviceModel device) async {
    try {
      _history.removeWhere((d) => d.address == device.address);
      await _saveToPreferences();
      notifyListeners();
    } catch (e) {
      // Kaldırma hatası sessizce işlenir
    }
  }

  /// SharedPreferences'a kaydet
  Future<void> _saveToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList =
        _history.map((device) => device.toJson()).toList();
    await prefs.setString(
      BluetoothConstants.connectionHistoryKey,
      json.encode(jsonList),
    );
  }

  /// Cihaz geçmişte var mı?
  bool isInHistory(BluetoothDeviceModel device) {
    return _history.any((d) => d.address == device.address);
  }
}
