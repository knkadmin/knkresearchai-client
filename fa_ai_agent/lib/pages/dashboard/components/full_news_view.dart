import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fa_ai_agent/services/news_service.dart';
import 'package:fa_ai_agent/models/news_article.dart';
import 'package:fa_ai_agent/widgets/animations/thinking_animation.dart';

class FullNewsView extends StatefulWidget {
  final VoidCallback onClose;
  final String initialNewsType;

  const FullNewsView({
    Key? key,
    required this.onClose,
    this.initialNewsType = 'Market News',
  }) : super(key: key);

  @override
  State<FullNewsView> createState() => _FullNewsViewState();
}

class _FullNewsViewState extends State<FullNewsView>
    with SingleTickerProviderStateMixin {
  late String _currentNewsType;
  final NewsService _newsService = NewsService();
  late Future<List<NewsArticle>> _newsFuture;

  // Shimmer animation controller
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _currentNewsType = widget.initialNewsType;
    // Initialize the future once
    _newsFuture = _getNewsByType(_currentNewsType);

    // Setup shimmer controller and animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<List<NewsArticle>> _getNewsByType(String newsType) {
    switch (newsType) {
      case 'Market News':
        return _newsService.getGeneralNews();
      case 'Press Releases':
        return _newsService.getPressReleasesLatest();
      case 'Stock News':
        return _newsService.getStockLatestNews();
      default:
        return _newsService.getGeneralNews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Card(
          color: Colors.white,
          elevation: 8,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 900,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with title and close button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Financial News',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onClose,
                        icon: const Icon(
                          Icons.close,
                          size: 24,
                          color: Color(0xFF1E3A8A),
                        ),
                        padding: const EdgeInsets.all(8),
                        splashRadius: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // News type tabs
                  Row(
                    children: [
                      _buildNewsTab('Market News'),
                      const SizedBox(width: 8),
                      _buildNewsTab('Press Releases'),
                      const SizedBox(width: 8),
                      _buildNewsTab('Stock News'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(
                      height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 12),

                  // News content
                  Expanded(
                    child: _buildNewsContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsTab(String tabName) {
    final bool isSelected = _currentNewsType == tabName;

    return InkWell(
      onTap: () {
        setState(() {
          _currentNewsType = tabName;
          // Only update the future when tab changes
          _newsFuture = _getNewsByType(_currentNewsType);
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E3A8A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          tabName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsContent() {
    return FutureBuilder<List<NewsArticle>>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5, // Show 5 shimmer placeholders
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey[200],
              height: 32,
              thickness: 1,
            ),
            itemBuilder: (context, index) {
              return _buildNewsArticleShimmer();
            },
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red[400],
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to load news',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No articles available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          separatorBuilder: (context, index) => Divider(
            color: Colors.grey[200],
            height: 32,
            thickness: 1,
          ),
          itemBuilder: (context, index) {
            final article = snapshot.data![index];
            return _buildNewsArticleItem(article);
          },
        );
      },
    );
  }

  Widget _buildNewsArticleShimmer() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [
                      Colors.grey[300]!,
                      Colors.grey[200]!,
                      Colors.grey[300]!,
                    ],
                    stops: const [0.2, 0.5, 0.8],
                    begin: Alignment(
                      _shimmerAnimation.value - 1,
                      0,
                    ),
                    end: Alignment(
                      _shimmerAnimation.value,
                      0,
                    ),
                  ).createShader(bounds);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 160,
                    height: 120,
                    color: Colors.grey[300],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Publisher placeholder
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            Colors.grey[300]!,
                            Colors.grey[200]!,
                            Colors.grey[300]!,
                          ],
                          stops: const [0.2, 0.5, 0.8],
                          begin: Alignment(
                            _shimmerAnimation.value - 1,
                            0,
                          ),
                          end: Alignment(
                            _shimmerAnimation.value,
                            0,
                          ),
                        ).createShader(bounds);
                      },
                      child: Container(
                        width: 120,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Title placeholder
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            Colors.grey[300]!,
                            Colors.grey[200]!,
                            Colors.grey[300]!,
                          ],
                          stops: const [0.2, 0.5, 0.8],
                          begin: Alignment(
                            _shimmerAnimation.value - 1,
                            0,
                          ),
                          end: Alignment(
                            _shimmerAnimation.value,
                            0,
                          ),
                        ).createShader(bounds);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 20,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity * 0.7,
                            height: 20,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Content placeholder
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            Colors.grey[300]!,
                            Colors.grey[200]!,
                            Colors.grey[300]!,
                          ],
                          stops: const [0.2, 0.5, 0.8],
                          begin: Alignment(
                            _shimmerAnimation.value - 1,
                            0,
                          ),
                          end: Alignment(
                            _shimmerAnimation.value,
                            0,
                          ),
                        ).createShader(bounds);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 14,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            height: 14,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity * 0.6,
                            height: 14,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Date placeholder
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            Colors.grey[300]!,
                            Colors.grey[200]!,
                            Colors.grey[300]!,
                          ],
                          stops: const [0.2, 0.5, 0.8],
                          begin: Alignment(
                            _shimmerAnimation.value - 1,
                            0,
                          ),
                          end: Alignment(
                            _shimmerAnimation.value,
                            0,
                          ),
                        ).createShader(bounds);
                      },
                      child: Container(
                        width: 100,
                        height: 16,
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewsArticleItem(NewsArticle article) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchNewsUrl(article.url),
        borderRadius: BorderRadius.circular(16),
        hoverColor: const Color(0xFF1E3A8A).withOpacity(0.05),
        splashColor: const Color(0xFF1E3A8A).withOpacity(0.08),
        highlightColor: const Color(0xFF1E3A8A).withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 160,
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
              if (article.image != null) const SizedBox(width: 20),
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
                    ),
                    const SizedBox(height: 10),
                    Text(
                      article.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
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
                        const SizedBox(width: 4),
                        Text(
                          _formatPublishedDate(article.publishedDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (article.symbol != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              article.symbol!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
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

  String _formatPublishedDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat.yMMMd().format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _launchNewsUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
