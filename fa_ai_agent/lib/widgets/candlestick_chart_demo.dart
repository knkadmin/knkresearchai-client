import 'package:flutter/material.dart';
import 'package:interactive_chart/interactive_chart.dart';
import 'dart:math' as math;

class CandlestickChartDemo extends StatefulWidget {
  final String symbol;

  const CandlestickChartDemo({
    Key? key,
    required this.symbol,
  }) : super(key: key);

  @override
  State<CandlestickChartDemo> createState() => _CandlestickChartDemoState();
}

class _CandlestickChartDemoState extends State<CandlestickChartDemo> {
  List<CandleData> _sampleCandleData = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _generateSampleData();
  }

  void _generateSampleData() {
    // Generate some sample data for demonstration purposes
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // In a real app, this would be replaced with actual API calls to fetch stock data
      final List<CandleData> data = [];

      // Starting values
      double open = 150.0;
      double high = 155.0;
      double low = 145.0;
      double close = 152.0;
      double volume = 1000000.0;

      // Generate 90 days of sample data
      final now = DateTime.now();
      for (int i = 90; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));

        // Random variations to create realistic-looking data
        final change =
            (30 * (0.5 - _getRandomDouble())) + (_getRandomDouble() * 5 - 2.5);

        open = close;
        close = open + change;
        high = math.max(open, close) + _getRandomDouble() * 5;
        low = math.min(open, close) - _getRandomDouble() * 5;
        volume = volume * (0.9 + _getRandomDouble() * 0.2);

        data.add(CandleData(
          timestamp: date.millisecondsSinceEpoch,
          open: open,
          high: high,
          low: low,
          close: close,
          volume: volume,
        ));
      }

      setState(() {
        _sampleCandleData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      print('Error generating sample data: $e');
    }
  }

  double _getRandomDouble() {
    return DateTime.now().microsecondsSinceEpoch % 1000 / 1000;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1E3A8A),
        ),
      );
    }

    if (_hasError || _sampleCandleData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading chart data for ${widget.symbol}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateSampleData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '${widget.symbol} Price Chart',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InteractiveChart(
            candles: _sampleCandleData,
            style: ChartStyle(
              priceGainColor: const Color(0xFF26A69A),
              priceLossColor: const Color(0xFFEF5350),
              volumeColor: const Color(0xFF64B5F6),
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.month}/${date.day}/${date.year}';
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    }
    return volume.toStringAsFixed(0);
  }
}
