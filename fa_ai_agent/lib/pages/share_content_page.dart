import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class ShareContentPage extends StatefulWidget {
  final String documentId;

  const ShareContentPage({super.key, required this.documentId});

  @override
  State<ShareContentPage> createState() => _ShareContentPageState();
}

class _ShareContentPageState extends State<ShareContentPage> {
  late Future<DocumentSnapshot> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = FirebaseFirestore.instance
        .collection('sharedContent')
        .doc(widget.documentId)
        .get();
  }

  Widget _buildDateDisplay(Timestamp timestamp) {
    final date = timestamp.toDate();
    final formattedDate = DateFormat('MMMM d, yyyy').format(date);
    final formattedTime = DateFormat('h:mm a').format(date);
    return Text(
      '$formattedDate · $formattedTime',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[500],
          ),
      textAlign: TextAlign.left,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 0),
        child: Align(
          alignment: Alignment.topCenter,
          child: FutureBuilder<DocumentSnapshot>(
            future: _contentFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Content not found'));
              }
              final data = snapshot.data!.data() as Map<String, dynamic>;
              final type = data['type'] as String?;
              if (type != 'hedgeFundWizard') {
                return const Center(child: Text('Invalid content type'));
              }
              final question = data['question'] as String?;
              final answer = data['answer'] as String?;
              final createdDate = data['createdDate'] as Timestamp?;
              if (question == null || answer == null) {
                return const Center(child: Text('Invalid content format'));
              }

              // Ensure the question ends with a question mark
              final formattedQuestion =
                  question.endsWith('?') ? question : '$question?';

              return Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final screenWidth = constraints.maxWidth;

                        final titleSection = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              blendMode: BlendMode.srcIn,
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [Colors.blue[400]!, Colors.blue[900]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(
                                Rect.fromLTWH(
                                    0, 0, bounds.width, bounds.height),
                              ),
                              child: Text(
                                'KNK Research AI',
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(
                                      fontSize: screenWidth < 700 ? 56 : 64,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -1.5,
                                    ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (type == 'hedgeFundWizard') ...[
                              Text(
                                'Ask Hedge Fund Wizard Anything',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontSize: screenWidth < 700 ? 18 : 20,
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(height: 16),
                            ] else
                              const SizedBox(height: 8),
                          ],
                        );

                        final tryButton = ElevatedButton(
                          onPressed: () => context.go('/signup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Try KNK Research AI',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );

                        if (screenWidth < 700) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              titleSection,
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.center,
                                child: tryButton,
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: titleSection,
                              ),
                              const SizedBox(width: 24),
                              tryButton,
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Icon(
                            Icons.question_answer_outlined,
                            color: Colors.grey[700],
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            formattedQuestion,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[900],
                                  height: 1.4,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Divider(
                        height: 32, thickness: 1.2, color: Colors.grey[200]),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Generated by Hedge Fund Wizard',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        if (createdDate != null) ...[
                          const SizedBox(width: 16),
                          _buildDateDisplay(createdDate),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    MarkdownBody(
                      data: answer,
                      styleSheet: MarkdownStyleSheet(
                        p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.8,
                              color: Colors.grey[800],
                              fontSize: 16,
                            ),
                        h1: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                              height: 1.4,
                            ),
                        h2: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                              height: 1.4,
                            ),
                        h3: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[900],
                              height: 1.4,
                            ),
                        blockquoteDecoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border(
                            left: BorderSide(
                              color: Colors.blue[300]!,
                              width: 5,
                            ),
                          ),
                        ),
                        blockquotePadding: const EdgeInsets.all(16),
                        blockquote:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              backgroundColor: Colors.transparent,
                              fontFamily: 'monospace',
                              fontSize: 14,
                              color: Colors.grey[850],
                            ),
                        listBullet:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                        a: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        tableHeadAlign: TextAlign.left,
                        tableHead:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[900],
                                ),
                        tableBody:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[800],
                                  height: 1.6,
                                ),
                        tableBorder: TableBorder.all(
                          color: Colors.grey[300]!,
                          width: 1,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        tableCellsPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 14),
                        tableCellsDecoration: BoxDecoration(
                          border: Border(
                            bottom:
                                BorderSide(color: Colors.grey[200]!, width: 1),
                          ),
                        ),
                      ),
                    ),
                    // Add promotional footer section
                    const SizedBox(height: 32),
                    Divider(height: 1, color: Colors.grey[300]),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50], // Subtle background color
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Powered by Hedge Fund Wizard',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Hedge Fund Wizard is one of the advanced AI features developed by KNK Research AI, specifically trained to provide deep insights, analysis, and data for investment professionals. Enhance your research process, uncover hidden opportunities, and make data-driven decisions faster than ever before.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[700],
                                  height: 1.6,
                                ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: () => context.go('/signup'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                'Explore KNK Research AI',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // End promotional footer section
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'All information and analyses on this website are generated by various Artificial Intelligence/Machine Learning models and are intended solely as a general "research copilot"—not definitive financial advice. While the site strives to offer helpful insights, investors/traders/analysts/researchers are encouraged to conduct their own research or consult a qualified professional before making any financial decisions, as all investments involve market risk. By using this website, investors/traders/analysts/researchers acknowledge that neither the site nor its contributors shall be held responsible for any losses or damages resulting from the use of—or reliance upon—the AI-generated information provided. We appreciate everyone\'s understanding and encourage all to make informed, responsible, and profitable decisions.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
