import 'package:flutter/material.dart';

/// Zeigt ein Buch-Cover mit drehendem Ladekreis während das Bild lädt.
/// Wird in BarcodeSearchPage, IsbnSearchPage und HomePage wiederverwendet.
class BookCoverImage extends StatelessWidget {
  final String url;
  final double height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const BookCoverImage({
    super.key,
    required this.url,
    this.height = 180,
    this.width,
    this.fit = BoxFit.contain,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(8);

    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: height,
            width: width,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, _, __) => SizedBox(
          height: height,
          width: width,
          child: const ColoredBox(
            color: Color(0xFFF0F0F0),
            child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
