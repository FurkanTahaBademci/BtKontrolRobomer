import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bt_kontrol_robomer/core/bluetooth/models/robot_command.dart';

/// Yön kontrolü için özel buton widget'ı
class DirectionButton extends StatefulWidget {
  final RobotCommand command;
  final IconData icon;
  final String label;
  final Function(RobotCommand) onPressed;
  final Function() onReleased;
  final Color? color;
  final bool enableVibration;
  final double? size;
  final double? borderRadius;

  const DirectionButton({
    super.key,
    required this.command,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.onReleased,
    this.color,
    this.enableVibration = true,
    this.size,
    this.borderRadius,
  });

  @override
  State<DirectionButton> createState() => _DirectionButtonState();
}

class _DirectionButtonState extends State<DirectionButton> {
  bool _isPressed = false;

  void _handlePressStart() {
    setState(() => _isPressed = true);
    if (widget.enableVibration) {
      HapticFeedback.lightImpact(); // Titreşim feedback
    }
    widget.onPressed(widget.command);
  }

  void _handlePressEnd() {
    setState(() => _isPressed = false);
    widget.onReleased();
  }

  @override
  Widget build(BuildContext context) {
    // Özel boyut veya responsive boyutlandırma
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonSize = widget.size ?? (screenHeight > 600 ? 70.0 : 60.0);
    final iconSize = buttonSize * 0.4;
    final fontSize = buttonSize * 0.15;
    final radius = widget.borderRadius ?? 14.0;

    return Listener(
      onPointerDown: (_) => _handlePressStart(),
      onPointerUp: (_) => _handlePressEnd(),
      onPointerCancel: (_) => _handlePressEnd(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color:
              _isPressed
                  ? (widget.color ?? Colors.blue).withOpacity(0.8)
                  : (widget.color ?? Colors.blue),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isPressed ? 0.1 : 0.3),
              blurRadius: _isPressed ? 4 : 8,
              offset: Offset(0, _isPressed ? 2 : 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: Colors.white, size: iconSize),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
