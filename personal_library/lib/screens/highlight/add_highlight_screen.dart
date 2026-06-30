import 'package:flutter/material.dart';
import '../../services/highlight_service.dart';
import '../../widgets/color_picker_dialog.dart';

class AddHighlightScreen extends StatefulWidget {
  final String bookId;
  final String cfi;
  final String text;
  final String? selectedColor;

  const AddHighlightScreen({
    super.key,
    required this.bookId,
    required this.cfi,
    required this.text,
    this.selectedColor,
  });

  @override
  State<AddHighlightScreen> createState() => _AddHighlightScreenState();
}

class _AddHighlightScreenState extends State<AddHighlightScreen> {
  final TextEditingController _noteController = TextEditingController();
  String _selectedColor = '#FFD700';
  bool _isLoading = false;
  final HighlightService _highlightService = HighlightService();

  final List<Map<String, dynamic>> _colors = [
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
  ];

  @override
  void initState() {
    super.initState();
    if (widget.selectedColor != null) {
      _selectedColor = widget.selectedColor!;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung ghi chú'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _highlightService.addHighlight(
        bookId: widget.bookId,
        cfi: widget.cfi,
        text: widget.text,
        color: _selectedColor,
        note: note,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã lưu highlight và ghi chú'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  void _openColorPicker() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => ColorPickerDialog(
        initialColor: _selectedColor,
      ),
    );
    if (result != null) {
      setState(() {
        _selectedColor = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Thêm ghi chú',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: const Text(
              'Lưu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5D4E),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Đoạn văn được chọn
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đoạn văn được chọn',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Text(
                            widget.text,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bảng chọn màu
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Chọn màu highlight',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _openColorPicker,
                              icon: const Icon(Icons.palette, size: 16),
                              label: const Text('Thêm màu'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _colors.map((item) {
                            final isSelected = _selectedColor == item['color'];
                            final color = Color(int.parse(item['color'].replaceFirst('#', '0xFF')));
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedColor = item['color'];
                                });
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: Colors.black, width: 2.5)
                                      : Border.all(
                                          color: Colors.grey[300]!,
                                          width: 1,
                                        ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.15),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ghi chú
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ghi chú',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _noteController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Nhập nội dung ghi chú...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF4A5D4E),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}