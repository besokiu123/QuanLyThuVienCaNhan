import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../screens/book/book_detail_screen.dart';

class BookCardWidget extends StatelessWidget {
  final BookModel book;
  final bool showProgress;
  final double? progress;
  final VoidCallback? onTap;

  const BookCardWidget({
    super.key,
    required this.book,
    this.showProgress = false,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(book: book),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 ẢNH BÌA - Fixed height
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: book.anhBia != null
                    ? Image.network(
                        book.anhBia!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.book, size: 40, color: Colors.grey),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.book, size: 40, color: Colors.grey),
                      ),
              ),
            ),
            
            // 🔥 THÔNG TIN SÁCH - Flexible, không fixed height
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tiêu đề
                  Text(
                    book.tieuDe,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF222222),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  
                  // Tác giả
                  Text(
                    book.tacGia,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Loại file + số trang
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: (book.loaiFile?.toUpperCase() ?? 'PDF') == 'EPUB'
                              ? Colors.purple.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          book.loaiFile?.toUpperCase() ?? 'PDF',
                          style: TextStyle(
                            color: (book.loaiFile?.toUpperCase() ?? 'PDF') == 'EPUB'
                                ? Colors.purple[700]
                                : Colors.blue[700],
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${book.tongSoTrang} tr',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  
                  if (showProgress && progress != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress!.clamp(0.0, 1.0),
                        minHeight: 3,
                        backgroundColor: Colors.grey[200],
                        color: const Color(0xFF4A5D4E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}