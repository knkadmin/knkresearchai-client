import 'package:flutter/material.dart';
import 'package:fa_ai_agent/widgets/animations/loading_spinner.dart';
import 'package:fa_ai_agent/widgets/error_display.dart';
import 'package:fa_ai_agent/widgets/report/chart_image.dart';
import 'package:fa_ai_agent/constants/layout_constants.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fa_ai_agent/gradient_text.dart';
import 'package:fa_ai_agent/utils/image_utils.dart';

class ChartBuilder extends StatefulWidget {
  final Stream<Map<String, dynamic>> stream;
  final String chartKey;
  final Widget? cachedImage;
  final String? cachedImageUrl;
  final Function(Widget, String) onImageCached;
  final Function(Widget)? onContentBuilt;
  final String title;
  final bool showTitle;

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

        final Map<String, dynamic> payload = data[widget.chartKey];
        if (payload == null) {
          return ErrorDisplayWidget(
              errorMessage: "No payload found for ${widget.chartKey}");
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

        // Load the image from URL
        return FutureBuilder<String>(
          future: ImageUtils.getSignedUrl(imageUrl),
          builder: (context, signedUrlSnapshot) {
            if (signedUrlSnapshot.connectionState == ConnectionState.waiting) {
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
    final content = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle) ...[
            gradientTitle(widget.title, 35),
            const SizedBox(height: 16),
          ],
          ChartImage(image: image),
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
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return content;
  }
}
