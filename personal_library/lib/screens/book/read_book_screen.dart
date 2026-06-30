import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../core/network/api_client.dart';
import '../../services/reading_service.dart';
import '../../core/storage/auth_storage.dart';
import 'kindle_reader_screen.dart';
import '../../services/highlight_service.dart';
import '../../services/note_service.dart';
import '../../models/highlight_model.dart';
import '../highlight/add_highlight_screen.dart';
import '../highlight/highlight_list_screen.dart';
import '../note/add_note_screen.dart';
import '../note/note_list_screen.dart';
import '../../models/book_model.dart';

class ReadBookScreen extends StatefulWidget {
  final String bookId;
  final String fileUrl;
  final String loaiFile;
  final String? bookTitle;
  final bool readFromBeginning;

  const ReadBookScreen({
    super.key,
    required this.bookId,
    required this.fileUrl,
    required this.loaiFile,
    this.bookTitle,
    this.readFromBeginning = false,
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
  String? _savedCfi;
  String? _latestCfi;
  Timer? _debounce;
  String? _localPdfPath;
  final HighlightService _highlightService = HighlightService();
  final NoteService _noteService = NoteService();
  
  // 🔥 HIGHLIGHT MENU
  OverlayEntry? _highlightMenu;
  String? _selectedText;
  String? _selectedCfi;
  Offset? _selectedPosition;
  bool _isRestoringDone = false;

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
  // ================= INIT =================
  Future<void> _init() async {
    await _loadProgress();
    _startPage = _currentPage;
    debugPrint('📖 Start page: $_startPage, savedCfi: $_savedCfi');

    if (widget.loaiFile.toUpperCase() == 'EPUB') {
      await _loadEpub();
    } else {
      await _loadPdfFile();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProgress() async {
    final data = await _service.getProgress(widget.bookId);
    _currentPage = data['trang_hien_tai'] ?? 1;
    if (_currentPage <= 0) _currentPage = 1;
    _savedCfi = data['epubCfi'] as String?;
    debugPrint('📖 Loaded: page=$_currentPage, cfi=$_savedCfi');
  }

  // ================= LOAD PDF FILE =================
  Future<void> _loadPdfFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/book_${widget.bookId}.pdf');

      if (await file.exists()) {
        _localPdfPath = file.path;
        await _countPdfPages(file.path);
        return;
      }

      debugPrint('📥 Getting signed URL from backend...');

      final token = await AuthStorage.getToken();
      final response = await ApiClient.dio.get(
        '/books/signed-url/${widget.bookId}',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final signedUrl = response.data['url'] as String;
      debugPrint('📄 Signed URL: $signedUrl');

      final dio = Dio();
      final downloadResponse = await dio.get(
        signedUrl,
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => true,
        ),
      );

      if (downloadResponse.statusCode == 200) {
        await file.writeAsBytes(downloadResponse.data as List<int>);
        _localPdfPath = file.path;
        debugPrint('✅ PDF downloaded');
        await _countPdfPages(file.path);
      } else {
        throw Exception('Download failed: ${downloadResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Download PDF error: $e');
      setState(() {
        _errorMessage = 'Không thể tải file PDF. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _countPdfPages(String path) async {
    try {
      _totalPages = 100;
      debugPrint('📄 PDF pages: $_totalPages');
    } catch (e) {
      debugPrint('❌ Count pages error: $e');
    }
  }

  // ================= EPUB =================
  Future<void> _loadEpub() async {
    try {
      _kindleEngine = KindleEpubEngine(
        widget.fileUrl,
        onPageChanged: (page) {
          if (!mounted) return;
          final newPage = page + 1;
          debugPrint('📄 Page changed to: $newPage');
          setState(() {
            _currentPage = newPage;
            _totalPages = _kindleEngine?.pageCount ?? 0;
            _latestCfi = _kindleEngine?.getCurrentCfi();
          });
          _scheduleSave();
        },
        onLoaded: (totalPages) {
          if (!mounted) return;
          debugPrint('📚 Total pages: $totalPages');
          setState(() {
            _totalPages = totalPages;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (_isRestoringDone) return;
              
              if (widget.readFromBeginning) {
                debugPrint('📍 Read from beginning');
                _kindleEngine?.jumpToPage(0);
                setState(() => _currentPage = 1);
                _isRestoringDone = true;
                _scheduleSave();
                return;
              }
              
              if (_savedCfi != null && _savedCfi!.isNotEmpty) {
                debugPrint('📍 Restored by CFI: $_savedCfi');
                _kindleEngine?.goToCfi(_savedCfi!);
                _isRestoringDone = true;
              } else if (_startPage > 1 && _startPage <= totalPages) {
                debugPrint('📍 Restored by page: $_startPage');
                _kindleEngine?.jumpToPage(_startPage - 1);
                setState(() => _currentPage = _startPage);
                _isRestoringDone = true;
              } else {
                debugPrint('📍 Starting from page 1');
                _kindleEngine?.jumpToPage(0);
                setState(() => _currentPage = 1);
                _isRestoringDone = true;
              }
            });
          });
        },
        onTextSelected: (text, cfi, x, y) {
          debugPrint('📝 EPUB Text selected: "$text"');
          _selectedText = text;
          _selectedCfi = cfi;
          _showHighlightMenu(Offset(x, y));
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

  // ================= HIGHLIGHT MENU =================
  void _showHighlightMenu(Offset position) {
    _hideHighlightMenu();

    final screenWidth = MediaQuery.of(context).size.width;
    final menuX = (position.dx - 100).clamp(10.0, screenWidth - 170);
    final menuY = (position.dy - 60).clamp(10.0, MediaQuery.of(context).size.height - 100);

    _highlightMenu = OverlayEntry(
      builder: (context) => Positioned(
        left: menuX,
        top: menuY,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuButton(
                  icon: Icons.highlight,
                  label: 'Tô màu',
                  color: Colors.amber,
                  onTap: () => _onHighlightSelected(showNote: false),
                ),
                const SizedBox(width: 4),
                _buildMenuButton(
                  icon: Icons.note_add,
                  label: 'Ghi chú',
                  color: Colors.blue,
                  onTap: () => _onHighlightSelected(showNote: true),
                ),
                const SizedBox(width: 4),
                _buildMenuButton(
                  icon: Icons.close,
                  label: 'Hủy',
                  color: Colors.grey,
                  onTap: _hideHighlightMenu,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_highlightMenu!);
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }

  void _hideHighlightMenu() {
    _highlightMenu?.remove();
    _highlightMenu = null;
  }

  // 🔥 XỬ LÝ CHỌN HIGHLIGHT
  Future<void> _onHighlightSelected({required bool showNote}) async {
    _hideHighlightMenu();

    if (_selectedText == null || _selectedText!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn văn bản'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // 🔥 LƯU HIGHLIGHT VÀO DATABASE
    if (showNote) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddHighlightScreen(
            bookId: widget.bookId,
            cfi: _selectedCfi ?? '',
            text: _selectedText!,
          ),
        ),
      );
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lưu highlight và ghi chú'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      try {
        await _highlightService.addHighlight(
          bookId: widget.bookId,
          cfi: _selectedCfi ?? '',
          text: _selectedText!,
          color: '#FFD700',
          note: null,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã highlight đoạn văn'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ================= SAVE =================
  Future<void> _save() async {
    try {
      String? cfi;
      int currentPage = _currentPage;
      
      if (_kindleEngine != null) {
        cfi = _kindleEngine?.getCurrentCfi();
        currentPage = (_kindleEngine?.currentPage ?? 0) + 1;
      }

      debugPrint('📤 saveProgress: {bookId: ${widget.bookId}, trangHienTai: $currentPage, epubCfi: $cfi}');

      await _service.saveProgress(
        bookId: widget.bookId,
        trangHienTai: currentPage,
        epubCfi: cfi ?? _latestCfi,
      );
      debugPrint('💾 Saved: page=$currentPage, cfi=${cfi ?? _latestCfi}');
    } catch (e) {
      debugPrint('❌ Save error: $e');
    }
  }

  // ================= SAVE SESSION KHI THOÁT =================
// ================= SAVE SESSION KHI THOÁT =================
void _saveOnExit() {
  _save();
  
  // 🔥 TÍNH THỜI GIAN ĐỌC
  if (_sessionStart != null) {
    final now = DateTime.now();
    final duration = now.difference(_sessionStart!);
    final minutes = duration.inMinutes;
    
    // 🔥 CHỈ LƯU NẾU ĐỌC > 1 PHÚT
    if (minutes >= 1 && _startPage > 0) {
      final endPage = _currentPage > _startPage ? _currentPage : _startPage + 1;
      // 🔥 SỬA: _readingService -> _service
      _service.saveSession(
        bookId: widget.bookId,
        startPage: _startPage,
        endPage: endPage,
        minutes: minutes,
      );
      debugPrint('⏱️ Session saved: $minutes minutes, pages: $_startPage -> $endPage');
    }
  }
}

@override
void dispose() {
  _debounce?.cancel();
  _saveOnExit();
  _kindleEngine?.dispose();
  _hideHighlightMenu();
  // _hintTimer?.cancel(); // Bỏ comment nếu có
  super.dispose();
}
  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _save);
  }

  // ================= PDF =================
  // ================= PDF =================
Widget _buildPdf() {
  if (_localPdfPath == null) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF4A5D4E)),
          SizedBox(height: 16),
          Text('Đang tải PDF...'),
        ],
      ),
    );
  }

  return Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: AppBar(
      title: Text(widget.bookTitle ?? 'Đọc sách'),
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Colors.black,
      actions: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => _showGoToDialog(),
              child: Text(
                _totalPages > 0 ? "Trang $_currentPage" : "Đang tải...",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    ),
    body: Stack(
      children: [
        SfPdfViewer.file(
          File(_localPdfPath!),
          controller: _pdfController,
          scrollDirection: PdfScrollDirection.horizontal,
          pageSpacing: 0,
          canShowPaginationDialog: false,
          canShowScrollHead: false,
          enableTextSelection: true,
          onDocumentLoaded: (details) {
            debugPrint('✅ PDF loaded, pages: ${details.document.pages.count}');
            setState(() {
              _totalPages = details.document.pages.count;
            });
            if (_currentPage > 1) {
              _pdfController.jumpToPage(_currentPage);
            }
          },
          onDocumentLoadFailed: (details) {
            debugPrint('❌ PDF load failed: $details');
            setState(() {
              _errorMessage = 'Không thể đọc file PDF.';
            });
          },
          onPageChanged: (details) {
            debugPrint('📄 Page changed: ${details.newPageNumber}');
            setState(() {
              _currentPage = details.newPageNumber;
            });
            _scheduleSave();
          },
          onTextSelectionChanged: (details) {
            final text = details.selectedText;
            if (text != null && text.isNotEmpty) {
              _selectedText = text;
              _selectedCfi = 'pdf_page_$_currentPage';
              
              // 🔥 LẤY VỊ TRÍ TỪ selectedTextBounds (NẾU CÓ)
              double x = 100;
              double y = 100;
              try {
                // Sử dụng reflection hoặc kiểm tra runtime
                final dynamic detailsDynamic = details;
                if (detailsDynamic.selectedTextBounds != null) {
                  final bounds = detailsDynamic.selectedTextBounds;
                  if (bounds is List && bounds.isNotEmpty) {
                    final rect = bounds.first;
                    x = rect.left + rect.width / 2;
                    y = rect.top - 10;
                  }
                }
              } catch (e) {
                // Fallback: giữa màn hình
                final screenWidth = MediaQuery.of(context).size.width;
                final screenHeight = MediaQuery.of(context).size.height;
                x = screenWidth / 2;
                y = screenHeight / 2 - 50;
              }
              
              _showHighlightMenu(Offset(x, y));
            } else {
              _hideHighlightMenu();
            }
          },
        ),
        _buildNavigationButtons(),
        _buildFloatingButtons(),
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
        title: Text(widget.bookTitle ?? 'Đọc sách'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
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
          _buildFloatingButtons(),
        ],
      ),
    );
  }

  // ================= FLOATING BUTTONS =================
  Widget _buildFloatingButtons() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔥 NÚT XEM HIGHLIGHT
          FloatingActionButton.small(
            heroTag: 'highlight_btn',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HighlightListScreen(bookId: widget.bookId),
                ),
              );
            },
            backgroundColor: Colors.amber,
            child: const Icon(Icons.highlight, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          // 🔥 NÚT THÊM GHI CHÚ
          FloatingActionButton.small(
            heroTag: 'note_btn',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddNoteScreen(bookId: widget.bookId),
                ),
              );
              if (result == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Đã thêm ghi chú'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            backgroundColor: Colors.blue,
            child: const Icon(Icons.note_add, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          // 🔥 NÚT XEM GHI CHÚ
          FloatingActionButton.small(
            heroTag: 'list_btn',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NoteListScreen(
                    book: BookModel(
                      id: widget.bookId,
                      tieuDe: widget.bookTitle ?? 'Sách',
                      tacGia: '',
                      tongSoTrang: 0,
                    ),
                  ),
                ),
              );
            },
            backgroundColor: const Color(0xFF4A5D4E),
            child: const Icon(Icons.list, color: Colors.white, size: 20),
          ),
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
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  _init();
                },
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.loaiFile.toUpperCase() == 'PDF' ? _buildPdf() : _buildEpub();
  }
}