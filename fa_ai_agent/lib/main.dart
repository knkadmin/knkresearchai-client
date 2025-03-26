import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_strategy/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'dart:io' show Platform;

import 'package:fa_ai_agent/agent_service.dart';
import 'package:fa_ai_agent/gradient_text.dart';
import 'package:fa_ai_agent/result_advanced.dart';
import 'package:fa_ai_agent/config.dart';
import 'package:fa_ai_agent/widgets/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:intl/intl.dart';
import 'package:fa_ai_agent/widgets/loading_spinner.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await Hive.initFlutter(); // Initialize Hive
  await Hive.openBox('settings'); // Open a box (like a database table)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

enum Language {
  chinese('Chinese'),
  english('English');

  final String value;
  const Language(this.value);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KNK Research',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E2C3D),
          primary: const Color(0xFF1E2C3D),
          secondary: const Color(0xFF2E4B6F),
          surface: Colors.white,
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E2C3D),
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E2C3D),
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            color: Colors.grey[800],
          ),
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: const WelcomeScreen(),
            ),
          ),
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => NoTransitionPage<void>(
              child: const MyHomePage(title: 'KNK Research'),
            ),
          ),
          GoRoute(
            path: '/report/:ticker',
            pageBuilder: (context, state) {
              final ticker = state.pathParameters['ticker']!;
              return NoTransitionPage<void>(
                child: FutureBuilder(
                  future: AgentService().searchTickerSymbol(ticker),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: StockLoadingSpinner(),
                      );
                    }

                    if (snapshot.hasData) {
                      final data = snapshot.data as Map<String, dynamic>;
                      if (data["quotes"] != null &&
                          (data["quotes"] as List).isNotEmpty) {
                        final quote = (data["quotes"] as List).first;
                        final companyName = quote["shortname"] ?? ticker;
                        return ResultAdvancedPage(
                          tickerCode: ticker.toUpperCase(),
                          companyName: companyName,
                          language: Language.english,
                        );
                      }
                    }

                    // Fallback to using ticker as company name if lookup fails
                    return ResultAdvancedPage(
                      tickerCode: ticker.toUpperCase(),
                      companyName: ticker.toUpperCase(),
                      language: Language.english,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;
  final Language language = Language.english;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final searchController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController feedbackController = TextEditingController();

  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;
  Timer? _debounce;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  final AgentService service = AgentService();

  // Update these variables for market data
  Map<String, dynamic> marketData = {
    'S&P 500': {
      'symbol': 'SPY',
      'price': '0.00',
      'change': '0.00%',
      'detail': 'Loading...',
      'isPositive': true
    },
    'NASDAQ': {
      'symbol': 'QQQ',
      'price': '0.00',
      'change': '0.00%',
      'detail': 'Loading...',
      'isPositive': true
    },
    'DOW JONES': {
      'symbol': 'DIA',
      'price': '0.00',
      'change': '0.00%',
      'detail': 'Loading...',
      'isPositive': true
    },
    'VIX': {
      'symbol': 'UVXY',
      'price': '0.00',
      'change': '0.00%',
      'detail': 'Loading...',
      'isPositive': true
    },
  };
  Timer? _marketUpdateTimer;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuad,
    ));

    // Initialize market data
    // updateMarketData();
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    _animationController.dispose();
    _marketUpdateTimer?.cancel();
    super.dispose();
  }

  void fetchStockData(String query) async {
    if (query.isEmpty) return;

    setState(() {
      searchResults = [];
    });

    final data = await service.searchTickerSymbol(query);
    if (data["quotes"] != null) {
      setState(() {
        searchResults = (data["quotes"] as List)
            .where((item) =>
                item.containsKey("shortname") && item.containsKey("symbol"))
            .map((item) => {
                  "name": item["shortname"],
                  "symbol": item["symbol"],
                })
            .toList();
      });

      _animationController.forward();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (query.isNotEmpty) {
        fetchStockData(query);
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        body: GestureDetector(
          onTap: () {
            if (searchResults.isNotEmpty) {
              setState(() {
                searchController.clear();
                searchResults = [];
                _animationController.reverse();
              });
            }
          },
          child: Container(
            child: Container(
              child: SingleChildScrollView(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        searchEngine(),
                        companyDemoPresets(),
                        whyChooseWithUs(),
                        Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 700,
                              color: Colors.black,
                            ),
                            Align(
                              alignment: Alignment.center,
                              child: feedbackForm(),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.only(bottom: 20),
                          width: double.infinity,
                          color: Colors.black,
                          child: const Text(
                            "© 2025 KNK research",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      ],
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const SizedBox(height: 480),
                          searchResults.isEmpty
                              ? Container()
                              : searchResultList()
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget searchEngine() {
    const String title = "KNK Research";
    final String subtitle = widget.language == Language.english
        ? "Your AI Agent financial analyst, delivering in-depth research to empower informed investment decisions and optimize returns."
        : "通过股票代码来获取公司业务概要，每股收益，现金流等财务信息。";
    final String placeholder =
        widget.language == Language.english ? "E.g. Nvidia" : "搜索公司名或者股票代码";
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E2C3D),
            const Color(0xFF2E4B6F),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 80),
          const Text(
            title,
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            height: 50,
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Container(
            width: 600,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Card(
              elevation: 20,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.language == Language.english
                          ? 'Try the Preview Version now'
                          : '立即试用',
                      style: const TextStyle(
                        color: Color(0xFF1E2C3D),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.language == Language.english
                          ? 'Simply ask AI agent to generate a financial report on any US-listed companies by searching names or ticker symbols.'
                          : '立即试用',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    searchBar(placeholder),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget companyDemoPresets() {
    final List<Map<String, String>> preset = [
      {"AAPL": "Apple"},
      {"MSFT": "Microsoft"},
      {"NVDA": "NVIDIA"},
      {"GOOG": "Alphabet (Google)"},
      {"AMZN": "Amazon"},
      {"META": "Meta Platforms (Facebook)"},
      {"JPM": "JPMorgan Chase"},
      {"AVGO": "Broadcom"},
      {"TSLA": "Tesla"},
      {"LLY": "Eli Lilly"}
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          const Text(
            "Quick start with Top 10 popular U.S. companies",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2C3D),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            width: 900, // Maximum width for the list
            child: Center(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(preset.length, (index) {
                  final Map<String, String> company = preset[index];
                  final companyName = company.values.toList().first;
                  final ticker = company.keys.toList().first;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          fetchReport(ticker, companyName, widget.language),
                      borderRadius: BorderRadius.circular(25),
                      hoverColor: const Color(0xFF2E4B6F).withOpacity(0.1),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF2E4B6F),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ticker,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E4B6F),
                              ),
                            ),
                            Container(
                              height: 20,
                              width: 1,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              color: const Color(0xFF2E4B6F).withOpacity(0.3),
                            ),
                            Text(
                              companyName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget marketOverview() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Market Overview",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2C3D),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 60),
          Center(
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: marketData.entries.map((entry) {
                final data = entry.value;
                return _buildMarketCard(
                  entry.key,
                  data['price'],
                  data['change'],
                  data['isPositive'] ?? true,
                  data['detail'],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketCard(String title, String value, String change,
      bool isPositive, String detail) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E2C3D),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2C3D),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 20,
                ),
                Text(
                  change,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              detail,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget whyChooseWithUs() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          gradientTitle("Why choose AI agent with us?", 32),
          const SizedBox(height: 60),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  showcaseCard(
                    "Quick Insights",
                    "Understand a U.S.-listed company in just 2 minutes",
                    "Get a comprehensive overview of any U.S.-listed company in just two minutes, including business model, financials, and market performance.",
                    Icons.speed,
                  ),
                  const SizedBox(width: 24),
                  showcaseCard(
                    "Instant Updates",
                    "Refresh reports in just 30 seconds",
                    "No need to search for updates manually—simply refresh the report and get the latest company news and market changes in 30 seconds.",
                    Icons.update,
                  ),
                  const SizedBox(width: 24),
                  showcaseCard(
                    "Comprehensive View",
                    "Full industry landscape & competitor analysis",
                    "Easily see where a company fits within its industry, from upstream and downstream supply chains to key competitors, all in one clear report.",
                    Icons.view_comfy,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget showcaseCard(
      String title, String subtitle, String description, IconData iconName) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(40),
        width: 350,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2C3D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconName,
                color: const Color(0xFF1E2C3D),
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2C3D),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E2C3D),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget teamMember(String name, String role, String imageName) {
    return Column(
      children: [
        Container(
            width: 200,
            height: 300,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(8), // Apply corner radius here
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                "assets/$imageName",
                fit: BoxFit.cover,
              ),
            )),
        const SizedBox(
          height: 10,
        ),
        Text(
          name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          role,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w100, color: Colors.grey),
        ),
      ],
    );
  }

  Widget feedbackForm() {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 900, // Maximum width of the container
      ),
      color: Colors.black,
      padding: EdgeInsets.all(80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 10,
          ),
          const SizedBox(
            child: const Text(
              "We would like to hear your feedback.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
          const SizedBox(
            height: 40,
          ),
          const Text(
            'Issue description (* Requried)',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: feedbackController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText:
                  'Please tell us what you were trying to achieve and what unexpected results or false information you noticed from AI agent reports.',
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade800),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your email',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your email',
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade800),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            child: ElevatedButton(
                onPressed: () {
                  if (feedbackController.text.isEmpty) {
                    QuickAlert.show(
                      context: context,
                      type: QuickAlertType.error,
                      title: "Your message is empty",
                      text: 'Please describe your issue in the description.',
                      showConfirmBtn: true,
                    );
                    return;
                  }
                  service.sendFeedback(
                      emailController.text, feedbackController.text);
                  emailController.text = "";
                  feedbackController.text = "";
                  setState(() {
                    QuickAlert.show(
                      context: context,
                      type: QuickAlertType.success,
                      title: "Thank you",
                      text: 'Your feedback is on its way to our mailbox.',
                      showConfirmBtn: true,
                    );
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.white60;
                      }
                      return Colors.white; // Use the component's default.
                    },
                  ),
                ),
                child: Container(
                    width: 100,
                    height: 40,
                    child: Center(
                      child: Text(
                        widget.language == Language.english ? 'Send' : '确认发送',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ))),
          ),
        ],
      ),
    );
  }

  Widget searchBar(String placeholder) {
    return GestureDetector(
      onTap: () {}, // Prevent click propagation
      child: SizedBox(
        height: 60,
        child: TextField(
          controller: searchController,
          onChanged: _onSearchChanged,
          onSubmitted: (value) => {if (value.isNotEmpty) {}},
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF1E2C3D),
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: () {
                      searchController.clear();
                      searchResults = [];
                      setState(() {});
                    },
                  )
                : Icon(Icons.search, color: Colors.grey[600]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget searchResultList() {
    return GestureDetector(
      onTap: () {}, // Prevent click propagation
      child: SizedBox(
        height: 400,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimation,
              child: AnimatedOpacity(
                opacity: _opacityAnimation.value,
                duration: _animationController.duration ??
                    const Duration(milliseconds: 300),
                child: Card(
                  elevation: 20,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    width: 600,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final name = searchResults[index]["name"] ?? "";
                        final symbol = searchResults[index]["symbol"] ?? "";
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E2C3D),
                            ),
                          ),
                          subtitle: Text(
                            symbol,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E4B6F),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF2E4B6F),
                          ),
                          onTap: () {
                            _animationController.reverse();
                            fetchReport(symbol, name, widget.language);
                            setState(() {
                              searchController.text = "";
                              searchResults = [];
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void fetchReport(String ticker, String companyName, Language language) {
    final encodedTicker = Uri.encodeComponent(ticker);
    context.go('/report/$encodedTicker');
  }

  Future<void> updateMarketData() async {
    try {
      for (var entry in marketData.entries) {
        final symbol = entry.value['symbol'];
        final url = Uri.parse(
            'https://api.twelvedata.com/quote?symbol=${symbol}&apikey=${Config.twelvedataApiKey}');

        // Add retries for robustness
        int maxRetries = 3;
        int currentTry = 0;

        while (currentTry < maxRetries) {
          try {
            final response = await http.get(url);
            print('Response for ${entry.key}: ${response.body}'); // Debug log

            if (response.statusCode == 200) {
              final data = json.decode(response.body);

              if (data != null &&
                  !data.containsKey('status') &&
                  !data.containsKey('code')) {
                final price = double.tryParse(data['close'] ?? '0.0')
                        ?.toStringAsFixed(2) ??
                    '0.00';
                final previousClose =
                    double.tryParse(data['previous_close'] ?? '0.0') ?? 0.0;
                final currentPrice = double.tryParse(price) ?? 0.0;

                // Calculate percentage change
                final changePercent = previousClose > 0
                    ? ((currentPrice - previousClose) / previousClose * 100)
                        .toStringAsFixed(2)
                    : '0.00';

                final isPositive = double.parse(changePercent) >= 0;

                // Format the detail string with commas for better readability
                final formattedPrevClose =
                    NumberFormat("#,##0.00", "en_US").format(previousClose);
                String detail = 'Previous Close: \$${formattedPrevClose}';
                if (entry.key == 'VIX') {
                  detail = 'Volatility: ${currentPrice > 20 ? 'High' : 'Low'}';
                }

                if (mounted) {
                  setState(() {
                    marketData[entry.key] = {
                      'symbol': symbol,
                      'price': price,
                      'change': '${isPositive ? '+' : ''}$changePercent%',
                      'isPositive': isPositive,
                      'detail': detail,
                    };
                  });
                }
                break; // Success, exit retry loop
              } else {
                print('Invalid data format for ${entry.key}: ${data}');
              }
            } else {
              print(
                  'Error fetching data for ${entry.key}: ${response.statusCode}');
              print('Error response: ${response.body}');
            }
          } catch (e) {
            print('Error in try ${currentTry + 1} for ${entry.key}: $e');
            if (currentTry == maxRetries - 1) {
              // On last retry, update UI to show error state
              if (mounted) {
                setState(() {
                  marketData[entry.key] = {
                    'symbol': symbol,
                    'price': 'Error',
                    'change': '--',
                    'detail': 'Unable to fetch data',
                    'isPositive': true,
                  };
                });
              }
            }
          }
          currentTry++;
          if (currentTry < maxRetries) {
            // Wait before retrying, with exponential backoff
            await Future.delayed(
                Duration(milliseconds: 500 * (currentTry + 1)));
          }
        }

        // Add a small delay between requests to respect rate limits
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print('Error updating market data: $e');
    }
  }
}
