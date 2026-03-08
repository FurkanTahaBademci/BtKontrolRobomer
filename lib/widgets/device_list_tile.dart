import 'package:flutter/material.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/bluetooth_device_model.dart';

/// Bluetooth cihaz listesi için widget
class DeviceListTile extends StatelessWidget {
  final BluetoothDeviceModel device;
  final VoidCallback onTap;
  final bool isFromHistory;

  const DeviceListTile({
    super.key,
    required this.device,
    required this.onTap,
    this.isFromHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          device.type == BluetoothDeviceType.classic
              ? Icons.bluetooth
              : Icons.bluetooth_searching,
          color: Colors.blue,
          size: 36,
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              device.address,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
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
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                if (isFromHistory)
                  Icon(Icons.history, size: 14, color: Colors.grey[600]),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Color _getSignalColor(int rssi) {
    if (rssi > -60) return Colors.green;
    if (rssi > -80) return Colors.orange;
    return Colors.red;
  }
}
