import 'package:flutter/material.dart';
import 'package:fa_ai_agent/models/news_article.dart';
import 'package:fa_ai_agent/services/auth_service.dart';
import 'package:fa_ai_agent/services/news_service.dart';
import 'package:fa_ai_agent/widgets/company_button.dart';
import 'package:fa_ai_agent/widgets/search_bar.dart' show CustomSearchBar;
import 'package:fa_ai_agent/constants/company_data.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CombinedSearchNewsCard extends StatefulWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Function(String) onSearchChanged;
  final Function(String, String) onNavigateToReport;
  final List<Map<String, dynamic>> searchResults;
  final Function() onHideSearchResults;
  final GlobalKey searchCardKey;

  const CombinedSearchNewsCard({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.onNavigateToReport,
    required this.searchResults,
    required this.onHideSearchResults,
    required this.searchCardKey,
  });

  @override
  State<CombinedSearchNewsCard> createState() => _CombinedSearchNewsCardState();
}

class _CombinedSearchNewsCardState extends State<CombinedSearchNewsCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  late List<Animation<double>> _buttonAnimations;
  final NewsService _newsService = NewsService();
  late Future<List<NewsArticle>> _newsFuture;
  late Future<List<NewsArticle>> _pressReleasesFuture;
  late Future<List<NewsArticle>> _stockNewsFuture;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

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

    _newsFuture = _newsService.getGeneralNews();
    _pressReleasesFuture = _newsService.getPressReleasesLatest();
    _stockNewsFuture = _newsService.getStockLatestNews();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  String _formatPublishedDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return DateFormat.yMMMd().format(date);
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Center(
        child: Container(
          child: _buildVerticalLayout(),
        ),
      ),
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Search Section - Top
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSearchHeader(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: CustomSearchBar(
                      key: widget.searchCardKey,
                      controller: widget.searchController,
                      focusNode: widget.searchFocusNode,
                      onChanged: widget.onSearchChanged,
                      hintText: 'Search company or ticker...',
                      onClear: () {
                        widget.searchController.clear();
                        widget.onHideSearchResults();
                      },
                      width: double.infinity,
                      showBorder: true,
                      showShadow: false,
                    ),
                  ),
                ),
              ),
              if (AuthService().currentUser != null) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildPopularCompaniesSection(),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),

        // Horizontal Spacer
        const SizedBox(height: 20),

        // News Sections Row
        _buildNewsRow(),
      ],
    );
  }

  Widget _buildNewsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 800;

        if (isSmallScreen) {
          // Vertical layout for small screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNewsSection(
                title: 'Market News',
                icon: Icons.newspaper_outlined,
                newsFuture: _newsFuture,
              ),
              const Divider(
                height: 32,
                thickness: 1,
                color: Color(0xFFE5E7EB),
              ),
              _buildNewsSection(
                title: 'Press Releases',
                icon: Icons.feed_outlined,
                newsFuture: _pressReleasesFuture,
              ),
              const Divider(
                height: 32,
                thickness: 1,
                color: Color(0xFFE5E7EB),
              ),
              _buildNewsSection(
                title: 'Stock News',
                icon: Icons.trending_up_outlined,
                newsFuture: _stockNewsFuture,
              ),
            ],
          );
        } else {
          // Horizontal layout for larger screens
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 1,
                child: _buildNewsSection(
                  title: 'Market News',
                  icon: Icons.newspaper_outlined,
                  newsFuture: _newsFuture,
                ),
              ),
              const VerticalDivider(
                width: 28,
                thickness: 1,
                color: Color(0xFFE5E7EB),
                indent: 10,
                endIndent: 10,
              ),
              Expanded(
                flex: 1,
                child: _buildNewsSection(
                  title: 'Press Releases',
                  icon: Icons.feed_outlined,
                  newsFuture: _pressReleasesFuture,
                ),
              ),
              const VerticalDivider(
                width: 28,
                thickness: 1,
                color: Color(0xFFE5E7EB),
                indent: 10,
                endIndent: 10,
              ),
              Expanded(
                flex: 1,
                child: _buildNewsSection(
                  title: 'Stock News',
                  icon: Icons.trending_up_outlined,
                  newsFuture: _stockNewsFuture,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildNewsSection({
    required String title,
    required IconData icon,
    required Future<List<NewsArticle>> newsFuture,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.transparent,
          width: 0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          _buildNewsContent(newsFuture),
        ],
      ),
    );
  }

  Widget _buildNewsContent(Future<List<NewsArticle>> newsFuture) {
    return FutureBuilder<List<NewsArticle>>(
      future: newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              // Show 3 loading spinners in list format
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.grey[200],
                  height: 28,
                  thickness: 1,
                ),
                itemBuilder: (context, index) {
                  return _buildLoadingListItem();
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[400],
                    size: 32,
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
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(30.0),
              child: Text('No articles available'),
            ),
          );
        }

        return Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length > 3 ? 3 : snapshot.data!.length,
              separatorBuilder: (context, index) => Divider(
                color: Colors.grey[200],
                height: 28,
                thickness: 1,
              ),
              itemBuilder: (context, index) {
                final article = snapshot.data![index];
                return _buildNewsArticleItem(article);
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // Action for viewing more news
                },
                icon: const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: Color(0xFF1E3A8A),
                ),
                label: const Text(
                  'View more',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                    letterSpacing: -0.2,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.04),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingListItem() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ShaderMask(
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Publisher placeholder
                      Container(
                        width: 80,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title placeholder
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Content placeholder
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Stock Search',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Search for any US-listed company',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPopularCompaniesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<Map<String, String>>>(
          stream: CompanyData.streamMega7CompaniesForButtons(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final companies = snapshot.data!;
            _buttonAnimations = List.generate(
              companies.length,
              (index) => CurvedAnimation(
                parent: _animationController,
                curve: Interval(
                  0.1 * index,
                  0.1 * index + 0.3,
                  curve: Curves.easeOut,
                ),
              ),
            );
            _animationController.forward();

            return Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: companies.asMap().entries.map((entry) {
                  final index = entry.key;
                  final company = entry.value;
                  final symbol = company.keys.toList().first;
                  final name = company.values.toList().first;
                  return AnimatedBuilder(
                    animation: _buttonAnimations[index],
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                            0, 20 * (1 - _buttonAnimations[index].value)),
                        child: Opacity(
                          opacity: _buttonAnimations[index].value,
                          child: child,
                        ),
                      );
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: InkWell(
                          onTap: () => widget.onNavigateToReport(symbol, name),
                          borderRadius: BorderRadius.circular(20),
                          hoverColor: const Color(0xFF1E3A8A).withOpacity(0.15),
                          splashColor: const Color(0xFF1E3A8A).withOpacity(0.1),
                          highlightColor:
                              const Color(0xFF1E3A8A).withOpacity(0.05),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Text(
                                symbol,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNewsArticleItem(NewsArticle article) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchUrl(article.url),
        borderRadius: BorderRadius.circular(16),
        hoverColor: const Color(0xFF1E3A8A).withOpacity(0.05),
        splashColor: const Color(0xFF1E3A8A).withOpacity(0.08),
        highlightColor: const Color(0xFF1E3A8A).withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 100,
                    height: 100,
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
              if (article.image != null) const SizedBox(width: 14),
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
                    const SizedBox(height: 10),
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      article.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
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
}
