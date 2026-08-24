import 'package:flutter/material.dart';

/// Sanal joystick widget'ı
///
/// [onChanged]: normalize edilmiş x,y değerleri (-1.0 ile 1.0)
///   - x: sola -1.0, sağa +1.0
///   - y: geriye -1.0, ileri +1.0 (ekran koordinatı ters çevrilir)
/// [onReleased]: parmak kaldırıldığında çağrılır (dur sinyali)
class JoystickWidget extends StatefulWidget {
  final void Function(double x, double y) onChanged;
  final VoidCallback onReleased;

  /// Joystick'in toplam çapı (piksel)
  final double size;

  const JoystickWidget({
    super.key,
    required this.onChanged,
    required this.onReleased,
    this.size = 220.0,
  });

  @override
  State<JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<JoystickWidget>
    with SingleTickerProviderStateMixin {
  Offset _thumbOffset = Offset.zero;
  bool _isDragging = false;

  late AnimationController _snapController;
  late Animation<Offset> _snapAnimation;
  Offset _animStartOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _snapAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOut));
    _snapAnimation.addListener(() {
      setState(() => _thumbOffset = _snapAnimation.value);
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  double get _baseRadius => widget.size / 2;
  double get _thumbRadius => widget.size / 6;

  /// Parmak hareketi — thumb'ı güncelle ve callback çağır
  void _handlePanUpdate(DragUpdateDetails details) {
    _snapController.stop();
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final center = Offset(_baseRadius, _baseRadius);
    final localPos = renderBox.globalToLocal(details.globalPosition);
    final delta = localPos - center;
    final maxDistance = _baseRadius - _thumbRadius;

    final Offset clampedDelta;
    if (delta.distance <= maxDistance) {
      clampedDelta = delta;
    } else {
      clampedDelta = delta / delta.distance * maxDistance;
    }

    setState(() {
      _thumbOffset = clampedDelta;
      _isDragging = true;
    });

    // Normalize: -1.0 ile 1.0
    final nx = clampedDelta.dx / maxDistance;
    final ny = -clampedDelta.dy / maxDistance; // Y eksenini ters çevir

    widget.onChanged(nx, ny);
  }

  /// Parmak kalktı — thumb'ı merkeze döndür
  void _handlePanEnd() {
    _animStartOffset = _thumbOffset;
    _snapAnimation = Tween<Offset>(
      begin: _animStartOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeOut));

    setState(() => _isDragging = false);
    _snapController.forward(from: 0);
    widget.onReleased();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onPanUpdate: _handlePanUpdate,
      onPanEnd: (_) => _handlePanEnd(),
      onPanCancel: () => _handlePanEnd(),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Arka plan dairesi
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHigh,
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.25),
                  width: 2.5,
                ),
              ),
            ),
            // Merkez yardımcı çizgiler (artı işareti)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 1.5,
                    height: widget.size * 0.35,
                    color: colorScheme.outline.withOpacity(0.15),
                  ),
                ],
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: widget.size * 0.35,
                    height: 1.5,
                    color: colorScheme.outline.withOpacity(0.15),
                  ),
                ],
              ),
            ),
            // Thumb (hareketli iç daire)
            Positioned(
              left: _baseRadius + _thumbOffset.dx - _thumbRadius,
              top: _baseRadius + _thumbOffset.dy - _thumbRadius,
              child: Container(
                width: _thumbRadius * 2,
                height: _thumbRadius * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isDragging
                      ? colorScheme.primary
                      : colorScheme.primary.withOpacity(0.85),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.35),
                      blurRadius: _isDragging ? 12 : 6,
                      spreadRadius: _isDragging ? 3 : 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
