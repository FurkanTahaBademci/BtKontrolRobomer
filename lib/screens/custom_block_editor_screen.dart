import 'package:flutter/material.dart';
import 'package:bt_kontrol_robomer/models/custom_block.dart';

/// Özel blok ekleme/düzenleme ekranı
class CustomBlockEditorScreen extends StatefulWidget {
  /// [block] null ise yeni blok, dolu ise düzenleme modu
  final CustomBlock? block;

  const CustomBlockEditorScreen({super.key, this.block});

  @override
  State<CustomBlockEditorScreen> createState() =>
      _CustomBlockEditorScreenState();
}

class _CustomBlockEditorScreenState extends State<CustomBlockEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _pressController;
  late final TextEditingController _releaseController;
  late int _selectedColorValue;

  bool get _isEditing => widget.block != null;

  @override
  void initState() {
    super.initState();
    final b = widget.block;
    _nameController = TextEditingController(text: b?.name ?? '');
    _pressController = TextEditingController(text: b?.pressChar ?? '');
    _releaseController = TextEditingController(text: b?.releaseChar ?? '');
    _selectedColorValue = b?.colorValue ?? kBlockColors.first.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pressController.dispose();
    _releaseController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final pressChar = _pressController.text;
    final releaseChar = _releaseController.text;

    if (name.isEmpty) {
      _showError('Blok adı boş bırakılamaz.');
      return;
    }
    if (pressChar.isEmpty && releaseChar.isEmpty) {
      _showError('En az bir karakter (basılı veya bırakma) girmelisiniz.');
      return;
    }

    final result = _isEditing
        ? widget.block!.copyWith(
            name: name,
            pressChar: pressChar,
            releaseChar: releaseChar,
            colorValue: _selectedColorValue,
          )
        : CustomBlock(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            name: name,
            pressChar: pressChar,
            releaseChar: releaseChar,
            colorValue: _selectedColorValue,
          );

    Navigator.of(context).pop(result);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Bloğu Düzenle' : 'Yeni Blok Ekle'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Kaydet',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Canlı Önizleme
          _buildPreview(),
          const SizedBox(height: 24),

          // Blok Adı
          _buildSectionTitle('Blok Adı'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Örn: Işık Aç, Korna, Mod 1...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label_outline),
            ),
            maxLength: 20,
          ),
          const SizedBox(height: 20),

          // Gönderilecek Karakterler
          _buildSectionTitle('Bluetooth Karakterleri'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCharField(
                  controller: _pressController,
                  label: 'Basılınca Gönder',
                  hint: 'Örn: H',
                  icon: Icons.touch_app,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCharField(
                  controller: _releaseController,
                  label: 'Bırakınca Gönder',
                  hint: 'Örn: N',
                  icon: Icons.pan_tool_alt_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Arduino\'nun alacağı tek karakteri girin. Boş bırakırsanız o durum için karakter gönderilmez.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Renk Seçimi
          _buildSectionTitle('Buton Rengi'),
          const SizedBox(height: 12),
          _buildColorPicker(),
          const SizedBox(height: 32),

          // Kaydet Butonu
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isEditing ? Icons.save : Icons.add),
              label: Text(_isEditing ? 'Değişiklikleri Kaydet' : 'Blok Ekle'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final name = _nameController.text.trim().isEmpty
        ? 'Örnek'
        : _nameController.text.trim();
    final color = Color(_selectedColorValue);
    return Center(
      child: Column(
        children: [
          Text(
            'Önizleme',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.touch_app, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
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
        ],
      ),
    );
  }

  Widget _buildCharField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      maxLength: 4,
      textCapitalization: TextCapitalization.characters,
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: kBlockColors.map((color) {
        final isSelected = color.value == _selectedColorValue;
        return GestureDetector(
          onTap: () => setState(() => _selectedColorValue = color.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isSelected ? 0.3 : 0.15),
                  blurRadius: isSelected ? 8 : 4,
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 22)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
    );
  }
}
