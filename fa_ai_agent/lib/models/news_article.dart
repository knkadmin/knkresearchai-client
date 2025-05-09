class NewsArticle {
  final String? image;
  final String publishedDate;
  final String publisher;
  final String site;
  final String? symbol;
  final String text;
  final String title;
  final String url;

  NewsArticle({
    this.image,
    required this.publishedDate,
    required this.publisher,
    required this.site,
    this.symbol,
    required this.text,
    required this.title,
    required this.url,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      image: json['image'] as String?,
      publishedDate: json['publishedDate'] as String,
      publisher: json['publisher'] as String,
      site: json['site'] as String,
      symbol: json['symbol'] as String?,
      text: json['text'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'publishedDate': publishedDate,
      'publisher': publisher,
      'site': site,
      'symbol': symbol,
      'text': text,
      'title': title,
      'url': url,
    };
  }
}
