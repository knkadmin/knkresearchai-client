import 'package:flutter/material.dart';
import 'package:fa_ai_agent/main.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class DashboardWidget {
  final String id;
  final String title;
  final String widgetType;
  double columnSpan;
  double rowSpan;
  bool isLoading;
  Map<String, dynamic>? data;
  int gridIndex;

  DashboardWidget({
    required this.id,
    required this.title,
    required this.widgetType,
    this.columnSpan = 1.0,
    this.rowSpan = 1.0,
    this.isLoading = false,
    this.data,
    this.gridIndex = 0,
  });
}

class DashboardPage extends StatefulWidget {
  final String tickerSymbol;
  final String companyName;
  final Language language;

  const DashboardPage({
    Key? key,
    required this.tickerSymbol,
    required this.companyName,
    required this.language,
  }) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final bool _isLoading = false;
  final List<DashboardWidget> _widgets = [];
  Offset? _startResizeOffset;
  Size? _startResizeSize;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  void _initializeDashboard() {
    _addWidget(
      'overview',
      'Company Overview',
      'overview',
      2.0,
      2.0,
      0,
    );

    _addWidget(
      'metrics',
      'Key Metrics',
      'metrics',
      2.0,
      1.0,
      1,
    );

    _addWidget(
      'chart',
      'Stock Chart',
      'chart',
      2.0,
      2.0,
      2,
    );

    // Load data for all widgets
    for (var widget in _widgets) {
      _refreshWidget(widget);
    }
  }

  Future<void> _refreshWidget(DashboardWidget dashboardWidget) async {
    setState(() {
      dashboardWidget.isLoading = true;
    });

    try {
      // Add 1 second delay to simulate network request
      await Future.delayed(const Duration(seconds: 1));

      switch (dashboardWidget.widgetType) {
        case 'overview':
          setState(() {
            dashboardWidget.data = {
              'overview': 'This is a dummy business overview for ${widget.companyName}. '
                  'The company is doing great and has strong market presence. '
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                  'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
            };
          });
          break;

        case 'metrics':
          setState(() {
            dashboardWidget.data = {
              'metrics': '''
Key Financial Metrics for ${widget.companyName}:
• Revenue: \$10.5B (+15% YoY)
• Operating Margin: 35%
• Net Income: \$2.8B
• EPS: \$3.45
• P/E Ratio: 25.6
• Market Cap: \$150B
''',
            };
          });
          break;

        case 'chart':
          setState(() {
            dashboardWidget.data = {
              'chart': '''
Stock Performance (Last 12 months):
📈 High: \$185.20
📉 Low: \$120.40
📊 Current: \$165.75
Volume: 12.5M shares
''',
            };
          });
          break;
      }
    } catch (e) {
      debugPrint('Error refreshing widget ${dashboardWidget.id}: $e');
      setState(() {
        dashboardWidget.data = {'error': e.toString()};
      });
    } finally {
      setState(() {
        dashboardWidget.isLoading = false;
      });
    }
  }

  void _addWidget(String id, String title, String widgetType, double columnSpan,
      double rowSpan, int gridIndex) {
    setState(() {
      _widgets.add(DashboardWidget(
        id: id,
        title: title,
        widgetType: widgetType,
        columnSpan: columnSpan,
        rowSpan: rowSpan,
        gridIndex: gridIndex,
      ));
    });
  }

  Widget _buildWidgetContent(BuildContext context, DashboardWidget widget) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.data?['error'] != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.data!['error'].toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (widget.data == null) {
      return const Center(
        child: Text('No data available'),
      );
    }

