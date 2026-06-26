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

  late InAppWebViewController webController;
  List<String> pages = [];
  int currentPage = 0;
  bool _isLoading = false;
  bool _isOpened = false;

  KindleEpubEngine(
    this.url, {
    this.onPageChanged,
    this.onLoaded,
  });

  int get pageCount => pages.length;

  // 🔥 THÊM: Lấy CFI hiện tại
  String? getCurrentCfi() {
    if (pages.isEmpty) return null;
    // Tạo CFI đơn giản từ số trang hiện tại
    return 'epubcfi(/6/24!/4/${currentPage + 1})';
  }

  // 🔥 THÊM: Đi đến vị trí từ CFI
  void goToCfi(String cfi) {
    try {
      debugPrint('📍 goToCfi: $cfi');
      
      // Cách 1: Lấy số trang từ CFI
      // epubcfi(/6/24!/4/10) -> lấy số 10
      final match = RegExp(r'!/4/(\d+)').firstMatch(cfi);
      if (match != null) {
        final page = int.parse(match.group(1)!) - 1;
        debugPrint('📍 Parsed page: $page');
        if (page >= 0 && page < pages.length) {
          jumpToPage(page);
          return;
        }
      }
      
      // Cách 2: Lấy số cuối cùng trong CFI
      final match2 = RegExp(r'/(\d+)(?!.*/)').firstMatch(cfi);
      if (match2 != null) {
        final page = int.parse(match2.group(1)!) - 1;
        debugPrint('📍 Parsed page (fallback): $page');
        if (page >= 0 && page < pages.length) {
          jumpToPage(page);
          return;
        }
      }
      
      debugPrint('⚠️ Cannot parse CFI: $cfi');
    } catch (e) {
      debugPrint('❌ goToCfi error: $e');
    }
  }

  @override
  Future<void> open() async {
    if (_isOpened) return;
    
    try {
      final res = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = List<int>.from(res.data);
      final archive = ZipDecoder().decodeBytes(bytes);
      pages.clear();

      for (final file in archive.files) {
        if (!file.isFile) continue;
        final name = file.name.toLowerCase();

        if (name.endsWith('.xhtml') ||
            name.endsWith('.html') ||
            name.endsWith('.htm')) {
          final html = utf8.decode(file.content);
          final document = html_parser.parse(html);
          
          final body = document.body;
          if (body != null) {
            final paragraphs = body.querySelectorAll('p, div, h1, h2, h3, h4, h5, h6');
            
            if (paragraphs.isNotEmpty) {
              String currentPage = '';
              int charCount = 0;
              const int maxCharsPerPage = 3000;
              
              for (final element in paragraphs) {
                final text = element.text.trim();
                if (text.isEmpty) continue;
                
                final htmlContent = element.outerHtml;
                if (charCount + text.length > maxCharsPerPage && currentPage.isNotEmpty) {
                  pages.add(currentPage);
                  currentPage = '';
                  charCount = 0;
                }
                currentPage += htmlContent;
                charCount += text.length;
              }
              
              if (currentPage.isNotEmpty) {
                pages.add(currentPage);
              }
            } else {
              final text = body.text;
              const int charsPerPage = 3000;
              for (int i = 0; i < text.length; i += charsPerPage) {
                final end = (i + charsPerPage > text.length) ? text.length : i + charsPerPage;
                pages.add('<p>${text.substring(i, end)}</p>');
              }
            }
          }
        }
      }

      if (pages.isEmpty) {
        pages.add('<h1>Không có nội dung</h1><p>Không thể đọc file EPUB này</p>');
      }

      _isOpened = true;
      onLoaded?.call(pages.length);
    } catch (e) {
      pages = ['<h1>Lỗi</h1><p>Không thể mở file EPUB: $e</p>'];
      _isOpened = true;
      rethrow;
    }
  }

  @override
  void jumpToPage(int page) {
    if (page < 0 || page >= pages.length) return;
    currentPage = page;
    _loadCurrentPage();
  }

  Future<void> _loadCurrentPage() async {
    if (pages.isEmpty) return;
    if (_isLoading) return;
    _isLoading = true;

    final html = '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
body {
  background: #F8F4EA;
  color: #222;
  font-size: 22px;
  line-height: 1.8;
  padding: 24px 20px;
  max-width: 800px;
  margin: auto;
  font-family: Georgia, serif;
  min-height: 100vh;
}
img {
  max-width: 100%;
  height: auto;
}
h1, h2, h3, h4, h5, h6 {
  margin-top: 24px;
  margin-bottom: 12px;
}
p {
  margin-bottom: 12px;
}
blockquote {
  border-left: 4px solid #ccc;
  padding-left: 16px;
  margin-left: 8px;
}
</style>
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
      onPageChanged?.call(currentPage);
    } catch (e) {
      _isLoading = false;
      rethrow;
    }
  }

  @override
  Widget buildView() {
    return InAppWebView(
      initialSettings: InAppWebViewSettings(
        transparentBackground: false,
        javaScriptEnabled: true,
        domStorageEnabled: true,
      ),
      onWebViewCreated: (controller) {
        webController = controller;
        if (_isOpened) {
          _loadCurrentPage();
        }
      },
      onLoadError: (controller, url, code, message) {
        debugPrint('WebView error: $code - $message');
      },
    );
  }

  @override
  void nextPage() {
    if (currentPage >= pages.length - 1) return;
    currentPage++;
    _loadCurrentPage();
  }

  @override
  void prevPage() {
    if (currentPage <= 0) return;
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
    // Clean up
  }
}