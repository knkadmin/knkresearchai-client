import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_message.dart';
import 'typing_indicator.dart';
import 'animated_message.dart';
import 'history_dialog.dart';
import '../../widgets/chat_input_field.dart';

class HedgeFundWizardChatView extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isProcessing;
  final bool showInsufficientBalance;
  final int lastMessageCount;
  final TextEditingController messageController;
  final Function(String) onSubmitted;
  final List<Map<String, dynamic>> questionHistory;
  final String currentUuid;

  const HedgeFundWizardChatView({
    super.key,
    required this.messages,
    required this.isProcessing,
    required this.showInsufficientBalance,
    required this.lastMessageCount,
    required this.messageController,
    required this.onSubmitted,
    required this.questionHistory,
    required this.currentUuid,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0F172A).withValues(alpha: 0),
                  const Color(0xFF0F172A).withValues(alpha: 0),
                  const Color(0xFF0F172A).withValues(alpha: 0),
                  const Color(0xFF0F172A),
                ],
                stops: const [0.0, 0.05, 0.95, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstOut,
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                        left: 8.0, right: 8.0, bottom: 32.0),
                    itemCount: messages.length +
                        (isProcessing ? 1 : 0) +
                        (showInsufficientBalance ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && isProcessing) {
                        return const TypingIndicator();
                      }

                      if (index == messages.length + (isProcessing ? 1 : 0) &&
                          showInsufficientBalance) {
                        return Padding(
                          padding: const EdgeInsets.only(
                              left: 16.0, right: 16.0, bottom: 16.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Insufficient balance. Please purchase more Veritas to continue.',
                              style: TextStyle(
                                color: Colors.red.withValues(alpha: 0.8),
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        );
                      }

                      final message = messages[index];
                      final isNew = index >= lastMessageCount - 1;

                      final bool isShareableAiMessage =
                          !message.isUser && message.isMarkdown;

                      return AnimatedMessage(
                        isNew: isNew,
                        child: ChatMessage(
                          key: message.key,
                          text: message.text,
                          isUser: message.isUser,
                          isMarkdown: message.isMarkdown,
                          onSharePressed: isShareableAiMessage
                              ? () {
                                  final historyItem =
                                      questionHistory.firstWhere(
                                    (item) => item['sessionId'] == currentUuid,
                                  );

                                  showDialog(
                                    context: context,
                                    builder: (context) => HistoryDialog(
                                      question: historyItem['question'] ?? '',
                                      answer: historyItem['result'] ?? '',
                                      createdDate: (historyItem['createdDate']
                                              as Timestamp)
                                          .toDate(),
                                      documentId: historyItem['id'] ?? '',
                                    ),
                                  );
                                }
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ChatInputField(
              controller: messageController,
              isProcessing: isProcessing,
              onSubmitted: onSubmitted,
              onSendPressed: () => onSubmitted(messageController.text),
            ),
          ),
        ),
      ],
    );
  }
}
