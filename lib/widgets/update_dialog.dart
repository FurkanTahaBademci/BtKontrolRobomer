import 'package:flutter/material.dart';
import 'package:bt_kontrol_robomer/models/version_info.dart';
import 'package:bt_kontrol_robomer/services/update_service.dart';

/// Güncelleme dialog'u
class UpdateDialog extends StatefulWidget {
  final VersionInfo versionInfo;
  final bool forceUpdate;

  const UpdateDialog({
    super.key,
    required this.versionInfo,
    this.forceUpdate = false,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = '';

  Future<void> _startUpdate() async {
    setState(() {
      _isDownloading = true;
      _statusMessage = 'İndiriliyor...';
    });

    try {
      // APK'yı indir
      final filePath = await UpdateService.downloadApk(
        widget.versionInfo.downloadUrl,
        onProgress: (progress) {
          setState(() {
            _downloadProgress = progress;
            _statusMessage =
                'İndiriliyor... ${(progress * 100).toStringAsFixed(0)}%';
          });
        },
      );

      if (filePath != null) {
        setState(() {
          _statusMessage = 'Yükleme hazırlanıyor...';
        });

        // APK'yı yükle (izin kontrolü dahil)
        final error = await UpdateService.installApk(filePath);

        if (mounted) {
          if (error != null) {
            setState(() {
              _isDownloading = false;
              _statusMessage = '';
            });
            _showError(error);
          } else {
            // Yükleme başlatıldı - kullanıcı yükleyici ile devam edecek
            setState(() {
              _isDownloading = false;
              _statusMessage = 'Yükleme başlatıldı. Yükleyiciyi takip edin.';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _statusMessage = '';
          });
          _showError('İndirme başarısız. İnternet bağlantınızı kontrol edin.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _statusMessage = '';
        });
        _showError('Bir hata oluştu: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.forceUpdate && !_isDownloading,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(
              widget.forceUpdate
                  ? Icons.warning_amber_rounded
                  : Icons.system_update,
              color: widget.forceUpdate ? Colors.orange : Colors.blue,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.forceUpdate ? 'Zorunlu Güncelleme' : 'Güncelleme Mevcut',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.forceUpdate)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bu güncellemeyi yüklemeden uygulamayı kullanamazsınız.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              _buildInfoRow(
                Icons.new_releases,
                'Yeni Versiyon',
                widget.versionInfo.latestVersion,
              ),
              const SizedBox(height: 8),
              if (widget.versionInfo.fileSize.isNotEmpty)
                _buildInfoRow(
                  Icons.storage,
                  'Boyut',
                  widget.versionInfo.fileSize,
                ),
              if (widget.versionInfo.fileSize.isNotEmpty)
                const SizedBox(height: 8),
              if (widget.versionInfo.releaseDate.isNotEmpty)
                _buildInfoRow(
                  Icons.calendar_today,
                  'Tarih',
                  widget.versionInfo.releaseDate,
                ),
              if (widget.versionInfo.releaseDate.isNotEmpty)
                const SizedBox(height: 16),
              if (widget.versionInfo.releaseNotes.isNotEmpty) ...[
                const Row(
                  children: [
                    Icon(Icons.article_outlined, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      'Değişiklikler:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.versionInfo.releaseNotes,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
              if (_isDownloading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _downloadProgress,
                  backgroundColor: Colors.grey.shade200,
                ),
                const SizedBox(height: 8),
                Text(
                  _statusMessage,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!widget.forceUpdate && !_isDownloading)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Daha Sonra'),
            ),
          if (!_isDownloading)
            FilledButton.icon(
              onPressed: _startUpdate,
              icon: const Icon(Icons.download, size: 18),
              label: Text(widget.forceUpdate ? 'Güncelle' : 'Şimdi Güncelle'),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
