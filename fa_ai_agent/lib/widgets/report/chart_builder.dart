import 'package:flutter/material.dart';
import 'package:fa_ai_agent/widgets/animations/loading_spinner.dart';
import 'package:fa_ai_agent/widgets/error_display.dart';
import 'package:fa_ai_agent/widgets/report/chart_image.dart';
import 'package:fa_ai_agent/constants/layout_constants.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fa_ai_agent/gradient_text.dart';
import 'package:fa_ai_agent/utils/image_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ChartBuilder extends StatefulWidget {
  final Stream<Map<String, dynamic>> stream;
  final String chartKey;
  final Widget? cachedImage;
  final String? cachedImageUrl;
  final Function(Widget, String) onImageCached;
  final Function(Widget)? onContentBuilt;
  final String title;
  final bool showTitle;

  // Static method to clear the signed URL cache
  static void clearSignedUrlCache() {
    _ChartBuilderState.clearSignedUrlCache();
  }

  const ChartBuilder({
    super.key,
    required this.stream,
    required this.chartKey,
    this.cachedImage,
    this.cachedImageUrl,
    required this.onImageCached,
    this.onContentBuilt,
    required this.title,
    this.showTitle = true,
  });

  @override
  State<ChartBuilder> createState() => _ChartBuilderState();
}

class _ChartBuilderState extends State<ChartBuilder> {
  // Static cache for signed URLs
  static final Map<String, String> _signedUrlCache = {};

  // Static method to clear the signed URL cache
  static void clearSignedUrlCache() {
    _signedUrlCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: widget.stream,
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.hasError) {
          return ErrorDisplayWidget(
              errorMessage:
                  "Error loading ${widget.chartKey}: ${snapshot.error}");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
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
        }

        if (!snapshot.hasData) {
          return ErrorDisplayWidget(
              errorMessage: "No data available for ${widget.chartKey}");
        }

        final Map<String, dynamic> data = snapshot.data!;
        if (data.isEmpty) {
          return ErrorDisplayWidget(
              errorMessage: "Failed to load ${widget.chartKey}");
        }

        final Map<String, dynamic>? payload = data[widget.chartKey];
        if (payload == null) {
          return const LoadingSpinner();
        }

        final String? imageUrl = payload['imageUrl'];
        final String? markdown = payload['md'];

        // If we have a cached image and URL, use them
        if (widget.cachedImage != null && widget.cachedImageUrl != null) {
          final content = _buildChartContent(
            context,
            widget.cachedImage! as Image,
            markdown,
          );
          widget.onContentBuilt?.call(content);
          return content;
        }

        // If no image URL is available, show error
        if (imageUrl == null || imageUrl.isEmpty) {
          return ErrorDisplayWidget(
              errorMessage: "No image URL found for ${widget.chartKey}");
        }

        // Check if we have a cached signed URL
        final String? cachedSignedUrl = _signedUrlCache[imageUrl];
        if (cachedSignedUrl != null) {
          final Image image = Image.network(
            cachedSignedUrl,
            cacheWidth: LayoutConstants.maxWidth.toInt(),
            filterQuality: FilterQuality.high,
          );
          final content = _buildChartContent(context, image, markdown);
          widget.onContentBuilt?.call(content);
          return content;
        }

        // Load the image from URL
        return FutureBuilder<String>(
          future: ImageUtils.getSignedUrl(imageUrl),
          builder: (context, signedUrlSnapshot) {
            if (signedUrlSnapshot.connectionState == ConnectionState.waiting) {
              // Show cached image if available while loading
              if (widget.cachedImage != null) {
                final content = _buildChartContent(
                  context,
                  widget.cachedImage! as Image,
                  markdown,
                );
                widget.onContentBuilt?.call(content);
                return content;
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
            }

            if (signedUrlSnapshot.hasError) {
              return ErrorDisplayWidget(
                  errorMessage:
                      "Error loading image: ${signedUrlSnapshot.error}");
            }

            final String signedUrl = signedUrlSnapshot.data!;
            // Cache the signed URL
            _signedUrlCache[imageUrl] = signedUrl;

            final Image image = Image.network(
              signedUrl,
              cacheWidth: LayoutConstants.maxWidth.toInt(),
              filterQuality: FilterQuality.high,
            );

            final content = _buildChartContent(context, image, markdown);
            widget.onContentBuilt?.call(content);
            return content;
          },
        );
      },
    );
  }

  Widget _buildChartContent(
      BuildContext context, Image image, String? markdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: gradientTitle(widget.title, 35),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
        ],
        ChartImage(image: image),
        if (markdown != null && markdown.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 50),
              child: MarkdownBody(
                data: markdown,
                onTapLink: (text, href, title) {
                  if (href != null) {
                    launchUrl(Uri.parse(href),
                        mode: LaunchMode.externalApplication);
                  }
                },
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                    height: 1.3,
                  ),
                  h2: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                    height: 1.4,
                  ),
                  h3: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.2,
                    height: 1.4,
                  ),
                  p: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF334155),
                    height: 1.7,
                    letterSpacing: 0.2,
                  ),
                  strong: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  em: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Color(0xFF475569),
                  ),
                  blockquote: const TextStyle(
                    color: Color(0xFF64748B),
                    fontStyle: FontStyle.italic,
                    fontSize: 15,
                    height: 1.6,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border(
                      left: BorderSide(
                        color: const Color(0xFFE2E8F0),
                        width: 4,
                      ),
                    ),
                  ),
                  code: const TextStyle(
                    backgroundColor: Color(0xFFF1F5F9),
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  listBullet: const TextStyle(
                    color: Color(0xFF1E293B),
                  ),
                  tableHead: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  tableBody: const TextStyle(
                    color: Color(0xFF334155),
                  ),
                  tableBorder: TableBorder.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  tableCellsPadding: const EdgeInsets.all(12),
                  tableCellsDecoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
