import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fa_ai_agent/widgets/loading_spinner.dart';
import 'package:fa_ai_agent/widgets/error_display.dart';
import 'package:fa_ai_agent/constants/layout_constants.dart';
import 'package:fa_ai_agent/gradient_text.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportBuilder extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final String title;
  final String reportKey;
  final bool showTitle;
  final Function(DateTime) onCacheTimeUpdate;

  const ReportBuilder({
    super.key,
    required this.future,
    required this.title,
    required this.reportKey,
    this.showTitle = true,
    required this.onCacheTimeUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder:
          (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final Map<String, dynamic> data = snapshot.data ?? {};
          if (data.isEmpty) {
            return ErrorDisplayWidget(
                errorMessage: "Failed to load $reportKey");
          }
          final int cachedTimestamp = data["cachedAt"];
          final DateTime cacheTime =
              DateTime.fromMicrosecondsSinceEpoch(cachedTimestamp);
          onCacheTimeUpdate(cacheTime);
          final Map<String, dynamic> payload = data[reportKey];
          final String markdown = payload["md"] ?? "";
          if (markdown.isEmpty) {
            return ErrorDisplayWidget(
                errorMessage: "Unable to find any content on $reportKey");
          }
          final markdownWithNoHeading = markdown.replaceAll("## $title", "");

          final markdownBody = MarkdownBody(
            data: markdownWithNoHeading,
            selectable: true,
            onTapLink: (text, href, title) async {
              if (href != null) {
                final uri = Uri.parse(href);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.platformDefault);
                }
              }
            },
            styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF1F2937),
              ),
              blockquote: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
                fontSize: 16,
                height: 1.6,
              ),
              code: TextStyle(
                fontFamily: 'Menlo',
                fontSize: 14,
                color: Colors.blue.shade800,
                backgroundColor: Colors.grey.shade100,
              ),
              h1: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3A8A),
                height: 1.4,
              ),
              h2: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
                height: 1.4,
              ),
              h3: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
                height: 1.4,
              ),
              a: TextStyle(
                color: Colors.blue.shade700,
                decoration: TextDecoration.underline,
              ),
              tableHead: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
                fontSize: 14,
              ),
              tableBody: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
              tableBorder: TableBorder.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              tableCellsPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              tableColumnWidth: const FlexColumnWidth(),
            ),
          );

          if (!showTitle) {
            return markdownBody;
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: LayoutConstants.maxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    gradientTitle(title, 35),
                    const SizedBox(height: 24),
                    markdownBody,
                  ],
                ),
              ),
            ),
          );
        } else {
          final loadingSpinner = LoadingSpinner();
          if (!showTitle) {
            return loadingSpinner;
          }
          return Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: LayoutConstants.maxWidth,
              ),
              child: loadingSpinner,
            ),
          );
        }
      },
    );
  }
}
