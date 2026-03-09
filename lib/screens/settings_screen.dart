import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:bt_kontrol_robomer/providers/settings_provider.dart';
import 'package:bt_kontrol_robomer/providers/connection_history_provider.dart';
import 'package:bt_kontrol_robomer/services/update_service.dart';
import 'package:bt_kontrol_robomer/models/version_info.dart';
import 'package:bt_kontrol_robomer/widgets/update_dialog.dart';
import 'package:bt_kontrol_robomer/screens/button_layout_editor_screen.dart';

/// Ayarlar ekranı
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = info.version);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final historyProvider = context.watch<ConnectionHistoryProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Görünüm Ayarları
          _buildSectionTitle('Görünüm'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tema',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto),
                          label: Text('Sistem'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode),
                          label: Text('Açık'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode),
                          label: Text('Koyu'),
                        ),
                      ],
                      selected: {settingsProvider.themeMode},
                      onSelectionChanged: (selection) {
                        settingsProvider.setThemeMode(selection.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Varsayılan Hız Ayarı
          _buildSectionTitle('Robot Kontrol'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Varsayılan Hız',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${settingsProvider.defaultSpeed}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: settingsProvider.defaultSpeed.toDouble(),
                    min: 0,
                    max: 255,
                    divisions: 255,
                    label: settingsProvider.defaultSpeed.toString(),
                    onChanged: (value) {
                      settingsProvider.setDefaultSpeed(value.toInt());
                    },
                  ),
                  const Text(
                    'Robot başlatıldığında kullanılacak hız değeri (0-255 PWM)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Vibrasyon Ayarı
          Card(
            child: SwitchListTile(
              title: const Text('Titreşim'),
              subtitle: const Text('Buton basıldığında titreşim'),
              value: settingsProvider.vibrationEnabled,
              onChanged: (value) {
                settingsProvider.setVibrationEnabled(value);
              },
              secondary: const Icon(Icons.vibration),
            ),
          ),
          const SizedBox(height: 16),

          // Buton Özelleştirme
          _buildSectionTitle('Buton Özelleştirme'),
          // Buton Düzenleyici
          Card(
            child: ListTile(
              leading: const Icon(Icons.open_in_full),
              title: const Text('Buton Konumlandırıcı'),
              subtitle: const Text(
                'Butonları ekranda sürükleyerek konumlandır',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ButtonLayoutEditorScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Canlı Önizleme
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Önizleme',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Önizleme butonları
                        _buildButtonPreview(settingsProvider),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buton Boyutu
                  _buildSliderRow(
                    icon: Icons.aspect_ratio,
                    label: 'Buton Boyutu',
                    value: settingsProvider.buttonSize,
                    min: 40,
                    max: 120,
                    unit: 'px',
                    onChanged: (v) => settingsProvider.setButtonSize(v),
                  ),
                  const SizedBox(height: 16),

                  // Buton Aralığı
                  _buildSliderRow(
                    icon: Icons.space_bar,
                    label: 'Buton Aralığı',
                    value: settingsProvider.buttonSpacing,
                    min: 0,
                    max: 30,
                    unit: 'px',
                    onChanged: (v) => settingsProvider.setButtonSpacing(v),
                  ),
                  const SizedBox(height: 16),

                  // Köşe Yuvarlaklığı
                  _buildSliderRow(
                    icon: Icons.rounded_corner,
                    label: 'Köşe Yuvarlaklığı',
                    value: settingsProvider.buttonRadius,
                    min: 0,
                    max: 30,
                    unit: 'px',
                    onChanged: (v) => settingsProvider.setButtonRadius(v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ekran Yönlendirme
          _buildSectionTitle('Ekran Yönlendirme'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kontrol ekranının yönlendirmesini seçin',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),
                  ...ScreenOrientation.values.map((orientation) {
                    return RadioListTile<ScreenOrientation>(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Text(orientation.icon),
                          const SizedBox(width: 8),
                          Text(orientation.displayName),
                        ],
                      ),
                      subtitle: Text(
                        orientation.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      value: orientation,
                      groupValue: settingsProvider.screenOrientation,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.setScreenOrientation(value);
                        }
                      },
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Geliştirici Modu (Geçici)
          Card(
            child: SwitchListTile(
              title: const Text('Geliştirici Modu'),
              subtitle: const Text(
                'Bağlantı olmadan kontrol ekranını aç (geçici)',
              ),
              value: settingsProvider.developerMode,
              onChanged: (value) {
                settingsProvider.setDeveloperMode(value);
              },
              secondary: Icon(
                Icons.developer_mode,
                color: settingsProvider.developerMode ? Colors.orange : null,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Komut Modu Seçimi
          _buildSectionTitle('Komut Sistemi'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Komut Modu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  ...CommandMode.values.map((mode) {
                    return RadioListTile<CommandMode>(
                      title: Text(mode.displayName),
                      subtitle: Text(mode.description),
                      value: mode,
                      groupValue: settingsProvider.commandMode,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.setCommandMode(value);
                        }
                      },
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Arduino kodunuzun seçilen modu desteklediğinden emin olun.',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Bağlantı Geçmişi
          _buildSectionTitle('Veri Yönetimi'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Bağlantı Geçmişini Temizle'),
              subtitle: Text(
                '${historyProvider.history.length} cihaz kaydedildi',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showClearHistoryDialog(context, historyProvider);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Ayarları Sıfırla
          Card(
            child: ListTile(
              leading: const Icon(Icons.restore, color: Colors.orange),
              title: const Text('Ayarları Sıfırla'),
              subtitle: const Text('Tüm ayarları varsayılana döndür'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showResetSettingsDialog(context, settingsProvider);
              },
            ),
          ),
          const SizedBox(height: 32),

          // Hakkında
          _buildSectionTitle('Hakkında'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/app_logo.png',
                    height: 80,
                    width: 80,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mucit Akademi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versiyon $_appVersion',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Classic Bluetooth (HC-05/06) ve BLE modülleri ile robot kontrolü.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const Divider(height: 32),
                  // Güncelleme Kontrolü
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _checkForUpdates,
                      icon: const Icon(Icons.system_update, size: 20),
                      label: const Text('Güncelleme Kontrolü'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const Divider(height: 32),
                  // Geliştirici Bilgileri
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.code, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Geliştirici',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Furkan Taha Bademci',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      // Email gönderme
                      _launchEmail();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 18,
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'tahafurkanbademci@gmail.com',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Destek için iletişime geçebilirsiniz',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildButtonPreview(SettingsProvider settings) {
    final size = settings.buttonSize;
    final spacing = settings.buttonSpacing;
    final radius = settings.buttonRadius;

    Widget previewBtn(IconData icon) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.4),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        previewBtn(Icons.arrow_upward),
        SizedBox(height: spacing),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            previewBtn(Icons.arrow_back),
            SizedBox(width: spacing + 12),
            previewBtn(Icons.arrow_forward),
          ],
        ),
        SizedBox(height: spacing),
        previewBtn(Icons.arrow_downward),
      ],
    );
  }

  Widget _buildSliderRow({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.round()} $unit',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'tahafurkanbademci@gmail.com',
      query: 'subject=Mucit Akademi Robot Kontrol - Destek',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      // Email açma hatası - sessizce işlenir
    }
  }

  Future<void> _checkForUpdates() async {
    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Güncelleme kontrol ediliyor...'),
                  ],
                ),
              ),
            ),
          ),
    );

    try {
      final versionInfo = await UpdateService.checkForUpdate();

      if (!mounted) return;

      // Loading kapat
      Navigator.of(context).pop();

      if (versionInfo == null) {
        // Güncelleme kontrolü başarısız
        _showMessage(
          'Güncelleme kontrolü yapılamadı. İnternet bağlantınızı kontrol edin.',
          isError: true,
        );
        return;
      }

      final currentVersion = await UpdateService.getCurrentVersion();
      final hasUpdate = VersionInfo.isNewerVersion(
        currentVersion,
        versionInfo.latestVersion,
      );

      if (hasUpdate) {
        // Güncelleme var - dialog göster
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: !versionInfo.forceUpdate,
            builder:
                (context) => UpdateDialog(
                  versionInfo: versionInfo,
                  forceUpdate: versionInfo.forceUpdate,
                ),
          );
        }
      } else {
        // Güncel
        _showMessage('Uygulamanız güncel! (v$currentVersion)');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Loading kapat
        _showMessage('Bir hata oluştu: $e', isError: true);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showClearHistoryDialog(
    BuildContext context,
    ConnectionHistoryProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Geçmişi Temizle'),
            content: const Text(
              'Tüm bağlantı geçmişi silinecek. Devam etmek istiyor musunuz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () async {
                  await provider.clearHistory();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bağlantı geçmişi temizlendi'),
                      ),
                    );
                  }
                },
                child: const Text('Temizle'),
              ),
            ],
          ),
    );
  }

  void _showResetSettingsDialog(
    BuildContext context,
    SettingsProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ayarları Sıfırla'),
            content: const Text(
              'Tüm ayarlar varsayılan değerlerine dönecek. Devam etmek istiyor musunuz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              TextButton(
                onPressed: () async {
                  await provider.resetToDefaults();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ayarlar sıfırlandı')),
                    );
                  }
                },
                child: const Text('Sıfırla'),
              ),
            ],
          ),
    );
  }
}
