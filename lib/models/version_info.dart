/// Güncelleme bilgilerini tutan model
class VersionInfo {
  final String latestVersion;
  final int versionCode;
  final String downloadUrl;
  final String releaseNotes;
  final String minRequiredVersion;
  final bool forceUpdate;
  final String fileSize;
  final String releaseDate;

  VersionInfo({
    required this.latestVersion,
    required this.versionCode,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.minRequiredVersion,
    required this.forceUpdate,
    required this.fileSize,
    required this.releaseDate,
  });

  /// JSON'dan VersionInfo oluştur
  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      latestVersion: json['latestVersion'] as String? ?? '1.0.0',
      versionCode: json['versionCode'] as int? ?? 1,
      downloadUrl: json['downloadUrl'] as String? ?? '',
      releaseNotes: json['releaseNotes'] as String? ?? 'Güncelleme mevcut',
      minRequiredVersion: json['minRequiredVersion'] as String? ?? '1.0.0',
      forceUpdate: json['forceUpdate'] as bool? ?? false,
      fileSize: json['fileSize'] as String? ?? '',
      releaseDate: json['releaseDate'] as String? ?? '',
    );
  }

  /// VersionInfo'yu JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'latestVersion': latestVersion,
      'versionCode': versionCode,
      'downloadUrl': downloadUrl,
      'releaseNotes': releaseNotes,
      'minRequiredVersion': minRequiredVersion,
      'forceUpdate': forceUpdate,
      'fileSize': fileSize,
      'releaseDate': releaseDate,
    };
  }

  /// İki versiyon karşılaştır (1.0.2 > 1.0.1)
  static bool isNewerVersion(String current, String latest) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final latestParts = latest.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        final latestPart = i < latestParts.length ? latestParts[i] : 0;

        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
      }
      return false; // Eşit
    } catch (e) {
      return false;
    }
  }
}
