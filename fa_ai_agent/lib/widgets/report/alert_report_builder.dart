import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fa_ai_agent/widgets/thinking_animation.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:intl/intl.dart';
import 'package:fa_ai_agent/agent_service.dart';
import 'dart:convert';
import 'package:fa_ai_agent/widgets/report/chart_image.dart';

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
            final markdown = data['accountingRedflags']?['md'] as String?;
            final rating =
                data['accountingRedflags']?['mScoreRating'] as String?;
            final incomeStatement =
                data['accountingRedflags']?['incomeStatement'] as String?;
            final balanceSheet =
                data['accountingRedflags']?['balanceSheet'] as String?;

            // Determine theme based on rating
            final statusColor = _getStatusColor(rating);
            final borderColor = _getBorderColor(rating);

            final cacheTime = data['cachedAt'] != null
                ? DateTime.fromMicrosecondsSinceEpoch(data['cachedAt'])
                : null;

            if (cacheTime != null && onCacheTimeUpdate != null) {
              onCacheTimeUpdate!(cacheTime);
            }

            if (markdown == null || markdown.isEmpty) {
              return const Center(
                child: Text('No content available'),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
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
                  if (incomeStatement != null || balanceSheet != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (incomeStatement != null) ...[
                            const Text(
                              'Income Statement',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ChartImage(
                              image: Image.memory(
                                base64Decode(incomeStatement),
                                fit: BoxFit.contain,
                              ),
                              encodedImage: incomeStatement,
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (balanceSheet != null) ...[
                            const Text(
                              'Balance Sheet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ChartImage(
                              image: Image.memory(
                                base64Decode(balanceSheet),
                                fit: BoxFit.contain,
                              ),
                              encodedImage: balanceSheet,
                            ),
                          ],
                        ],
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
                      builders: {
                        'ul': UnorderedListBuilder(),
                        'ol': OrderedListBuilder(),
                      },
                      styleSheet: MarkdownStyleSheet(
                        h1: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                        h2: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                        h3: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: statusColor,
                        ),
                        p: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF475569),
                          height: 1.6,
                        ),
                        strong: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: statusColor,
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

  Color _getStatusColor(String? rating) {
    switch (rating?.toLowerCase()) {
      case 'acceptable':
        return const Color(0xFF059669); // Green
      case 'skeptical':
        return const Color(0xFFD97706); // Orange
      case 'critical':
        return const Color(0xFF991B1B); // Dark Red
      default:
        return const Color(0xFF1E293B); // Default dark gray
    }
  }

  Color _getHeaderColor(String? rating) {
    switch (rating?.toLowerCase()) {
      case 'acceptable':
        return const Color(0xFFF0FDF4); // Light green
      case 'skeptical':
        return const Color(0xFFFFFBEB); // Light orange
      case 'critical':
        return const Color(0xFFFFF5F5); // Light red
      default:
        return const Color(0xFFF8FAFC); // Default light gray
    }
  }

  Color _getBorderColor(String? rating) {
    switch (rating?.toLowerCase()) {
      case 'acceptable':
        return const Color(0xFFD1FAE5); // Green border
      case 'skeptical':
        return const Color(0xFFFEF3C7); // Orange border
      case 'critical':
        return const Color(0xFFFEE2E2); // Red border
      default:
        return const Color(0xFFE5E7EB); // Default gray border
    }
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    final rating = data['accountingRedflags']?['mScoreRating'] as String?;
    final statusColor = _getStatusColor(rating);
    final headerColor = _getHeaderColor(rating);
    final borderColor = _getBorderColor(rating);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: headerColor,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
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
                _getStatusIcon(rating),
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
                      rating ?? "No Rating",
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
                    color: borderColor,
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
            _getStatusDescription(rating),
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

  IconData _getStatusIcon(String? rating) {
    switch (rating?.toLowerCase()) {
      case 'acceptable':
        return Icons.check_circle_outline;
      case 'skeptical':
        return Icons.warning_amber_rounded;
      case 'critical':
        return Icons.error_outline;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusDescription(String? rating) {
    switch (rating?.toLowerCase()) {
      case 'acceptable':
        return "Financial indicators are within acceptable ranges and show no significant concerns.";
      case 'skeptical':
        return "Some financial indicators require attention and further investigation.";
      case 'critical':
        return "Multiple critical financial indicators require immediate attention.";
      default:
        return "No rating available for this report.";
    }
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
