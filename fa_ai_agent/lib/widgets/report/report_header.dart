import 'package:fa_ai_agent/services/agent_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/subjects.dart';
import 'package:fa_ai_agent/main.dart';

class ReportHeader extends StatefulWidget {
  final BehaviorSubject cacheTimeSubject;
  final Language language;
  final String tickerCode;
  final AgentService agentService = AgentService();

  ReportHeader({
    Key? key,
    required this.cacheTimeSubject,
    required this.language,
    required this.tickerCode,
  }) : super(key: key);

  @override
  _ReportHeaderState createState() => _ReportHeaderState();
}

class _ReportHeaderState extends State<ReportHeader> {
  late Future<Map<String, dynamic>> _companyProfileFuture;

  @override
  void initState() {
    super.initState();
    _companyProfileFuture =
        widget.agentService.searchTickerSymbol(widget.tickerCode);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _companyProfileFuture,
      builder: (context, companySnapshot) {
        String companyName = 'Loading...';
        String sector = 'Loading...';
        Widget profileWidget;

        if (companySnapshot.connectionState == ConnectionState.waiting) {
          profileWidget = const Row(
            children: [
              SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white)),
              SizedBox(width: 8),
              Text('Loading Profile...',
                  style: TextStyle(color: Colors.white70)),
            ],
          );
        } else if (companySnapshot.hasError) {
          companyName = 'Error';
          sector = 'Error';
          profileWidget = Row(
            children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Text('Error Loading Profile: ${companySnapshot.error}',
                  style: const TextStyle(color: Colors.redAccent)),
            ],
          );
        } else if (companySnapshot.hasData &&
            companySnapshot.data?['quotes'] != null &&
            (companySnapshot.data!['quotes'] as List).isNotEmpty) {
          final quote = (companySnapshot.data!['quotes'] as List).first;
          companyName = quote['name'] ?? 'N/A';
          sector = quote['stockExchange'] ?? 'N/A';
          profileWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      companyName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (sector != 'N/A' && sector != 'Error')
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        sector,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          );
        } else {
          profileWidget = const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text('Profile data not found for ticker',
                  style: TextStyle(color: Colors.white70)),
            ],
          );
        }

        return StreamBuilder(
          stream: widget.cacheTimeSubject.stream,
          builder: (BuildContext context, AsyncSnapshot cacheSnapshot) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade900,
                    Colors.blue.shade800,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 24),
                          child: profileWidget,
                        ),
                      ),
                      if (cacheSnapshot.hasData)
                        SizedBox(
                          width: 160,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "Last Updated",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMMM, yyyy').format(
                                    DateTime.fromMicrosecondsSinceEpoch(
                                        cacheSnapshot.data)),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.language == Language.english
                        ? "KNK Research - Comprehensive Financial Analysis Report"
                        : "KNK Research - 综合财务分析报告",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w500,
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
}
