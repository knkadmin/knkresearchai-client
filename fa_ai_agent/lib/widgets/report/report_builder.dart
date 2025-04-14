import 'package:flutter/material.dart';
import 'package:fa_ai_agent/widgets/animations/thinking_animation.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fa_ai_agent/constants/layout_constants.dart';

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
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.grey.shade200,
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(20),
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
          ),
        );

        // Notify parent widget that content has been built
        widget.onContentBuilt?.call(content);

        return content;
      },
    );
  }
}
