import 'package:flutter/material.dart';
import 'package:fa_ai_agent/widgets/animations/thinking_animation.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fa_ai_agent/constants/layout_constants.dart';
import 'package:fa_ai_agent/gradient_text.dart';

class ReportBuilder extends StatefulWidget {
  final Stream<Map<String, dynamic>> stream;
  final String title;
  final String reportKey;
  final bool showTitle;
  final Function(Widget)? onContentBuilt;

  const ReportBuilder({
    Key? key,
    required this.stream,
    required this.title,
    required this.reportKey,
    this.showTitle = true,
    this.onContentBuilt,
  }) : super(key: key);

  @override
  State<ReportBuilder> createState() => _ReportBuilderState();
}

class _ReportBuilderState extends State<ReportBuilder> {
  String _cleanMarkdown(String markdown, String title) {
    // Remove markdown headers that match the title
    final titlePattern =
        RegExp(r'^#+\s*' + RegExp.escape(title) + r'\s*$', multiLine: true);
    return markdown.replaceAll(titlePattern, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: widget.stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: ThinkingAnimation(
              size: 24,
              color: Color(0xFF1E3A8A),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading report: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text('No data available'),
          );
        }

        final data = snapshot.data!;
        final markdown = data[widget.reportKey]?['md'] as String?;

        if (markdown == null || markdown.isEmpty) {
          return const Center(
            child: Text('No content available'),
          );
        }

        // Clean the markdown content
        final cleanedMarkdown = _cleanMarkdown(markdown, widget.title);

        final content = Column(
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
                color: Colors.grey.shade200,
              ),
              const SizedBox(height: 8),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: MarkdownBody(
                data: cleanedMarkdown,
                styleSheet: MarkdownStyleSheet(
                  h1: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  h2: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                  h3: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.2,
                    height: 1.4,
                  ),
                  p: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF334155),
                    height: 1.8,
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
                    borderRadius: BorderRadius.circular(8),
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
                    fontSize: 15,
                  ),
                  tableBody: const TextStyle(
                    color: Color(0xFF334155),
                    fontSize: 14,
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
          ],
        );

        // Notify parent widget that content has been built
        widget.onContentBuilt?.call(content);

        return content;
      },
    );
  }
}
