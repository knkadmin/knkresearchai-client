import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/pricing_plan.dart';

class PricingService extends ChangeNotifier {
  static final PricingService _instance = PricingService._internal();
  factory PricingService() => _instance;
  PricingService._internal();

  Map<String, PricingPlan> _pricingPlans = {};
  bool _isLoading = false;
  bool _hasError = false;
  StreamSubscription? _subscription;

  Map<String, PricingPlan> get pricingPlans => _pricingPlans;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  bool get hasData => _pricingPlans.isNotEmpty;

  void initialize() {
    if (_subscription != null) return;

    _isLoading = true;
    _hasError = false;
    notifyListeners();

    _subscription = FirebaseFirestore.instance
        .collection('pricing')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isEmpty) {
        _hasError = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _pricingPlans = {
        for (var doc in snapshot.docs)
          doc.data()['type'] as String: PricingPlan.fromFirestore(doc.data())
      };
      _isLoading = false;
      _hasError = false;
      notifyListeners();
    }, onError: (error) {
      _isLoading = false;
      _hasError = true;
      notifyListeners();
    });
  }

  void retry() {
    _subscription?.cancel();
    _subscription = null;
    initialize();
  }
}
