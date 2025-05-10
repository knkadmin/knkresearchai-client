import 'package:flutter/material.dart';
import 'package:fa_ai_agent/services/news_service.dart';
import 'package:fa_ai_agent/models/news_article.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fa_ai_agent/widgets/candlestick_chart_demo.dart';

class OverviewTab extends StatefulWidget {
  final String tickerCode;
  final String companyName;

  const OverviewTab({
    Key? key,
    required this.tickerCode,
    required this.companyName,
  }) : super(key: key);

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final NewsService _newsService = NewsService();
  final ScrollController _scrollController = ScrollController();
  List<NewsArticle> _newsArticles = [];
  bool _isLoadingNews = false;

  @override
  void initState() {
    super.initState();
    _fetchStockNews();
  }

  Future<void> _fetchStockNews() async {
    setState(() {
      _isLoadingNews = true;
    });

    try {
      final news = await _newsService.getStockNews(symbols: widget.tickerCode);
      setState(() {
        _newsArticles = news;
        _isLoadingNews = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingNews = false;
      });
      print('Error fetching news: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingNews) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Color(0xFF1E3A8A),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading overview for ${widget.companyName}...',
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_newsArticles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.newspaper,
              color: Color(0xFFCBD5E1),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No news available for ${widget.companyName}',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchStockNews,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Text(
                  '${widget.companyName} Overview',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                if (widget.tickerCode.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF1E3A8A).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.tickerCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Add the candlestick chart here
          CandlestickChartDemo(symbol: widget.tickerCode),
          const SizedBox(height: 24),
          // News section heading
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Recent News',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: _newsArticles.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey[200],
                height: 40,
                thickness: 1,
              ),
              itemBuilder: (context, index) {
                final article = _newsArticles[index];
                return _buildNewsArticleItem(article);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsArticleItem(NewsArticle article) {
    String formattedDate;
    try {
      final date = DateTime.parse(article.publishedDate);
      formattedDate = DateFormat.yMMMd().format(date);
    } catch (e) {
      formattedDate = article.publishedDate;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (article.url.isNotEmpty) {
            launchUrl(Uri.parse(article.url));
          }
        },
        borderRadius: BorderRadius.circular(16),
        hoverColor: const Color(0xFF1E3A8A).withOpacity(0.05),
        splashColor: const Color(0xFF1E3A8A).withOpacity(0.08),
        highlightColor: const Color(0xFF1E3A8A).withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.image != null && article.image!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.network(
                      article.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[100],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (article.image != null && article.image!.isNotEmpty)
                const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        article.publisher,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFF1E3A8A),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      article.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withOpacity(0.04),
                            border: Border.all(
                              color: const Color(0xFF1E3A8A).withOpacity(0.15),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.launch,
                                size: 12,
                                color: Color(0xFF1E3A8A),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Read More',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
