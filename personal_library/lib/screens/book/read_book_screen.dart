import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../services/reading_service.dart';
import 'kindle_reader_screen.dart';

class ReadBookScreen extends StatefulWidget {
  final String bookId;
  final String fileUrl;
  final String loaiFile;

  const ReadBookScreen({
    super.key,
    required this.bookId,
    required this.fileUrl,
    required this.loaiFile,
  });

  @override
  State<ReadBookScreen> createState() => _ReadBookScreenState();
}

class _ReadBookScreenState extends State<ReadBookScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  int _currentPage = 1;
  int _startPage = 1;
  int _totalPages = 0;
  String? _savedCfi; // 🔥 THÊM
  String? _latestCfi; // 🔥 THÊM
  Timer? _debounce;

  final PdfViewerController _pdfController = PdfViewerController();
  KindleEpubEngine? _kindleEngine;

  final _service = ReadingService();
  DateTime? _sessionStart;

  @override
  void initState() {
    super.initState();
    _sessionStart = DateTime.now();
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _saveOnExit();
    _kindleEngine?.dispose();
    super.dispose();
  }

  // ================= INIT =================
  Future<void> _init() async {
    await _loadProgress();

    if (widget.loaiFile.toUpperCase() == 'EPUB') {
      await _loadEpub();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProgress() async {
    final data = await _service.getProgress(widget.bookId);
    _currentPage = data['trang_hien_tai'] ?? 1;
    if (_currentPage <= 0) _currentPage = 1;
    _startPage = _currentPage;
    _savedCfi = data['epubCfi'] as String?; // 🔥 LẤY CFI
    debugPrint('📖 Loaded: page=$_currentPage, cfi=$_savedCfi');
  }

  // ================= EPUB =================
  Future<void> _loadEpub() async {
    try {
      _kindleEngine = KindleEpubEngine(
        widget.fileUrl,
        onPageChanged: (page) {
          if (!mounted) return;
          setState(() {
            _currentPage = page + 1;
            _totalPages = _kindleEngine?.pageCount ?? 0;
            _latestCfi = _kindleEngine?.getCurrentCfi();
          });
          _scheduleSave();
        },
        onLoaded: (totalPages) {
          if (!mounted) return;
          setState(() {
            _totalPages = totalPages;
          });

          // 🔥 RESTORE: Ưu tiên CFI, fallback page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_savedCfi != null && _savedCfi!.isNotEmpty) {
              _kindleEngine?.goToCfi(_savedCfi!);
              debugPrint('📍 Restored by CFI: $_savedCfi');
            } else if (_currentPage > 1 && _currentPage <= totalPages) {
              _kindleEngine?.jumpToPage(_currentPage - 1);
              debugPrint('📍 Restored by page: $_currentPage');
            }
          });
        },
      );

      await _kindleEngine!.open();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = "EPUB error: $e";
        _isLoading = false;
      });
    }
  }

  // ================= SAVE =================
  Future<void> _save() async {
    try {
      String? cfi;
      if (_kindleEngine != null) {
        cfi = _kindleEngine?.getCurrentCfi();
      }

      await _service.saveProgress(
        bookId: widget.bookId,
        trangHienTai: _currentPage,
        epubCfi: cfi ?? _latestCfi,
      );
      debugPrint('💾 Saved: page=$_currentPage, cfi=${cfi ?? _latestCfi}');
    } catch (e) {
      debugPrint('❌ Save error: $e');
    }
  }

  void _saveOnExit() {
    _save();
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _save);
  }

  // ================= PDF =================
  Widget _buildPdf() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đọc sách'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () => _showGoToDialog(),
                child: Text(
                  "Trang $_currentPage",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.fileUrl,
            controller: _pdfController,
            scrollDirection: PdfScrollDirection.horizontal,
            pageSpacing: 0,
            canShowPaginationDialog: false,
            canShowScrollHead: false,
            onDocumentLoaded: (details) {
              setState(() {
                _totalPages = details.document.pages.count;
              });
              if (_currentPage > 1) {
                _pdfController.jumpToPage(_currentPage);
              }
            },
            onPageChanged: (details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
              _scheduleSave();
            },
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  // ================= EPUB =================
  Widget _buildEpub() {
    if (_kindleEngine == null) {
      return const Scaffold(body: Center(child: Text('Không thể tải EPUB')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đọc sách'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () => _showGoToDialog(),
                child: Text(
                  _totalPages > 0
                      ? "$_currentPage/$_totalPages"
                      : "Trang $_currentPage",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTapUp: (d) {
              final w = MediaQuery.of(context).size.width;
              if (d.globalPosition.dx < w * 0.3) {
                _kindleEngine?.prevPage();
              } else if (d.globalPosition.dx > w * 0.7) {
                _kindleEngine?.nextPage();
              }
            },
            child: _kindleEngine!.buildView(),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  // ================= NAVIGATION BUTTONS =================
  Widget _buildNavigationButtons() {
    final isEpub = widget.loaiFile.toUpperCase() == 'EPUB';
    final canPrev = isEpub
        ? (_kindleEngine?.currentPage ?? 0) > 0
        : _currentPage > 1;
    final canNext = isEpub
        ? (_kindleEngine?.currentPage ?? 0) <
              (_kindleEngine?.pageCount ?? 0) - 1
        : _currentPage < _totalPages;

    return Stack(
      children: [
        Positioned(
          left: 10,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton(
              icon: Icon(
                Icons.chevron_left,
                size: 42,
                color: canPrev ? Colors.black54 : Colors.black12,
              ),
              onPressed: canPrev
                  ? () {
                      if (isEpub) {
                        _kindleEngine?.prevPage();
                      } else {
                        _pdfController.previousPage();
                      }
                    }
                  : null,
            ),
          ),
        ),
        Positioned(
          right: 10,
          top: 0,
          bottom: 0,
          child: Center(
            child: IconButton(
              icon: Icon(
                Icons.chevron_right,
                size: 42,
                color: canNext ? Colors.black54 : Colors.black12,
              ),
              onPressed: canNext
                  ? () {
                      if (isEpub) {
                        _kindleEngine?.nextPage();
                      } else {
                        _pdfController.nextPage();
                      }
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // ================= GO TO DIALOG =================
  void _showGoToDialog() {
    final controller = TextEditingController(text: _currentPage.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đi tới trang"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "1 - $_totalPages",
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page > 0 && page <= _totalPages) {
                if (widget.loaiFile.toUpperCase() == 'PDF') {
                  _pdfController.jumpToPage(page);
                } else {
                  _kindleEngine?.jumpToPage(page - 1);
                }
                setState(() => _currentPage = page);
                _scheduleSave();
              }
              Navigator.pop(context);
            },
            child: const Text("Đi đến"),
          ),
        ],
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(body: Center(child: Text(_errorMessage!)));
    }

    return widget.loaiFile.toUpperCase() == 'PDF' ? _buildPdf() : _buildEpub();
  }
}