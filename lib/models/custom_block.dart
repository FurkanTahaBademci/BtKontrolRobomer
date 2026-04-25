import 'dart:convert';
import 'package:flutter/material.dart';

/// Kullanıcı tarafından oluşturulan özel kontrol bloğu modeli
class CustomBlock {
  final String id;
  String name;
  String pressChar;    // Butona basılınca gönderilecek karakter
  String releaseChar;  // Buton bırakılınca gönderilecek karakter
  Offset position;     // Normalize edilmiş ekran pozisyonu (0.0-1.0)
  int colorValue;      // Color.value olarak renk

  CustomBlock({
    required this.id,
    required this.name,
    required this.pressChar,
    required this.releaseChar,
    this.position = const Offset(0.5, 0.5),
    this.colorValue = 0xFF2196F3, // Varsayılan mavi
  });

  Color get color => Color(colorValue);

  /// JSON'dan oluştur
  factory CustomBlock.fromJson(Map<String, dynamic> json) {
    return CustomBlock(
      id: json['id'] as String,
      name: json['name'] as String,
      pressChar: json['pressChar'] as String,
      releaseChar: json['releaseChar'] as String,
      position: Offset(
        (json['posX'] as num?)?.toDouble() ?? 0.5,
        (json['posY'] as num?)?.toDouble() ?? 0.5,
      ),
      colorValue: json['colorValue'] as int? ?? 0xFF2196F3,
    );
  }

  /// JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pressChar': pressChar,
      'releaseChar': releaseChar,
      'posX': position.dx,
      'posY': position.dy,
      'colorValue': colorValue,
    };
  }

  /// Kopyasını oluştur
  CustomBlock copyWith({
    String? id,
    String? name,
    String? pressChar,
    String? releaseChar,
    Offset? position,
    int? colorValue,
  }) {
    return CustomBlock(
      id: id ?? this.id,
      name: name ?? this.name,
      pressChar: pressChar ?? this.pressChar,
      releaseChar: releaseChar ?? this.releaseChar,
      position: position ?? this.position,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  /// Liste kodlama/çözme yardımcıları
  static String encodeList(List<CustomBlock> blocks) {
    return jsonEncode(blocks.map((b) => b.toJson()).toList());
  }

  static List<CustomBlock> decodeList(String raw) {
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CustomBlock.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  String toString() =>
      'CustomBlock(id: $id, name: $name, press: $pressChar, release: $releaseChar)';
}

/// Önceden tanımlı renk seçenekleri
const List<Color> kBlockColors = [
  Color(0xFF2196F3), // Mavi
  Color(0xFF4CAF50), // Yeşil
  Color(0xFFFF5722), // Turuncu-Kırmızı
  Color(0xFF9C27B0), // Mor
  Color(0xFFFF9800), // Turuncu
  Color(0xFF00BCD4), // Camgöbeği
  Color(0xFFE91E63), // Pembe
  Color(0xFF607D8B), // Gri-Mavi
  Color(0xFF795548), // Kahverengi
  Color(0xFFF44336), // Kırmızı
];
