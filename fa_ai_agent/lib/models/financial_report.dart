import 'package:cloud_firestore/cloud_firestore.dart';

class FinancialReport {
  final String? shortname;
  final String? exchange;
  final String? sector;
  final String? ticker;
  final DateTime? lastUpdated;
  final BusinessOverview? businessOverview;
  final FinancialPerformance? financialPerformance;
  final CompetitorLandscape? competitorLandscape;
  final SupplyChain? supplyChain;
  final StrategicOutlooks? strategicOutlooks;
  final RecentNews? recentNews;
  final AccountingRedFlags? accountingRedFlags;
  final CashFlowChart? cashFlowChart;
  final PePbRatioBand? pePbRatioBand;
  final SectorStocks? sectorStocks;
  final CombinedCharts? combinedCharts;
  final StockPriceTarget? stockPriceTarget;
  final InsiderTrading? insiderTrading;
  final CandleStickChart? candleStickChart;
  final ShareholderChart? shareholderChart;
  final IndustrialRelationship? industrialRelationship;
  final SectorComparison? sectorComparison;
  final EpsVsStockPriceChart? epsVsStockPriceChart;

  FinancialReport({
    this.shortname,
    this.exchange,
    this.sector,
    this.ticker,
    this.lastUpdated,
    this.businessOverview,
    this.financialPerformance,
    this.competitorLandscape,
    this.supplyChain,
    this.strategicOutlooks,
    this.recentNews,
    this.accountingRedFlags,
    this.cashFlowChart,
    this.pePbRatioBand,
    this.sectorStocks,
    this.combinedCharts,
    this.stockPriceTarget,
    this.insiderTrading,
    this.candleStickChart,
    this.shareholderChart,
    this.industrialRelationship,
    this.sectorComparison,
    this.epsVsStockPriceChart,
  });

