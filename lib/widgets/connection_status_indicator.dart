import 'package:flutter/material.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/connection_state.dart'
    as app_state;

/// Bağlantı durumu göstergesi widget'ı
class ConnectionStatusIndicator extends StatelessWidget {
  final app_state.ConnectionState state;
  final String? deviceName;

  const ConnectionStatusIndicator({
    super.key,
    required this.state,
    this.deviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIcon(),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.displayText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              if (deviceName != null && state.isConnected)
                Text(
                  deviceName!,
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (state.isConnecting) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Icon(_getIcon(), color: Colors.white, size: 20);
  }

  IconData _getIcon() {
    switch (state) {
      case app_state.ConnectionState.connected:
        return Icons.bluetooth_connected;
      case app_state.ConnectionState.disconnected:
        return Icons.bluetooth_disabled;
      case app_state.ConnectionState.error:
        return Icons.error_outline;
      case app_state.ConnectionState.connecting:
        return Icons.bluetooth_searching;
    }
  }

  Color _getBackgroundColor() {
    switch (state) {
      case app_state.ConnectionState.connected:
        return Colors.green;
      case app_state.ConnectionState.disconnected:
        return Colors.grey;
      case app_state.ConnectionState.error:
        return Colors.red;
      case app_state.ConnectionState.connecting:
        return Colors.orange;
    }
  }
}
