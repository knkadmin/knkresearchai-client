import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

class HistoryDialog extends StatefulWidget {
  final String question;
  final String answer;
  final DateTime createdDate;

  const HistoryDialog({
    super.key,
    required this.question,
    required this.answer,
    required this.createdDate,
  });

  @override
  State<HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<HistoryDialog> {
  late final String _formattedDate;
  late final MarkdownStyleSheet _markdownStyleSheet;

  @override
  void initState() {
    super.initState();
    _formattedDate = DateFormat('MMMM d, yyyy').format(widget.createdDate);
    _markdownStyleSheet = MarkdownStyleSheet(
      p: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        height: 1.6,
        fontFamily: 'Inter',
      ),
      h1: const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.3,
        fontFamily: 'Inter',
      ),
      h2: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        fontFamily: 'Inter',
      ),
      h3: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        fontFamily: 'Inter',
      ),
      h4: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
        fontFamily: 'Inter',
      ),
      code: TextStyle(
        color: Colors.white,
        backgroundColor: Colors.white.withOpacity(0.1),
        fontFamily: 'JetBrains Mono',
        fontSize: 14,
      ),
      codeblockDecoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      blockquote: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          left: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 4,
          ),
        ),
      ),
      listBullet: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      tableHead: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      tableBody: const TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
      tableBorder: TableBorder.all(
        color: Colors.white.withOpacity(0.1),
        width: 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1F2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          children: [
            // Fixed header
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Conversation History',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.white.withOpacity(0.7)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Question from $_formattedDate',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Text(
                widget.question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Response',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // Scrollable content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Scrollbar(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white,
                          Colors.white,
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.85, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Markdown(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        data: widget.answer,
                        styleSheet: _markdownStyleSheet,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
