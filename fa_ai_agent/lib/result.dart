import 'package:animation_list/animation_list.dart';
import 'package:fa_ai_agent/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ResultPage extends StatefulWidget {
  const ResultPage(
      {super.key, required this.tickerCode, required this.language});

  final String tickerCode;
  final Language language;
  @override
  State<ResultPage> createState() => _ResultPage();
}

class _ResultPage extends State<ResultPage> {
  final f = DateFormat('yyyy-MM-dd hh:mm');
  bool forceRefreshReport = false;
  bool forceRefreshCharts = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tickerCode),
        centerTitle: false,
        actionsPadding: const EdgeInsets.only(right: 24),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                forceRefreshReport = true;
                forceRefreshCharts = true;
              });
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.hovered))
                    return Colors.blue.shade900;
                  return Colors.black; // Use the component's default.
                },
              ),
            ),
            child: Text(
              widget.language == Language.english ? 'Update Reports' : '获取最新',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      body: Center(
          child: Row(
        children: [
          Expanded(child: markdownBuilder(widget.tickerCode)),
          Expanded(child: chartsBuilder(widget.tickerCode))
        ],
      )),
    );
  }

  Widget markdownBuilder(String tickerCode) {
    return FutureBuilder(
        future: getTextReport(tickerCode),
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final Map<String, dynamic> data = snapshot.data ?? {};
            final int cachedTimestamp = data["cachedAt"];
            final DateTime cacheTime =
                DateTime.fromMicrosecondsSinceEpoch(cachedTimestamp);
            final String markdown = data["md"];
            return Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Cached at: ${f.format(cacheTime)}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Markdown(data: markdown),
                  )
                ],
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }

  Widget chartsBuilder(String ticker) {
    return FutureBuilder(
        future: getChartsData(ticker),
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final Map<String, dynamic> data = snapshot.data ?? {};
            final int cachedTimestamp = data["cachedAt"];
            final DateTime cacheTime =
                DateTime.fromMicrosecondsSinceEpoch(cachedTimestamp);

            final Map<String, dynamic> espChart = data['esp_chart'];
            final String espImageEncodedString = espChart['base64'];
            final decodedEspImage =
                convert.base64.decode(espImageEncodedString);
            final espImage = Image.memory(decodedEspImage);

            final Map<String, dynamic> combinedCharts = data['combined_charts'];
            final String combinedImageEncodedString = combinedCharts['base64'];
            final decodedcombinedImage =
                convert.base64.decode(combinedImageEncodedString);
            final combinedImage = Image.memory(decodedcombinedImage);

            final Map<String, dynamic> cashFlowCharts = data['cash_flow'];
            final Map<String, dynamic> cashFlowChartDict =
                cashFlowCharts['charts'];
            final String cashFlowImageEncodedString =
                cashFlowChartDict['base64'];
            final decodedCashFlowImage =
                convert.base64.decode(cashFlowImageEncodedString);
            final cashFlowImage = Image.memory(decodedCashFlowImage);
            // final Map<String, dynamic> cashFlowTableDict =
            //     cashFlowCharts['table'];
            // final String cashFlowTableHTML = cashFlowTableDict['html'];

            final Map<String, dynamic> peChart = data['pe_chart'];
            final String peImageEncodedString = peChart['base64'];
            final decodedPeImage = convert.base64.decode(peImageEncodedString);
            final peImage = Image.memory(decodedPeImage);

            final Map<String, dynamic> insiderTradingChart =
                data['insider_trading_chart'];
            final String insiderTradingImageEncodedString =
                insiderTradingChart['base64'];
            final decodedInsiderTradingImage =
                convert.base64.decode(insiderTradingImageEncodedString);
            final insiderTradingImage =
                Image.memory(decodedInsiderTradingImage);

            return Container(
              child: AnimationList(
                animationDirection: AnimationDirection.vertical,
                duration: 2000,
                reBounceDepth: 1,
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    "Cached at: ${f.format(cacheTime)}",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 50,
                    shadowColor: Colors.black,
                    child: espImage,
                  ),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 50,
                    shadowColor: Colors.black,
                    child: combinedImage,
                  ),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 50,
                    shadowColor: Colors.black,
                    child: cashFlowImage,
                  ),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 50,
                    shadowColor: Colors.black,
                    child: peImage,
                  ),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 50,
                    shadowColor: Colors.black,
                    child: insiderTradingImage,
                  ),
                ],
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }

  Future<Map<String, dynamic>> getTextReport(String ticker) async {
    final language = widget.language.value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String cacheReportKey = "$ticker-$language-text-report";
    final String? cachedReport = prefs.getString(cacheReportKey);
    if (cachedReport == null || forceRefreshReport) {
      final url = Uri.https(
          'fa-ai-agent-784609894309.australia-southeast1.run.app',
          '/report',
          {'code': ticker, 'language': language});
      final response = await http.get(url);
      final jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      final output = jsonResponse['output'];
      output["cachedAt"] = DateTime.now().microsecondsSinceEpoch;
      prefs.setString(cacheReportKey, convert.jsonEncode(output));
      forceRefreshReport = false;
      return Future.value(output);
    } else {
      return Future.value(convert.jsonDecode(cachedReport));
    }
  }

  Future<Map<String, dynamic>> getChartsData(String ticker) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String cacheReportKey = "$ticker-charts-report";
    final String? cachedReport = prefs.getString(cacheReportKey);
    if (cachedReport == null || forceRefreshCharts) {
      final url = Uri.https(
          'fa-ai-agent-784609894309.australia-southeast1.run.app',
          '/charts',
          {'code': ticker});
      final response = await http.get(url);
      final jsonResponse =
          convert.jsonDecode(response.body) as Map<String, dynamic>;
      final output = jsonResponse['output'];
      output["cachedAt"] = DateTime.now().microsecondsSinceEpoch;
      prefs.setString(cacheReportKey, convert.jsonEncode(output));
      forceRefreshCharts = false;
      return Future.value(output);
    } else {
      return Future.value(convert.jsonDecode(cachedReport));
    }
  }
}
