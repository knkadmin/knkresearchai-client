import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryDialog extends StatefulWidget {
  final String question;
  final String answer;
  final DateTime createdDate;
  final String documentId;

  const HistoryDialog({
    super.key,
    required this.question,
    required this.answer,
    required this.createdDate,
    required this.documentId,
  });

  @override
  State<HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<HistoryDialog> {
  late final String _formattedDate;
  late final MarkdownStyleSheet _markdownStyleSheet;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> _shareContent() async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';

      // Check if the document already exists
      final docSnapshot = await _firestore
          .collection('sharedContent')
          .doc(widget.documentId)
          .get();

      if (docSnapshot.exists) {
        // If document exists, show the success dialog directly
        if (mounted) {
          _showShareSuccessDialog(widget.documentId);
        }
        return;
      }

      // Create a new document in the sharedContent collection with the same ID
      await _firestore.collection('sharedContent').doc(widget.documentId).set({
        'type': 'hedgeFundWizard',
        'question': widget.question,
        'answer': widget.answer,
        'createdDate': Timestamp.fromDate(widget.createdDate),
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Show success dialog with the share link
      if (mounted) {
        _showShareSuccessDialog(widget.documentId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing content: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showShareSuccessDialog(String sharedContentId) {
    final shareUrl = 'https://knkresearchai.com/share/$sharedContentId';
    bool isCopied = false;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFF1A1F2C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: isSmallScreen
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: isSmallScreen ? double.infinity : 600,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.link,
                      color: Colors.white.withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Your link is ready',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            textSelectionTheme: TextSelectionThemeData(
                              selectionColor: Colors.white.withOpacity(0.4),
                            ),
                          ),
                          child: SelectableText(
                            shareUrl,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCopied)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'URL copied',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.withOpacity(0.7),
                              size: 16,
                            ),
                          ],
                        )
                      else
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: shareUrl));
                            setState(() => isCopied = true);
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) {
                                setState(() => isCopied = false);
                              }
                            });
                          },
                          icon: Icon(
                            Icons.copy,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pop(); // Only close the link ready popup
                      },
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final uri = Uri.parse(shareUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        minimumSize: const Size(120, 48),
                      ),
                      child: const Text(
                        'View Page',
                        style: TextStyle(
                          color: Color(0xFF1A1F2C),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showShareConfirmationDialog() async {
    // Check if the document already exists
    final docSnapshot = await _firestore
        .collection('sharedContent')
        .doc(widget.documentId)
        .get();

    if (docSnapshot.exists) {
      // If document exists, show the success dialog directly
      if (mounted) {
        _showShareSuccessDialog(widget.documentId);
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Generate Public Link',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will generate a public link to share this conversation. Anyone with the link will be able to view it.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.privacy_tip_outlined,
                      color: Colors.white.withOpacity(0.7),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your personal information will not be disclosed in this shared page.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _shareContent();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              minimumSize: const Size(120, 48),
            ),
            child: const Text(
              'Generate',
              style: TextStyle(
                color: Color(0xFF1A1F2C),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 700;

    return Dialog(
      backgroundColor: const Color(0xFF1A1F2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: isSmallScreen
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: isSmallScreen ? double.infinity : 1000,
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
                  'Hedge Fund Wizard - History',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (widget.answer.isNotEmpty)
                  TextButton(
                    onPressed: _showShareConfirmationDialog,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      minimumSize: const Size(120, 48),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Share',
                          style: TextStyle(
                            color: const Color(0xFF1A1F2C),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.link,
                          color: const Color(0xFF1A1F2C),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 16),
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