  factory FinancialReport.fromJson(Map<String, dynamic> json) {
    return FinancialReport(
      shortname: json['shortname'] as String?,
      exchange: json['exchange'] as String?,
      sector: json['sector'] as String?,
      ticker: json['ticker'] as String?,
      lastUpdated: json['lastUpdated'] != null
          ? (json['lastUpdated'] as Timestamp).toDate()
          : null,
      businessOverview: json['businessOverview'] != null
          ? BusinessOverview.fromJson(
              json['businessOverview'] as Map<String, dynamic>)
          : null,
      financialPerformance: json['financialPerformance'] != null
          ? FinancialPerformance.fromJson(
              json['financialPerformance'] as Map<String, dynamic>)
          : null,
      competitorLandscape: json['competitorLandscape'] != null
          ? CompetitorLandscape.fromJson(
              json['competitorLandscape'] as Map<String, dynamic>)
          : null,
      supplyChain: json['supplyChain'] != null
          ? SupplyChain.fromJson(json['supplyChain'] as Map<String, dynamic>)
          : null,
      strategicOutlooks: json['strategicOutlooks'] != null
          ? StrategicOutlooks.fromJson(
              json['strategicOutlooks'] as Map<String, dynamic>)
          : null,
      recentNews: json['recentNews'] != null
          ? RecentNews.fromJson(json['recentNews'] as Map<String, dynamic>)
          : null,
      accountingRedFlags: json['accountingRedflags'] != null
          ? AccountingRedFlags.fromJson(
              json['accountingRedflags'] as Map<String, dynamic>)
          : null,
      cashFlowChart: json['cashFlowChart'] != null
          ? CashFlowChart.fromJson(
              json['cashFlowChart'] as Map<String, dynamic>)
          : null,
      pePbRatioBand: json['pePbRatioBand'] != null
          ? PePbRatioBand.fromJson(
              json['pePbRatioBand'] as Map<String, dynamic>)
          : null,
      sectorStocks: json['sectorStocks'] != null
          ? SectorStocks.fromJson(json['sectorStocks'] as Map<String, dynamic>)
          : null,
      combinedCharts: json['combinedCharts'] != null
          ? CombinedCharts.fromJson(
              json['combinedCharts'] as Map<String, dynamic>)
          : null,
      stockPriceTarget: json['stockPriceTarget'] != null
          ? StockPriceTarget.fromJson(
              json['stockPriceTarget'] as Map<String, dynamic>)
          : null,
      insiderTrading: json['insiderTrading'] != null
          ? InsiderTrading.fromJson(
              json['insiderTrading'] as Map<String, dynamic>)
          : null,
      candleStickChart: json['candleStickChart'] != null
          ? CandleStickChart.fromJson(
              json['candleStickChart'] as Map<String, dynamic>)
          : null,
      shareholderChart: json['shareholderChart'] != null
          ? ShareholderChart.fromJson(
              json['shareholderChart'] as Map<String, dynamic>)
          : null,
      industrialRelationship: json['industrialRelationship'] != null
          ? IndustrialRelationship.fromJson(
              json['industrialRelationship'] as Map<String, dynamic>)
          : null,
      sectorComparison: json['sectorComparison'] != null
          ? SectorComparison.fromJson(
              json['sectorComparison'] as Map<String, dynamic>)
          : null,
      epsVsStockPriceChart: json['epsVsStockPriceChart'] != null
          ? EpsVsStockPriceChart.fromJson(
              json['epsVsStockPriceChart'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shortname': shortname,
      'exchange': exchange,
      'sector': sector,
      'ticker': ticker,
      'lastUpdated':
          lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
      'businessOverview': businessOverview?.toJson(),
      'financialPerformance': financialPerformance?.toJson(),
      'competitorLandscape': competitorLandscape?.toJson(),
      'supplyChain': supplyChain?.toJson(),
      'strategicOutlooks': strategicOutlooks?.toJson(),
      'recentNews': recentNews?.toJson(),
      'accountingRedFlags': accountingRedFlags?.toJson(),
      'cashFlowChart': cashFlowChart?.toJson(),
      'pePbRatioBand': pePbRatioBand?.toJson(),
      'sectorStocks': sectorStocks?.toJson(),
      'combinedCharts': combinedCharts?.toJson(),
      'stockPriceTarget': stockPriceTarget?.toJson(),
      'insiderTrading': insiderTrading?.toJson(),
      'candleStickChart': candleStickChart?.toJson(),
      'shareholderChart': shareholderChart?.toJson(),
      'industrialRelationship': industrialRelationship?.toJson(),
      'sectorComparison': sectorComparison?.toJson(),
      'epsVsStockPriceChart': epsVsStockPriceChart?.toJson(),
    };
  }
}

class BusinessOverview {
  final String? md;

  BusinessOverview({this.md});

  factory BusinessOverview.fromJson(Map<String, dynamic> json) {
    return BusinessOverview(md: json['md'] as String?);
  }

  Map<String, dynamic> toJson() => {'md': md};
}

class FinancialPerformance {
  final String? md;

  FinancialPerformance({this.md});

  factory FinancialPerformance.fromJson(Map<String, dynamic> json) {
    return FinancialPerformance(md: json['md'] as String?);
  }

  Map<String, dynamic> toJson() => {'md': md};
}

class CompetitorLandscape {
  final String? md;

  CompetitorLandscape({this.md});

  factory CompetitorLandscape.fromJson(Map<String, dynamic> json) {
    return CompetitorLandscape(md: json['md'] as String?);
  }

  Map<String, dynamic> toJson() => {'md': md};
}

class SupplyChain {
  final String? md;

  SupplyChain({this.md});

  factory SupplyChain.fromJson(Map<String, dynamic> json) {
    return SupplyChain(md: json['md'] as String?);
  }

  Map<String, dynamic> toJson() => {'md': md};
}

class StrategicOutlooks {
  final String? md;

  StrategicOutlooks({this.md});

  factory StrategicOutlooks.fromJson(Map<String, dynamic> json) {
    return StrategicOutlooks(md: json['md'] as String?);
  }

  Map<String, dynamic> toJson() => {'md': md};
}

class RecentNews {
  final String? md;

  RecentNews({this.md});

  factory RecentNews.fromJson(Map<String, dynamic> json) {
    return RecentNews(md: json['md'] as String?);
  }

  Map<String, dynamic> toJson() => {'md': md};
}

class AccountingRedFlags {
  final String? md;
  final String? mScoreRating;
  final String? incomeStatement;
  final String? balanceSheet;

  AccountingRedFlags({
    this.md,
    this.mScoreRating,
    this.incomeStatement,
    this.balanceSheet,
  });

  factory AccountingRedFlags.fromJson(Map<String, dynamic> json) {
    return AccountingRedFlags(
      md: json['md'] as String?,
      mScoreRating: json['mScoreRating'] as String?,
      incomeStatement: json['incomeStatement'] as String?,
      balanceSheet: json['balanceSheet'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'md': md,
        'mScoreRating': mScoreRating,
        'incomeStatement': incomeStatement,
        'balanceSheet': balanceSheet,
      };
}

class CashFlowChart {
  final String? imageUrl;

  CashFlowChart({this.imageUrl});

  factory CashFlowChart.fromJson(Map<String, dynamic> json) {
    return CashFlowChart(imageUrl: json['imageUrl'] as String?);
  }

  Map<String, dynamic> toJson() => {'imageUrl': imageUrl};
}

class PePbRatioBand {
  final String? imageUrl;

  PePbRatioBand({this.imageUrl});

  factory PePbRatioBand.fromJson(Map<String, dynamic> json) {
    return PePbRatioBand(imageUrl: json['imageUrl'] as String?);
  }

  Map<String, dynamic> toJson() => {'imageUrl': imageUrl};
}

class SectorStocks {
  final String? imageUrl;

  SectorStocks({this.imageUrl});

  factory SectorStocks.fromJson(Map<String, dynamic> json) {
    return SectorStocks(imageUrl: json['imageUrl'] as String?);
  }

  Map<String, dynamic> toJson() => {'imageUrl': imageUrl};
}

class CombinedCharts {
  final String? imageUrl;

  CombinedCharts({this.imageUrl});

  factory CombinedCharts.fromJson(Map<String, dynamic> json) {
    return CombinedCharts(imageUrl: json['imageUrl'] as String?);
  }

  Map<String, dynamic> toJson() => {'imageUrl': imageUrl};
}

class StockPriceTarget {
  final String? imageUrl;

  StockPriceTarget({this.imageUrl});

  factory StockPriceTarget.fromJson(Map<String, dynamic> json) {
    return StockPriceTarget(imageUrl: json['imageUrl'] as String?);
  }

  Map<String, dynamic> toJson() => {'imageUrl': imageUrl};
}

class InsiderTrading {
  final String? imageUrl;

  InsiderTrading({this.imageUrl});

  factory InsiderTrading.fromJson(Map<String, dynamic> json) {
    return InsiderTrading(imageUrl: json['imageUrl'] as String?);
  }

  Map<String, dynamic> toJson() => {'imageUrl': imageUrl};
}

class CandleStickChart {
  final String? imageUrl;
  final String? md;

  CandleStickChart({this.imageUrl, this.md});

  factory CandleStickChart.fromJson(Map<String, dynamic> json) {
    return CandleStickChart(
      imageUrl: json['imageUrl'] as String?,
      md: json['md'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'imageUrl': imageUrl,
        'md': md,
      };
}

class ShareholderChart {
  final String? imageUrl;

  ShareholderChart({this.imageUrl});

  factory ShareholderChart.fromJson(Map<String, dynamic> json) {
    return ShareholderChart(imageUrl: json['imageUrl'] as String?);
  }

  Map<String, dynamic> toJson() => {'imageUrl': imageUrl};
}

class IndustrialRelationship {
  final String? imageUrl;

  IndustrialRelationship({this.imageUrl});

  factory IndustrialRelationship.fromJson(Map<String, dynamic> json) {
    return IndustrialRelationship(imageUrl: json['imageUrl'] as String?);
  }

  Map<String, dynamic> toJson() => {'imageUrl': imageUrl};
}

class SectorComparison {
  final String? imageUrl;

  SectorComparison({this.imageUrl});

  factory SectorComparison.fromJson(Map<String, dynamic> json) {
    return SectorComparison(imageUrl: json['imageUrl'] as String?);
  }

  Map<String, dynamic> toJson() => {'imageUrl': imageUrl};
}

class EpsVsStockPriceChart {
  final String? imageUrl;
  final String? md;

  EpsVsStockPriceChart({this.imageUrl, this.md});

  factory EpsVsStockPriceChart.fromJson(Map<String, dynamic> json) {
    return EpsVsStockPriceChart(
      imageUrl: json['imageUrl'] as String?,
      md: json['md'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'imageUrl': imageUrl,
        'md': md,
      };
}
