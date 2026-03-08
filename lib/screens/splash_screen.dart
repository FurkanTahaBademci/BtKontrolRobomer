import 'package:flutter/material.dart';
import 'package:bt_kontrol_robomer/screens/device_scan_screen.dart';
import 'package:bt_kontrol_robomer/services/update_service.dart';
import 'package:bt_kontrol_robomer/models/version_info.dart';
import 'package:bt_kontrol_robomer/widgets/update_dialog.dart';

/// Splash screen - Uygulama açılış ekranı
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _animationController.forward();

    // Splash animasyonu ve güncelleme kontrolü
    _initializeApp();
  }

  /// Uygulama başlatma ve güncelleme kontrolü
  Future<void> _initializeApp() async {
    // Minimum splash süresi (animasyon için)
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Güncelleme kontrolü yap
    await _checkForUpdates();

    // Ana ekrana geç
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DeviceScanScreen()),
      );
    }
  }

  /// Güncelleme kontrolü
  Future<void> _checkForUpdates() async {
    try {
      final versionInfo = await UpdateService.checkForUpdate();
      
      if (versionInfo == null || !mounted) return;

      final currentVersion = await UpdateService.getCurrentVersion();
      final hasUpdate = VersionInfo.isNewerVersion(
        currentVersion,
        versionInfo.latestVersion,
      );

      if (hasUpdate && mounted) {
        // Güncelleme dialog'u göster
        await showDialog(
          context: context,
          barrierDismissible: !versionInfo.forceUpdate,
          builder: (context) => UpdateDialog(
            versionInfo: versionInfo,
            forceUpdate: versionInfo.forceUpdate,
          ),
        );
      }
    } catch (e) {
      // Güncelleme kontrolü başarısız - sessizce devam et
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Uygulama adı
                      const Text(
                        'Mucit Akademi',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Alt yazı
                      Text(
                        'Bluetooth Robot Kontrolü',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 50),
                      // Loading indicator
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
