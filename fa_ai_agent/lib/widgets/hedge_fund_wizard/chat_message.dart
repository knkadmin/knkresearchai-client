import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:math';

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isMarkdown;
  final VoidCallback? onSharePressed;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.isMarkdown = false,
    this.onSharePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(text),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            isUser
                ? Container(
                    constraints: BoxConstraints(
                      maxWidth: isUser
                          ? min(800 * 0.7,
                              MediaQuery.of(context).size.width * 0.7)
                          : min(
                              800 - 32, MediaQuery.of(context).size.width - 32),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF27324A)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: isUser
                          ? null
                          : Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                    ),
                    child: isMarkdown
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share,
                                    color: Colors.white70, size: 18),
                                onPressed: onSharePressed,
                                tooltip: 'Share',
                                splashRadius: 20,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.only(bottom: 4),
                              ),
                              MarkdownBody(
                                data: text,
                                shrinkWrap: true,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    height: 1.5,
                                    fontFamily:
                                        '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                  ),
                                  h1: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                    fontFamily:
                                        '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                  ),
                                  h2: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                    fontFamily:
                                        '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                  ),
                                  h3: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                    fontFamily:
                                        '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                  ),
                                  h4: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                    fontFamily:
                                        '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                  ),
                                  h5: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                    fontFamily:
                                        '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                  ),
                                  h6: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                    fontFamily:
                                        '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                  ),
                                  em: const TextStyle(
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                    fontFamily:
                                        '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                  ),
                                  strong: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontFamily:
                                        '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                  ),
                                  code: TextStyle(
                                    color: Colors.white,
                                    backgroundColor: const Color(0xFF1E293B)
                                        .withOpacity(0.8),
                                    fontFamily:
                                        'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace',
                                    fontSize: 15,
                                  ),
                                  codeblockDecoration: BoxDecoration(
                                    color: const Color(0xFF1E293B)
                                        .withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  blockquote: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontStyle: FontStyle.italic,
                                    fontFamily:
                                        '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                  ),
                                  blockquoteDecoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  listBullet: const TextStyle(
                                    color: Colors.white,
                                    fontFamily:
                                        '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                  ),
                                  tableCellsDecoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  tableBorder: TableBorder(
                                    horizontalInside: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                    verticalInside: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                    top: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                    bottom: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                    left: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                    right: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  tableHead: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    fontFamily:
                                        '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                  ),
                                  tableBody: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w100,
                                    fontSize: 12,
                                    fontFamily:
                                        '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.share,
                                    color: Colors.white70, size: 18),
                                onPressed: onSharePressed,
                                tooltip: 'Share',
                                splashRadius: 20,
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.only(top: 4),
                              ),
                            ],
                          )
                        : Text(
                            text,
                            style: const TextStyle(color: Colors.white),
                          ),
                  )
                : Expanded(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isUser
                            ? min(800 * 0.7,
                                MediaQuery.of(context).size.width * 0.7)
                            : min(800 - 32,
                                MediaQuery.of(context).size.width - 32),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? const Color(0xFF27324A)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: isUser
                            ? null
                            : Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                      ),
                      child: isMarkdown
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.share,
                                      color: Colors.white70, size: 18),
                                  onPressed: onSharePressed,
                                  tooltip: 'Share',
                                  splashRadius: 20,
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.only(bottom: 4),
                                ),
                                MarkdownBody(
                                  data: text,
                                  shrinkWrap: true,
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      height: 1.5,
                                      fontFamily:
                                          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                    ),
                                    h1: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                      fontFamily:
                                          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                    ),
                                    h2: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                      fontFamily:
                                          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                    ),
                                    h3: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                      fontFamily:
                                          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                    ),
                                    h4: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                      fontFamily:
                                          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                    ),
                                    h5: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                      fontFamily:
                                          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                    ),
                                    h6: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      height: 1.3,
                                      fontFamily:
                                          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                    ),
                                    em: const TextStyle(
                                      color: Colors.white,
                                      fontStyle: FontStyle.italic,
                                      fontFamily:
                                          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                    ),
                                    strong: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily:
                                          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                    ),
                                    code: TextStyle(
                                      color: Colors.white,
                                      backgroundColor: const Color(0xFF1E293B)
                                          .withOpacity(0.8),
                                      fontFamily:
                                          'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace',
                                      fontSize: 15,
                                    ),
                                    codeblockDecoration: BoxDecoration(
                                      color: const Color(0xFF1E293B)
                                          .withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    blockquote: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontStyle: FontStyle.italic,
                                      fontFamily:
                                          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                    ),
                                    blockquoteDecoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border(
                                        left: BorderSide(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 4,
                                        ),
                                      ),
                                    ),
                                    listBullet: const TextStyle(
                                      color: Colors.white,
                                      fontFamily:
                                          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                    ),
                                    tableCellsDecoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    tableBorder: TableBorder(
                                      horizontalInside: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                      verticalInside: BorderSide(
                                        color: Colors.white.withOpacity(0.1),
                                        width: 1,
                                      ),
                                      top: BorderSide(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                      bottom: BorderSide(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                      left: BorderSide(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                      right: BorderSide(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    tableHead: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      fontFamily:
                                          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                    ),
                                    tableBody: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w100,
                                      fontSize: 12,
                                      fontFamily:
                                          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.share,
                                      color: Colors.white70, size: 18),
                                  onPressed: onSharePressed,
                                  tooltip: 'Share',
                                  splashRadius: 20,
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.only(top: 4),
                                ),
                              ],
                            )
                          : Text(
                              text,
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
