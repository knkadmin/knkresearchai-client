import 'package:flutter/material.dart';
import 'package:fa_ai_agent/widgets/loading_spinner.dart';
import 'package:fa_ai_agent/widgets/error_display.dart';
import 'package:fa_ai_agent/widgets/chart_image.dart';
import 'package:fa_ai_agent/widgets/image_viewer.dart';
import 'package:fa_ai_agent/constants/layout_constants.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:convert' as convert;
import 'package:fa_ai_agent/gradient_text.dart';

class ChartBuilder extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final String chartKey;
  final Widget? cachedImage;
  final String? cachedEncodedImage;
  final Function(Widget, String) onImageCached;
  final String title;
  final bool showTitle;

  const ChartBuilder({
    super.key,
    required this.future,
    required this.chartKey,
    this.cachedImage,
    this.cachedEncodedImage,
    required this.onImageCached,
    required this.title,
    this.showTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    if (cachedImage != null && cachedEncodedImage != null) {
      return Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth > LayoutConstants.maxWidth
                  ? LayoutConstants.maxWidth
                  : constraints.maxWidth,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showTitle) ...[
                      gradientTitle(title, 35),
                      const SizedBox(height: 16),
                    ],
                    ChartImage(
                      image: cachedImage!,
                      encodedImage: cachedEncodedImage!,
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder(
                      future: future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          final Map<String, dynamic> data = snapshot.data ?? {};
                          final Map<String, dynamic> payload = data[chartKey];
                          final String? markdown = payload['md'];

                          if (markdown != null && markdown.isNotEmpty) {
                            return Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(minHeight: 50),
                              child: MarkdownBody(
                                data: markdown,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF475569),
                                    height: 1.6,
                                  ),
                                  strong: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                  em: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                  blockquote: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  code: const TextStyle(
                                    backgroundColor: Color(0xFFF8FAFC),
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                  ),
                                  codeblockDecoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return FutureBuilder(
      future: future,
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final Map<String, dynamic> data = snapshot.data ?? {};
          if (data.isEmpty) {
            return ErrorDisplayWidget(errorMessage: "Failed to load $chartKey");
          }
          final Map<String, dynamic> payload = data[chartKey];
          final String imageEncodedString = payload['base64'] ?? "";
          final String? markdown = payload['md'];

          final decodedImage = convert.base64.decode(imageEncodedString);
          final image = Image.memory(
            decodedImage,
            cacheWidth: LayoutConstants.maxWidth.toInt(),
            filterQuality: FilterQuality.high,
          );

          // Create a high resolution version for the viewer without size constraints
          final highResImage = Image.memory(
            decodedImage,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            fit: BoxFit.contain,
            isAntiAlias: true,
            cacheWidth: null, // Remove size constraints
            cacheHeight: null, // Remove size constraints
          );

          // Cache the image widget and encoded string
          onImageCached(image, imageEncodedString);

          return Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: constraints.maxWidth > LayoutConstants.maxWidth
                      ? LayoutConstants.maxWidth
                      : constraints.maxWidth,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showTitle) ...[
                          gradientTitle(title, 35),
                          const SizedBox(height: 16),
                        ],
                        ChartImage(
                          image: image,
                          encodedImage: imageEncodedString,
                        ),
                        if (markdown != null && markdown.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 50),
                            child: MarkdownBody(
                              data: markdown,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF475569),
                                  height: 1.6,
                                ),
                                strong: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                                em: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                                blockquote: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontStyle: FontStyle.italic,
                                ),
                                code: const TextStyle(
                                  backgroundColor: Color(0xFFF8FAFC),
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                ),
                                codeblockDecoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }

        return Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: constraints.maxWidth > LayoutConstants.maxWidth
                    ? LayoutConstants.maxWidth
                    : constraints.maxWidth,
                child: const LoadingSpinner(),
              );
            },
          ),
        );
      },
    );
  }
}
