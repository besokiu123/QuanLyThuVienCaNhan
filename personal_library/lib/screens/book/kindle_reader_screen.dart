import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:html/parser.dart' as html_parser;

import 'reader_engine.dart';

class KindleEpubEngine implements ReaderEngine {
  final String url;
  final Function(int)? onPageChanged;
  final Function(int)? onLoaded;
  final Function(String, String, double, double)? onTextSelected;

  late InAppWebViewController webController;
  List<String> pages = [];
  int currentPage = 0;
  bool _isLoading = false;
  bool _isOpened = false;
  bool _isRestoring = false;
  bool _isFirstLoad = true;

  KindleEpubEngine(
    this.url, {
    this.onPageChanged,
    this.onLoaded,
    this.onTextSelected,
  });

  int get pageCount => pages.length;

  String? getCurrentCfi() {
    if (pages.isEmpty) return null;
    return 'epubcfi(/6/24!/4/${currentPage + 1})';
  }

  void goToCfi(String cfi) {
    try {
      debugPrint('📍 goToCfi: $cfi');
      _isRestoring = true;
      
      final match = RegExp(r'!/4/(\d+)').firstMatch(cfi);
      if (match != null) {
        final page = int.parse(match.group(1)!) - 1;
        debugPrint('📍 Parsed page: $page');
        if (page >= 0 && page < pages.length) {
          jumpToPage(page);
          _isRestoring = false;
          return;
        }
      }
      
      _isRestoring = false;
      debugPrint('⚠️ Cannot parse CFI: $cfi');
    } catch (e) {
      _isRestoring = false;
      debugPrint('❌ goToCfi error: $e');
    }
  }

  Future<Map<String, dynamic>?> getSelectedText() async {
    if (webController == null) return null;
    try {
      final result = await webController.evaluateJavascript(
        source: '''
          (function() {
            const selection = window.getSelection();
            if (!selection || selection.toString().trim().length === 0) {
              return null;
            }
            
            const range = selection.getRangeAt(0);
            const text = selection.toString();
            
            const rect = range.getBoundingClientRect();
            const x = rect.left + rect.width / 2;
            const y = rect.top - 10;
            
            const timestamp = Date.now();
            const cfi = 'epubcfi(/6/24!/4/\${timestamp % 10000})';
            
            return {
              text: text,
              cfi: cfi,
              x: x,
              y: y
            };
          })();
        ''',
      );
      
      if (result != null && result is Map) {
        return {
          'text': result['text'] as String,
          'cfi': result['cfi'] as String,
          'x': result['x'] as double? ?? 100,
          'y': result['y'] as double? ?? 100,
        };
      }
      return null;
    } catch (e) {
      debugPrint('❌ Get selected text error: $e');
      return null;
    }
  }

  List<String> _getOrderedFilesFromOpf(String opfContent) {
    List<String> orderedFiles = [];
    
    try {
      List<String> idrefs = [];
      final spineMatch = RegExp(r'<spine[^>]*>(.*?)</spine>', dotAll: true).firstMatch(opfContent);
      if (spineMatch != null) {
        final spineContent = spineMatch.group(1)!;
        final idrefMatches = RegExp(r'idref="([^"]+)"').allMatches(spineContent);
        for (final match in idrefMatches) {
          idrefs.add(match.group(1)!);
        }
      }
      
      Map<String, String> idToHref = {};
      final manifestMatch = RegExp(r'<manifest[^>]*>(.*?)</manifest>', dotAll: true).firstMatch(opfContent);
      if (manifestMatch != null) {
        final manifestContent = manifestMatch.group(1)!;
        final itemMatches = RegExp(r'<item[^>]+id="([^"]+)"[^>]+href="([^"]+)"').allMatches(manifestContent);
        for (final match in itemMatches) {
          idToHref[match.group(1)!] = match.group(2)!;
        }
      }
      
      for (final idref in idrefs) {
        final href = idToHref[idref];
        if (href != null) {
          orderedFiles.add(href);
        }
      }
    } catch (e) {
      debugPrint('❌ Parse OPF error: $e');
    }
    
    return orderedFiles;
  }

  ArchiveFile? _findFileByName(Archive archive, String fileName) {
    final nameOnly = fileName.split('/').last;
    
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final filePath = file.name;
      final fileNameOnly = filePath.split('/').last;
      
      if (fileNameOnly.toLowerCase() == nameOnly.toLowerCase()) {
        return file;
      }
    }
    
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final filePath = file.name;
      final fileNameOnly = filePath.split('/').last;
      
