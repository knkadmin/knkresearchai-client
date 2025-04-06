import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

class TradingViewChart extends StatefulWidget {
  final String tickerSymbol;
  final String companyName;

  const TradingViewChart({
    Key? key,
    required this.tickerSymbol,
    required this.companyName,
  }) : super(key: key);

  @override
  State<TradingViewChart> createState() => _TradingViewChartState();
}

class _TradingViewChartState extends State<TradingViewChart> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isWeb = false;

  @override
  void initState() {
    super.initState();
    _isWeb = identical(0, 0.0); // Check if running on web platform

    if (!_isWeb) {
      // Initialize platform-specific features for mobile
      late final PlatformWebViewControllerCreationParams params;
      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }
      _controller = WebViewController.fromPlatformCreationParams(params)
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              setState(() {
                _isLoading = false;
              });
            },
          ),
        )
        ..loadHtmlString(_getTradingViewWidgetHtml());
    } else {
      // For web platform, we'll use an iframe
      _isLoading = false;
      // Register the view factory for web platform
      final viewType = 'tradingview-${widget.tickerSymbol}';
      try {
        ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
          final iframe = html.IFrameElement()
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%'
            ..src =
                'https://www.tradingview.com/widgetembed/?symbol=${widget.tickerSymbol}&interval=1D&timezone=exchange&theme=light&style=1&locale=en&enable_publishing=false&hide_top_toolbar=true&hide_legend=false&save_image=false&calendar=false&hide_volume=false&hide_show_popup_button=true&studies=%5B%5D'
            ..id = 'tradingview_${widget.tickerSymbol}';
          return iframe;
        });
      } catch (e) {
        // Ignore error if factory is already registered
      }
    }
  }

  String _getTradingViewWidgetHtml() {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { margin: 0; padding: 0; }
          .tradingview-widget-container { width: 100%; height: 100%; }
        </style>
      </head>
      <body>
        <div class="tradingview-widget-container">
          <iframe 
            src="https://www.tradingview.com/widgetembed/?symbol=${widget.tickerSymbol}&interval=1D&timezone=exchange&theme=light&style=1&locale=en&enable_publishing=false&hide_top_toolbar=true&hide_legend=false&save_image=false&calendar=false&hide_volume=false&hide_show_popup_button=true&studies=%5B%5D"
            style="width: 100%; height: 100%; border: none;"
            allow="fullscreen"
          ></iframe>
        </div>
      </body>
      </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 120.0),
      child: Container(
        height: 600,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isWeb
            ? HtmlElementView(
                viewType: 'tradingview-${widget.tickerSymbol}',
              )
            : Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
