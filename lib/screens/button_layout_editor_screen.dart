import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:bt_kontrol_robomer/providers/settings_provider.dart';

/// Buton duzeni indeksleri (SettingsProvider.buttonPositions sirasi)
enum ButtonSlot {
  forward(0, 'Ileri', Icons.arrow_upward, Colors.blue),
  backward(1, 'Geri', Icons.arrow_downward, Colors.blue),
  left(2, 'Sol', Icons.arrow_back, Colors.blue),
  right(3, 'Sag', Icons.arrow_forward, Colors.blue),
  stop(4, 'DUR', Icons.stop_circle, Colors.red),
  speed(5, 'Hiz', Icons.speed, Colors.blueGrey);

  const ButtonSlot(this.slotIndex, this.label, this.icon, this.color);
  final int slotIndex;
  final String label;
  final IconData icon;
  final Color color;
}

class ButtonLayoutEditorScreen extends StatefulWidget {
  const ButtonLayoutEditorScreen({super.key});

  @override
  State<ButtonLayoutEditorScreen> createState() =>
      _ButtonLayoutEditorScreenState();
}

class _ButtonLayoutEditorScreenState extends State<ButtonLayoutEditorScreen> {
  late List<Offset> _positions;
  int? _dragging;
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _positions = List.of(settings.buttonPositions);
    _applyOrientation(settings.screenOrientation);
  }

  void _applyOrientation(ScreenOrientation orientation) {
    switch (orientation) {
      case ScreenOrientation.portrait:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        break;
      case ScreenOrientation.landscape:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case ScreenOrientation.auto:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Offset _toPixel(Offset norm) =>
      Offset(norm.dx * _canvasSize.width, norm.dy * _canvasSize.height);

  Offset _toNorm(Offset px) => Offset(
    (px.dx / _canvasSize.width).clamp(0.0, 1.0),
    (px.dy / _canvasSize.height).clamp(0.0, 1.0),
  );

  void _onDragUpdate(int index, DragUpdateDetails d) {
    setState(() {
      final updated = _toPixel(_positions[index]) + d.delta;
      _positions[index] = _toNorm(updated);
    });
  }

  Future<void> _save() async {
    await context.read<SettingsProvider>().setButtonPositions(_positions);
    if (mounted) Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _positions = List.of(SettingsProvider.defaultButtonPositions);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final btnSize = settings.buttonSize;
    final btnRadius = settings.buttonRadius;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

            return Stack(
              children: [
                // Yon butonlari
                for (final slot in [
                  ButtonSlot.forward,
                  ButtonSlot.backward,
                  ButtonSlot.left,
                  ButtonSlot.right,
                ])
                  _draggableSquareBtn(slot, btnSize, btnRadius),

                // DUR butonu (yon butonlariyla ayni boyut)
                _draggableSquareBtn(ButtonSlot.stop, btnSize, btnRadius),

                // Overlay: geri + sifirla + kaydet
                Positioned(
                  top: 8,
                  left: 8,
                  child: _overlayButton(
                    icon: Icons.arrow_back,
                    label: 'Geri',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 100,
                  child: _overlayButton(
                    icon: Icons.refresh,
                    label: 'Sifirla',
                    onTap: _reset,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _overlayButton(
                    icon: Icons.check,
                    label: 'Kaydet',
                    color: Theme.of(context).colorScheme.primary,
                    onTap: _save,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _overlayButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final col = color ?? Theme.of(context).colorScheme.onSurface;
    return Material(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.82),
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: col),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: col,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _draggableSquareBtn(ButtonSlot slot, double size, double radius) {
    final px = _toPixel(_positions[slot.slotIndex]);
    final dragging = _dragging == slot.slotIndex;
    return Positioned(
      left: px.dx - size / 2,
      top: px.dy - size / 2,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _dragging = slot.slotIndex),
        onPanUpdate: (d) => _onDragUpdate(slot.slotIndex, d),
        onPanEnd: (_) => setState(() => _dragging = null),
        child: _btnDecoration(
          width: size,
          height: size,
          color: slot.color,
          radius: radius,
          dragging: dragging,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(slot.icon, color: Colors.white, size: size * 0.38),
              const SizedBox(height: 2),
              Text(
                slot.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btnDecoration({
    required double width,
    required double height,
    required Color color,
    required double radius,
    required bool dragging,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(dragging ? 0.75 : 1.0),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dragging ? 0.3 : 0.18),
            blurRadius: dragging ? 12 : 6,
            offset: Offset(0, dragging ? 6 : 3),
          ),
        ],
        border:
            dragging
                ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.5,
                )
                : null,
      ),
      child: child,
    );
  }
}
