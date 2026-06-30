import 'package:flutter/material.dart';

class ColorPickerDialog extends StatefulWidget {
  final String initialColor;

  const ColorPickerDialog({
    super.key,
    required this.initialColor,
  });

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late String _selectedColor;

  final List<Map<String, dynamic>> _colorPalette = [
    {'color': '#FF6B6B', 'name': 'Đỏ'},
    {'color': '#FF9F43', 'name': 'Cam'},
    {'color': '#FECA57', 'name': 'Vàng'},
    {'color': '#48DBFB', 'name': 'Xanh dương nhạt'},
    {'color': '#0ABDE3', 'name': 'Xanh dương'},
    {'color': '#FF9FF3', 'name': 'Hồng'},
    {'color': '#F368E0', 'name': 'Hồng đậm'},
    {'color': '#54A0FF', 'name': 'Xanh biển'},
    {'color': '#5F27CD', 'name': 'Tím'},
    {'color': '#341F97', 'name': 'Tím đậm'},
    {'color': '#00D2D3', 'name': 'Xanh ngọc'},
    {'color': '#01CBC6', 'name': 'Xanh mint'},
    {'color': '#10AC84', 'name': 'Xanh lá đậm'},
    {'color': '#EE5A24', 'name': 'Cam đỏ'},
    {'color': '#B33771', 'name': 'Hồng tím'},
    {'color': '#2C3E50', 'name': 'Xanh đen'},
    {'color': '#34495E', 'name': 'Xanh xám'},
    {'color': '#636E72', 'name': 'Xám'},
    {'color': '#B2BEC3', 'name': 'Xám nhạt'},
    {'color': '#DFE6E9', 'name': 'Trắng xám'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Chọn màu highlight',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _colorPalette.map((item) {
                final isSelected = _selectedColor == item['color'];
                final color = Color(int.parse(item['color'].replaceFirst('#', '0xFF')));
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = item['color'];
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : Border.all(color: Colors.grey[300]!, width: 1),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  const Text(
                    'Màu đã chọn:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(int.parse(_selectedColor.replaceFirst('#', '0xFF'))),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _colorPalette.firstWhere(
                      (c) => c['color'] == _selectedColor,
                      orElse: () => {'name': 'Vàng'},
                    )['name'],
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text(
            'Chọn',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A5D4E),
            ),
          ),
        ),
      ],
    );
  }
}