      if (fileNameOnly.toLowerCase().contains(nameOnly.toLowerCase())) {
        return file;
      }
    }
    
    return null;
  }

  @override
  Future<void> open() async {
    if (_isOpened) return;
    
    try {
      debugPrint('📖 Opening EPUB from: $url');
      
      final res = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = List<int>.from(res.data);
      final archive = ZipDecoder().decodeBytes(bytes);
      pages.clear();

      String? opfContent;
      
      for (final file in archive.files) {
        if (!file.isFile) continue;
        final name = file.name.toLowerCase();
        if (name.endsWith('.opf')) {
          opfContent = utf8.decode(file.content);
          debugPrint('📄 Found OPF file: ${file.name}');
          break;
        }
      }

      List<String> orderedFiles = [];
      
      if (opfContent != null && opfContent.isNotEmpty) {
        orderedFiles = _getOrderedFilesFromOpf(opfContent);
        debugPrint('📄 Found ${orderedFiles.length} files from OPF');
      }
      
      if (orderedFiles.isEmpty) {
        for (final file in archive.files) {
          if (!file.isFile) continue;
          final name = file.name.toLowerCase();
          if (name.endsWith('.xhtml') || 
              name.endsWith('.html') || 
              name.endsWith('.htm')) {
            orderedFiles.add(file.name);
          }
        }
        orderedFiles.sort();
        debugPrint('📄 Found ${orderedFiles.length} files (sorted)');
      }

      const int maxCharsPerPage = 2800;
      int fileProcessed = 0;
      
      for (final filePath in orderedFiles) {
        try {
          ArchiveFile? file = _findFileByName(archive, filePath);
          
          if (file == null) {
            file = archive.findFile(filePath);
          }
          
          if (file == null) {
            final altPath = filePath.replaceAll('Text/', '');
            file = _findFileByName(archive, altPath);
          }
          
          if (file == null) {
            debugPrint('⚠️ File not found: $filePath');
            continue;
          }
          
          fileProcessed++;
          final content = utf8.decode(file.content);
          final document = html_parser.parse(content);
          
          String bodyHtml = '';
          try {
            if (document.body != null) {
              bodyHtml = document.body!.outerHtml;
            }
          } catch (e) {
            debugPrint('⚠️ Error parsing body: $e');
          }
          
          if (bodyHtml.isEmpty) {
            bodyHtml = content;
          }
          
          String cleanContent = bodyHtml
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          
          if (cleanContent.isEmpty) {
            final text = document.body?.text ?? '';
            if (text.isNotEmpty) {
              cleanContent = '<p>${text.replaceAll('\n', '<br>')}</p>';
            }
          }
          
          if (cleanContent.isNotEmpty) {
            if (cleanContent.length <= maxCharsPerPage) {
              pages.add(cleanContent);
            } else {
              final parts = cleanContent.split(RegExp(r'(?=</?p>|</?div>|</?section>|</?h[1-6]>)'));
              String currentPage = '';
              
              for (String part in parts) {
                final trimmed = part.trim();
                if (trimmed.isEmpty) continue;
                
                if (currentPage.length + trimmed.length > maxCharsPerPage && currentPage.isNotEmpty) {
                  pages.add(currentPage);
                  currentPage = '';
                }
                currentPage += trimmed;
              }
              
              if (currentPage.isNotEmpty) {
                pages.add(currentPage);
              }
            }
          }
        } catch (e) {
          debugPrint('❌ Error reading file $filePath: $e');
        }
      }

      debugPrint('📄 Processed $fileProcessed files');

      if (pages.isEmpty) {
        debugPrint('⚠️ No content found, showing fallback');
        pages.add('<h1>Không có nội dung</h1><p>Không thể đọc file EPUB này</p>');
      }

      debugPrint('✅ Total pages: ${pages.length}');
      _isOpened = true;
      _isFirstLoad = true;
      onLoaded?.call(pages.length);
    } catch (e) {
      debugPrint('❌ Open EPUB error: $e');
      pages = ['<h1>Lỗi</h1><p>Không thể mở file EPUB: $e</p>'];
      _isOpened = true;
      rethrow;
    }
  }

  @override
  void jumpToPage(int page) {
    if (page < 0 || page >= pages.length) return;
    debugPrint('📄 jumpToPage: $page (current: $currentPage)');
    currentPage = page;
    if (webController != null) {
      _loadCurrentPage();
    } else {
      debugPrint('⏳ WebView not ready, page set to $page');
    }
  }

  Future<void> _loadCurrentPage() async {
    if (pages.isEmpty) return;
    if (_isLoading) return;
    _isLoading = true;

    final pageNum = currentPage + 1;
    final totalPages = pages.length;
    
    debugPrint('📄 Loading page $pageNum / $totalPages');

    // 🔥 THÊM JAVASCRIPT HỖ TRỢ CẢ CHUỘT VÀ TOUCH
    final html = '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
* { 
  user-select: text; 
  -webkit-user-select: text; 
  -moz-user-select: text; 
  -ms-user-select: text;
  -webkit-touch-callout: none;
}
body {
  background: #F8F4EA;
  color: #222;
  font-size: 20px;
  line-height: 1.8;
  padding: 20px 16px;
  max-width: 800px;
  margin: auto;
  font-family: Georgia, serif;
  min-height: 100vh;
  -webkit-tap-highlight-color: transparent;
}
img { max-width: 100%; height: auto; }
h1, h2, h3, h4, h5, h6 { margin-top: 20px; margin-bottom: 10px; }
p { margin-bottom: 10px; }
blockquote { border-left: 4px solid #ccc; padding-left: 16px; margin-left: 8px; }
::selection {
  background: #FFD700;
  color: #222;
}
</style>
<script>
  // 🔥 BIẾN THEO DÕI TRẠNG THÁI
  var isSelecting = false;
  var startX = 0;
  var startY = 0;
  var selectionTimeout = null;
  
  // 🔥 HÀM GỬI TEXT SELECTION LÊN FLUTTER
  function sendSelection() {
    const selection = window.getSelection();
    if (selection && selection.toString().trim().length > 0) {
      try {
        const range = selection.getRangeAt(0);
        const rect = range.getBoundingClientRect();
        
        window.flutter_inappwebview.callHandler('onTextSelected', {
          text: selection.toString().trim(),
          cfi: 'epubcfi(/6/24!/4/' + Date.now() + ')',
          x: rect.left + rect.width / 2,
          y: rect.top - 10
        });
      } catch(e) {
        console.log('Selection error:', e);
      }
    }
  }
  
  // 🔥 CÁCH 1: CLICK VÀ KÉO (CHO MÁY ẢO)
  document.addEventListener('mousedown', function(e) {
    isSelecting = true;
    startX = e.clientX;
    startY = e.clientY;
  });
  
  document.addEventListener('mouseup', function(e) {
    if (isSelecting) {
      isSelecting = false;
      const dx = e.clientX - startX;
      const dy = e.clientY - startY;
      const distance = Math.sqrt(dx*dx + dy*dy);
      
      // Nếu kéo > 10px, coi như chọn text
      if (distance > 10) {
        setTimeout(sendSelection, 100);
      }
    }
  });
  
  // 🔥 CÁCH 2: TOUCH VÀ KÉO (CHO ĐIỆN THOẠI)
  var touchStartX = 0;
  var touchStartY = 0;
  var isTouching = false;
  
  document.addEventListener('touchstart', function(e) {
    isTouching = true;
    const touch = e.touches[0];
    touchStartX = touch.clientX;
    touchStartY = touch.clientY;
  }, { passive: true });
  
  document.addEventListener('touchend', function(e) {
    if (isTouching) {
      isTouching = false;
      const touch = e.changedTouches[0];
      const dx = touch.clientX - touchStartX;
      const dy = touch.clientY - touchStartY;
      const distance = Math.sqrt(dx*dx + dy*dy);
      
      // Nếu kéo > 10px, coi như chọn text
      if (distance > 10) {
        setTimeout(sendSelection, 200);
      }
    }
  }, { passive: true });
  
  // 🔥 CÁCH 3: LONG PRESS (CHO ĐIỆN THOẠI)
  var longPressTimer = null;
  
  document.addEventListener('touchstart', function(e) {
    longPressTimer = setTimeout(function() {
      // Long press detected
      const selection = window.getSelection();
      if (selection && selection.toString().trim().length > 0) {
        sendSelection();
      }
    }, 500);
  }, { passive: true });
  
  document.addEventListener('touchend', function(e) {
    if (longPressTimer) {
      clearTimeout(longPressTimer);
      longPressTimer = null;
    }
  }, { passive: true });
  
  document.addEventListener('touchmove', function(e) {
    if (longPressTimer) {
      clearTimeout(longPressTimer);
      longPressTimer = null;
    }
  }, { passive: true });
  
  // 🔥 CÁCH 4: SELECTION CHANGE (FALLBACK)
  document.addEventListener('selectionchange', function() {
    const selection = window.getSelection();
    if (selection && selection.toString().trim().length > 0) {
      // Clear previous timeout
      if (selectionTimeout) {
        clearTimeout(selectionTimeout);
      }
      // Gửi sau 200ms để tránh gửi nhiều lần
      selectionTimeout = setTimeout(sendSelection, 200);
    }
  });
  
  window.addEventListener('load', function() {
    window.flutter_inappwebview.callHandler('onPageLoaded', $pageNum, $totalPages);
  });
</script>
</head>
<body>
${pages[currentPage]}
</body>
</html>
''';

    try {
      await webController.loadData(
        data: html,
        mimeType: "text/html",
        encoding: "utf-8",
      );
      _isLoading = false;
      
      if (!_isRestoring && !_isFirstLoad) {
        onPageChanged?.call(currentPage);
      } else if (_isFirstLoad) {
        _isFirstLoad = false;
        onPageChanged?.call(currentPage);
      }
    } catch (e) {
      _isLoading = false;
      debugPrint('❌ Load page error: $e');
    }
  }

  @override
  Widget buildView() {
    return InAppWebView(
      initialSettings: InAppWebViewSettings(
        transparentBackground: false,
        javaScriptEnabled: true,
        domStorageEnabled: true,
        allowsInlineMediaPlayback: true,
        userAgent: 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
        cacheEnabled: true,
        supportZoom: true,
        useShouldInterceptAjaxRequest: true,
      ),
      onWebViewCreated: (controller) {
        webController = controller;
        debugPrint('✅ WebView created');
        
        controller.addJavaScriptHandler(
          handlerName: 'onTextSelected',
          callback: (args) {
            if (args.isNotEmpty && args.first is Map) {
              final data = args.first as Map;
              final text = data['text'] as String?;
              final cfi = data['cfi'] as String? ?? '';
              final x = (data['x'] as num?)?.toDouble() ?? 100;
              final y = (data['y'] as num?)?.toDouble() ?? 100;
              
              if (text != null && text.isNotEmpty && onTextSelected != null) {
                debugPrint('📝 EPUB Text selected: "${text.substring(0, text.length > 30 ? 30 : text.length)}..."');
                onTextSelected!(text, cfi, x, y);
              }
            }
            return null;
          },
        );
        
        controller.addJavaScriptHandler(
          handlerName: 'onPageLoaded',
          callback: (args) {
            if (args.isNotEmpty) {
              final pageNum = args.first as int?;
              if (pageNum != null && pageNum > 0) {
                final newPage = pageNum - 1;
                debugPrint('📄 Page loaded from JS: $pageNum / ${pages.length}');
                
                if (newPage != currentPage && !_isRestoring) {
                  currentPage = newPage;
                  if (!_isFirstLoad) {
                    onPageChanged?.call(currentPage);
                  }
                } else if (_isRestoring) {
                  currentPage = newPage;
                  _isRestoring = false;
                }
              }
            }
            return null;
          },
        );
        
        if (_isOpened && pages.isNotEmpty) {
          _loadCurrentPage();
        }
      },
      onLoadError: (controller, url, code, message) {
        debugPrint('❌ WebView error: $code - $message');
      },
      onLoadStop: (controller, url) {
        debugPrint('✅ WebView loaded');
      },
      onRenderProcessGone: (controller, details) async {
        debugPrint('⚠️ Renderer process crashed! Trying to reload...');
        _loadCurrentPage();
      },
    );
  }

  @override
  void nextPage() {
    if (currentPage >= pages.length - 1) {
      debugPrint('📄 Already at last page');
      return;
    }
    debugPrint('📄 Next page: ${currentPage + 1} -> ${currentPage + 2}');
    currentPage++;
    _loadCurrentPage();
  }

  @override
  void prevPage() {
    if (currentPage <= 0) {
      debugPrint('📄 Already at first page');
      return;
    }
    debugPrint('📄 Prev page: ${currentPage + 1} -> $currentPage');
    currentPage--;
    _loadCurrentPage();
  }

  @override
  int getProgress() {
    return currentPage;
  }

  @override
  void setProgress(dynamic value) {
    if (value is int) {
      jumpToPage(value);
    }
  }

  @override
  void dispose() {
    webController.dispose();
  }
}