    switch (widget.widgetType) {
      case 'overview':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Business Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(widget.data?['overview'] ?? 'No overview available'),
              ],
            ),
          ),
        );
      case 'metrics':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Metrics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(widget.data?['metrics'] ?? 'No metrics available'),
              ],
            ),
          ),
        );
      case 'chart':
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock Performance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(widget.data?['chart'] ?? 'No chart data available'),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDashboardWidget(BuildContext context, DashboardWidget widget) {
    return Container(
      key: ValueKey(widget.id),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.drag_indicator),
                        const SizedBox(width: 8),
                        Text(
                          widget.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                            '${widget.columnSpan.toStringAsFixed(1)} x ${widget.rowSpan.toStringAsFixed(1)}'),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: () => _refreshWidget(widget),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() {
                              _widgets.removeWhere((w) => w.id == widget.id);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildWidgetContent(context, widget)),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeDownRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  _startResizeOffset = details.globalPosition;
                  _startResizeSize = Size(widget.columnSpan, widget.rowSpan);
                  debugPrint(
                      'Started resizing widget ${widget.id} from ${_startResizeSize!.width} x ${_startResizeSize!.height}');
                },
                onPanUpdate: (details) {
                  if (_startResizeOffset == null || _startResizeSize == null)
                    return;

                  final cellSize = MediaQuery.of(context).size.width /
                      40; // Match the new grid resolution
                  final dx = details.globalPosition.dx - _startResizeOffset!.dx;
                  final dy = details.globalPosition.dy - _startResizeOffset!.dy;

                  setState(() {
                    // Calculate new spans based on drag distance with 0.1 precision
                    double newColumnSpan =
                        _startResizeSize!.width + (dx / (cellSize * 10));
                    double newRowSpan =
                        _startResizeSize!.height + (dy / (cellSize * 10));

                    // Round to nearest 0.1
                    newColumnSpan = (newColumnSpan * 10).round() / 10;
                    newRowSpan = (newRowSpan * 10).round() / 10;

                    // Apply constraints
                    widget.columnSpan = newColumnSpan.clamp(1.0, 4.0);
                    widget.rowSpan = newRowSpan.clamp(1.0, 4.0);

                    debugPrint(
                        'Resizing to ${widget.columnSpan.toStringAsFixed(1)} x ${widget.rowSpan.toStringAsFixed(1)}');
                  });
                },
                onPanEnd: (details) {
                  debugPrint(
                      'Finished resizing widget ${widget.id} to ${widget.columnSpan.toStringAsFixed(1)} x ${widget.rowSpan.toStringAsFixed(1)}');
                  _startResizeOffset = null;
                  _startResizeSize = null;
                },
                child: Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: const Icon(
                    Icons.open_with,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.companyName} (${widget.tickerSymbol})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _showAddWidgetDialog();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate total column spans in current row
                    Map<int, double> rowSpans = {};
                    for (var w in _widgets) {
                      int rowStart =
                          w.gridIndex ~/ 2; // Assuming 2 widgets per row max
                      rowSpans[rowStart] =
                          (rowSpans[rowStart] ?? 0) + w.columnSpan;
                    }

                    return StaggeredGrid.count(
                      crossAxisCount:
                          40, // Increase grid resolution for finer control
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: _widgets.map((w) {
                        // Get current row's total span
                        int rowIndex = w.gridIndex ~/ 2;
                        double rowTotalSpan = rowSpans[rowIndex] ?? 4.0;

                        // Calculate proportional width
                        double widthRatio = w.columnSpan / rowTotalSpan;
                        int crossAxisCells = (40 * widthRatio).round();
                        int mainAxisCells = (w.rowSpan * 10).round();

                        return StaggeredGridTile.count(
                          crossAxisCellCount: crossAxisCells,
                          mainAxisCellCount: mainAxisCells,
                          child: _buildDashboardWidget(context, w),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
    );
  }

  void _showAddWidgetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Widget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Business Overview'),
                onTap: () {
                  final widget = DashboardWidget(
                    id: 'overview_${DateTime.now().millisecondsSinceEpoch}',
                    title: 'Company Overview',
                    widgetType: 'overview',
                    columnSpan: 2.0,
                    rowSpan: 2.0,
                    gridIndex: _widgets.length,
                  );
                  setState(() {
                    _widgets.add(widget);
                  });
                  _refreshWidget(widget);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Key Metrics'),
                onTap: () {
                  final widget = DashboardWidget(
                    id: 'metrics_${DateTime.now().millisecondsSinceEpoch}',
                    title: 'Key Metrics',
                    widgetType: 'metrics',
                    columnSpan: 2.0,
                    rowSpan: 1.0,
                    gridIndex: _widgets.length,
                  );
                  setState(() {
                    _widgets.add(widget);
                  });
                  _refreshWidget(widget);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('Stock Chart'),
                onTap: () {
                  final widget = DashboardWidget(
                    id: 'chart_${DateTime.now().millisecondsSinceEpoch}',
                    title: 'Stock Chart',
                    widgetType: 'chart',
                    columnSpan: 2.0,
                    rowSpan: 2.0,
                    gridIndex: _widgets.length,
                  );
                  setState(() {
                    _widgets.add(widget);
                  });
                  _refreshWidget(widget);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
