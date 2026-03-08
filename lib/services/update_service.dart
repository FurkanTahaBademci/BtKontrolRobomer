import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
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

  /// Eski APK dosyalarını temizle (depolama optimizasyonu)
  static Future<void> _cleanOldApks(Directory dir) async {
    try {
      final files = dir.listSync();
      for (var entity in files) {
        if (entity is File && entity.path.endsWith('.apk')) {
          // Uygulamamızın APK dosyalarını sil
          final fileName = entity.path.split(Platform.pathSeparator).last;
          if (fileName.startsWith('app-update') ||
              fileName.startsWith('mucit')) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      // Hata durumunda sessizce devam et
    }
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
      // İndirme dizini (fallback mekanizması ile)
      Directory? dir = await getExternalStorageDirectory();
      dir ??= await getTemporaryDirectory();

      // Eski APK'ları temizle (depolama optimizasyonu)
      await _cleanOldApks(dir);

      final filePath = '${dir.path}/app-update.apk';

      // Dio ile indir (progress tracking ve redirect desteği)
      final dio = Dio();
      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            onProgress(received / total);
          }
        },
        options: Options(
          followRedirects: true,
          maxRedirects: 5,
          receiveTimeout: const Duration(minutes: 10),
        ),
      );

      // İndirilen dosyayı doğrula
      final downloadedFile = File(filePath);
      if (await downloadedFile.exists() && await downloadedFile.length() > 0) {
        return filePath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// İndirilen APK'yı yükle (Android yükleme ekranını aç)
  /// Returns: null = başarılı, String = hata mesajı
  static Future<String?> installApk(String filePath) async {
    try {
      // Dosya varlığını kontrol et
      final file = File(filePath);
      if (!await file.exists()) {
        return 'APK dosyası bulunamadı. Lütfen tekrar indirin.';
      }

      // Bilinmeyen kaynaklardan yükleme izni kontrol et (Android 8+)
      if (Platform.isAndroid) {
        var status = await Permission.requestInstallPackages.status;
        if (!status.isGranted) {
          status = await Permission.requestInstallPackages.request();
          if (!status.isGranted) {
            return 'Bilinmeyen kaynaklardan yükleme izni gerekli.\n\nAyarlar > Uygulamalar > Mucit Akademi > Bilinmeyen uygulamaları yükle seçeneğini açın.';
          }
        }
      }

      // APK'yı aç (yükleme ekranını başlat)
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      switch (result.type) {
        case ResultType.done:
          return null; // Başarılı
        case ResultType.fileNotFound:
          return 'APK dosyası bulunamadı.';
        case ResultType.noAppToOpen:
          return 'APK dosyasını açacak uygulama bulunamadı.';
        case ResultType.permissionDenied:
          return 'Dosya erişim izni reddedildi. Ayarlardan izin verin.';
        case ResultType.error:
          return 'APK açılamadı: ${result.message}';
      }
    } catch (e) {
      return 'Yükleme hatası: $e';
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
