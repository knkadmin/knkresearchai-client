import 'package:flutter/material.dart';
import 'package:fa_ai_agent/widgets/loading_spinner.dart';
import 'package:fa_ai_agent/widgets/error_display.dart';
import 'package:fa_ai_agent/widgets/chart_image.dart';
import 'package:fa_ai_agent/widgets/image_viewer.dart';
import 'package:fa_ai_agent/constants/layout_constants.dart';
import 'dart:convert' as convert;

class ChartBuilder extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final String chartKey;
  final Widget? cachedImage;
  final String? cachedEncodedImage;
  final Function(Widget, String) onImageCached;

  const ChartBuilder({
    super.key,
    required this.future,
    required this.chartKey,
    this.cachedImage,
    this.cachedEncodedImage,
    required this.onImageCached,
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
              child: ChartImage(
                image: cachedImage!,
                encodedImage: cachedEncodedImage!,
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
                  child: ChartImage(
                    image: image,
                    encodedImage: imageEncodedString,
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
