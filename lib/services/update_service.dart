import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:bt_kontrol_robomer/models/version_info.dart';

/// Uygulama güncelleme servisi
class UpdateService {
  // GitHub version.json URL'i (kendi repo'nuza göre değiştirin)
  static const String versionCheckUrl =
      'https://raw.githubusercontent.com/FurkanTahaBademci/BtKontrolRobomer/main/releases/version.json';

  /// Güncelleme kontrolü yap
  /// Returns: VersionInfo veya null (hata durumunda)
  static Future<VersionInfo?> checkForUpdate() async {
    try {
      final response = await http
          .get(
            Uri.parse(versionCheckUrl),
            headers: {'Cache-Control': 'no-cache'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return VersionInfo.fromJson(json);
      }
      return null;
    } catch (e) {
      // İnternet yok veya başka hata
      return null;
    }
  }

  /// Mevcut uygulama versiyonunu al
  static Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// Mevcut version code'u al
  static Future<int> getCurrentVersionCode() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return int.tryParse(packageInfo.buildNumber) ?? 1;
  }

  /// Güncelleme gerekli mi kontrol et
  static Future<bool> isUpdateAvailable() async {
    final versionInfo = await checkForUpdate();
    if (versionInfo == null) return false;

    final currentVersion = await getCurrentVersion();
    return VersionInfo.isNewerVersion(
      currentVersion,
      versionInfo.latestVersion,
    );
  }

  /// APK dosyasını indir
  /// [downloadUrl] - APK download linki
  /// [onProgress] - İndirme ilerlemesi callback (0.0 - 1.0)
  /// Returns: İndirilen dosya yolu veya null
  static Future<String?> downloadApk(
    String downloadUrl, {
    Function(double)? onProgress,
  }) async {
    try {
      // İndirme dizini
      final dir = await getExternalStorageDirectory();
      if (dir == null) return null;

      final filePath = '${dir.path}/app-update.apk';

      // Eski APK varsa sil
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Dio ile indir (progress tracking için)
      final dio = Dio();
      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            final progress = received / total;
            onProgress(progress);
          }
        },
      );

      return filePath;
    } catch (e) {
      return null;
    }
  }

  /// İndirilen APK'yı yükle (Android yükleme ekranını aç)
  static Future<bool> installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      return result.type == ResultType.done;
    } catch (e) {
      return false;
    }
  }

  /// Zorunlu güncelleme mi kontrol et
  static Future<bool> isForceUpdateRequired() async {
    final versionInfo = await checkForUpdate();
    if (versionInfo == null) return false;

    // forceUpdate flag kontrolü
    if (versionInfo.forceUpdate) return true;

    // Minimum gerekli versiyon kontrolü
    final currentVersion = await getCurrentVersion();
    final minVersion = versionInfo.minRequiredVersion;

    return VersionInfo.isNewerVersion(currentVersion, minVersion) &&
        currentVersion != minVersion;
  }

  /// Uygulama bilgilerini al
  static Future<Map<String, String>> getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
    };
  }
}
