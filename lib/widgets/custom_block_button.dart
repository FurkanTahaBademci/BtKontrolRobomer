import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bt_kontrol_robomer/models/custom_block.dart';

/// Kullanıcı tarafından oluşturulan özel blok butonu
class CustomBlockButton extends StatefulWidget {
  final CustomBlock block;
  final Future<void> Function(String char) onPressChar;
  final Future<void> Function(String char) onReleaseChar;
  final bool enableVibration;
  final double? size;
  final double? borderRadius;

  const CustomBlockButton({
    super.key,
    required this.block,
    required this.onPressChar,
    required this.onReleaseChar,
    this.enableVibration = true,
    this.size,
    this.borderRadius,
  });

  @override
  State<CustomBlockButton> createState() => _CustomBlockButtonState();
}

class _CustomBlockButtonState extends State<CustomBlockButton> {
  bool _isPressed = false;

  void _handlePressStart() {
    if (_isPressed) return;
    setState(() => _isPressed = true);
    if (widget.enableVibration) {
      HapticFeedback.lightImpact();
    }
    if (widget.block.pressChar.isNotEmpty) {
      widget.onPressChar(widget.block.pressChar);
    }
  }

  void _handlePressEnd() {
    if (!_isPressed) return;
    setState(() => _isPressed = false);
    if (widget.block.releaseChar.isNotEmpty) {
      widget.onReleaseChar(widget.block.releaseChar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonSize = widget.size ?? (screenHeight > 600 ? 70.0 : 60.0);
    final iconSize = buttonSize * 0.28;
    final fontSize = buttonSize * 0.14;
    final radius = widget.borderRadius ?? 14.0;
    final baseColor = widget.block.color;

    return Listener(
      onPointerDown: (_) => _handlePressStart(),
      onPointerUp: (_) => _handlePressEnd(),
      onPointerCancel: (_) => _handlePressEnd(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: _isPressed ? baseColor.withOpacity(0.75) : baseColor,
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
            Icon(Icons.touch_app, color: Colors.white, size: iconSize),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                widget.block.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
