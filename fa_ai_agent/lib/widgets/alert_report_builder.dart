import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fa_ai_agent/widgets/thinking_animation.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:intl/intl.dart';
import 'package:fa_ai_agent/agent_service.dart';

class AlertReportBuilder extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final String title;
  final String reportKey;
  final Function(DateTime)? onCacheTimeUpdate;

  const AlertReportBuilder({
    Key? key,
    required this.future,
    required this.title,
    required this.reportKey,
    this.onCacheTimeUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, bool>>(
      stream: AgentService().loadingStateSubject.stream,
      builder: (context, loadingSnapshot) {
        final loadingStates = loadingSnapshot.data ?? {};
        final isLoading = loadingStates[reportKey] == true;

        return FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting ||
                isLoading) {
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
            print('API Response Data: $data'); // Debug log

            final markdown = data['accountingRedflags']?['md'] as String?;
            print('Extracted markdown: $markdown'); // Debug log

            // Count bullet points
            final bulletCount = markdown?.split('- ').length ?? 0;
            final isCritical = bulletCount > 5;
            final statusLabel = bulletCount == 0
                ? "No Issues"
                : (isCritical ? "Critical" : "Acceptable");
            final statusColor = bulletCount == 0
                ? const Color(0xFF1E3A8A)
                : (isCritical
                    ? const Color(0xFF991B1B)
                    : const Color(0xFF059669));
            final headerColor = bulletCount == 0
                ? const Color(0xFFF8FAFC)
                : const Color(0xFFFFF5F5);
            final borderColor =
                bulletCount == 0 ? Colors.blue.shade50 : Colors.red.shade50;

            final cacheTime = data['cachedAt'] != null
                ? DateTime.fromMicrosecondsSinceEpoch(data['cachedAt'])
                : null;

            if (cacheTime != null && onCacheTimeUpdate != null) {
              onCacheTimeUpdate!(cacheTime);
            }

            if (markdown == null || markdown.isEmpty) {
              print('No markdown content found in response'); // Debug log
              return const Center(
                child: Text('No content available'),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
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
                  _buildHeader(data),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: MarkdownBody(
                      data: markdown,
                      builders: {
                        'ul': UnorderedListBuilder(),
                        'ol': OrderedListBuilder(),
                      },
                      styleSheet: MarkdownStyleSheet(
                        h1: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF991B1B),
                        ),
                        h2: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF991B1B),
                        ),
                        h3: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF991B1B),
                        ),
                        p: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF475569),
                          height: 1.6,
                        ),
                        strong: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF991B1B),
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
          },
        );
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    final markdown = data['accountingRedflags']?['md'];
    final bulletCount = markdown?.split('- ').length ?? 0;
    final isCritical = bulletCount > 5;
    final statusLabel = bulletCount == 0
        ? "No Issues"
        : (isCritical ? "Critical" : "Acceptable");
    final statusColor = bulletCount == 0
        ? const Color(0xFF1E3A8A)
        : (isCritical ? const Color(0xFF991B1B) : const Color(0xFF059669));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bulletCount == 0 ? Colors.blue.shade50 : const Color(0xFFFFF5F5),
        border: Border(
          bottom: BorderSide(
            color: bulletCount == 0
                ? Colors.blue.shade100
                : const Color(0xFFFFE5E5),
          ),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                bulletCount == 0
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: statusColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: statusColor.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: bulletCount == 0
                        ? Colors.blue.shade50
                        : const Color(0xFFFFE5E5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.update_rounded,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Last Updated: ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                      style: TextStyle(
                        fontSize: 13,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bulletCount == 0
                ? "No significant accounting concerns detected in the financial statements."
                : (isCritical
                    ? "Multiple critical financial indicators require immediate attention"
                    : "Financial indicators are within acceptable ranges"),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class UnorderedListBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElement(md.Element element, TextStyle? preferredStyle) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: element.children?.map((child) {
              if (child is md.Element && child.tag == 'li') {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF991B1B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          child.textContent,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF475569),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }).toList() ??
            [],
      ),
    );
  }
}

class OrderedListBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElement(md.Element element, TextStyle? preferredStyle) {
    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: element.children?.asMap().entries.map((entry) {
              if (entry.value is md.Element &&
                  (entry.value as md.Element).tag == 'li') {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          (entry.value as md.Element).textContent,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF475569),
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            }).toList() ??
            [],
      ),
    );
  }
}
