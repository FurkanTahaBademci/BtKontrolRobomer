import 'package:flutter/material.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/bluetooth_device_model.dart';

/// Bluetooth cihaz listesi için widget
class DeviceListTile extends StatelessWidget {
  final BluetoothDeviceModel device;
  final VoidCallback onTap;
  final bool isFromHistory;
  final bool? isActive; // null = bilinmiyor (geçmişte tarama yapılmamış)
  final VoidCallback? onDelete;

  const DeviceListTile({
    super.key,
    required this.device,
    required this.onTap,
    this.isFromHistory = false,
    this.isActive,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Stack(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                10,
                onDelete != null ? 36 : 12,
                10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    device.type == BluetoothDeviceType.classic
                        ? Icons.bluetooth
                        : Icons.bluetooth_searching,
                    color: Colors.blue,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.address,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    device.type == BluetoothDeviceType.classic
                                        ? Colors.blue.shade100
                                        : Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                device.type == BluetoothDeviceType.classic
                                    ? 'Classic'
                                    : 'BLE',
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      device.type == BluetoothDeviceType.classic
                                          ? Colors.blue.shade900
                                          : Colors.purple.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (device.rssi != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.signal_cellular_alt,
                                    size: 14,
                                    color: _getSignalColor(device.rssi!),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${device.rssi}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            if (isFromHistory)
                              Icon(
                                Icons.history,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                            // Aktif/Pasif etiketi
                            if (isActive != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isActive!
                                          ? Colors.green.shade100
                                          : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isActive!
                                          ? Icons.wifi_tethering
                                          : Icons.wifi_tethering_off,
                                      size: 10,
                                      color:
                                          isActive!
                                              ? Colors.green.shade800
                                              : Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      isActive! ? 'Aktif' : 'Kapsama dışı',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isActive!
                                                ? Colors.green.shade800
                                                : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
          // Sağ üst köşe × silme butonu
          if (onDelete != null)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 13, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi > -60) return Colors.green;
    if (rssi > -80) return Colors.orange;
    return Colors.red;
  }
}
