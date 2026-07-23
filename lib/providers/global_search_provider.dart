import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/equipment_model.dart';
import '../models/donation_model.dart';
import '../models/request_model.dart';
import '../models/hospital_model.dart';

class GlobalSearchProvider extends ChangeNotifier {
  static const String _recentPrefKey = 'medishare_recent_searches';
  final Dio _dio = DioClient.instance;

  String _query = '';
  String _selectedFilter = 'All';
  bool _isSearching = false;
  String _errorMessage = '';

  List<EquipmentModel> _equipmentResults = [];
  List<DonationModel> _donationResults = [];
  List<RequestModel> _requestResults = [];
  List<HospitalModel> _hospitalResults = [];
  List<String> _recentSearches = [];

  // Getters
  String get query => _query;
  String get selectedFilter => _selectedFilter;
  bool get isSearching => _isSearching;
  String get errorMessage => _errorMessage;

  List<EquipmentModel> get equipmentResults => _equipmentResults;
  List<DonationModel> get donationResults => _donationResults;
  List<RequestModel> get requestResults => _requestResults;
  List<HospitalModel> get hospitalResults => _hospitalResults;
  List<String> get recentSearches => _recentSearches;

  int get totalResultsCount =>
      _equipmentResults.length +
      _donationResults.length +
      _requestResults.length +
      _hospitalResults.length;

  GlobalSearchProvider() {
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _recentSearches = prefs.getStringList(_recentPrefKey) ?? ['Wheelchair', 'Hospital Bed', 'Oxygen', 'Civil Hospital'];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> addRecentSearch(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;

    _recentSearches.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentPrefKey, _recentSearches);
    } catch (_) {}
  }

  Future<void> removeRecentSearch(String term) async {
    _recentSearches.removeWhere((item) => item == term);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentPrefKey, _recentSearches);
    } catch (_) {}
  }

  Future<void> clearRecentSearches() async {
    _recentSearches.clear();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentPrefKey);
    } catch (_) {}
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  // ── Universal Global Search Across All Modules ───────────────────────
  Future<void> search(String searchQuery) async {
    final trimmed = searchQuery.trim();
    _query = trimmed;
    _errorMessage = '';

    if (trimmed.isEmpty) {
      _equipmentResults = [];
      _donationResults = [];
      _requestResults = [];
      _hospitalResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    final queryLower = trimmed.toLowerCase();

    try {
      // Execute multi-module requests concurrently
      final futures = await Future.wait([
        _dio.get(ApiEndpoints.equipment),
        _dio.get(ApiEndpoints.donation),
        _dio.get(ApiEndpoints.request),
        _dio.get(ApiEndpoints.hospital),
      ]);

      // 1. Equipment Results
      if (futures[0].data != null && futures[0].data['success'] == true) {
        final List listData = futures[0].data['data'] ?? [];
        final items = listData.map((json) => EquipmentModel.fromJson(json)).toList();
        _equipmentResults = items.where((item) {
          return item.name.toLowerCase().contains(queryLower) ||
              item.category.toLowerCase().contains(queryLower) ||
              item.donor.toLowerCase().contains(queryLower);
        }).toList();
      }

      // 2. Donation Results
      if (futures[1].data != null && futures[1].data['success'] == true) {
        final List listData = futures[1].data['data'] ?? [];
        final items = listData.map((json) => DonationModel.fromJson(json)).toList();
        _donationResults = items.where((item) {
          return (item.equipment?.name.toLowerCase().contains(queryLower) ?? false) ||
              (item.equipment?.category.toLowerCase().contains(queryLower) ?? false) ||
              item.donorName.toLowerCase().contains(queryLower) ||
              item.hospital.toLowerCase().contains(queryLower);
        }).toList();
      }

      // 3. Request Results
      if (futures[2].data != null && futures[2].data['success'] == true) {
        final List listData = futures[2].data['data'] ?? [];
        final items = listData.map((json) => RequestModel.fromJson(json)).toList();
        _requestResults = items.where((item) {
          return (item.equipment?.name.toLowerCase().contains(queryLower) ?? false) ||
              (item.equipment?.category.toLowerCase().contains(queryLower) ?? false) ||
              item.requesterName.toLowerCase().contains(queryLower) ||
              item.hospital.toLowerCase().contains(queryLower);
        }).toList();
      }

      // 4. Hospital Results
      if (futures[3].data != null && futures[3].data['success'] == true) {
        final List listData = futures[3].data['data'] ?? [];
        final items = listData.map((json) => HospitalModel.fromJson(json)).toList();
        _hospitalResults = items.where((item) {
          return item.hospitalName.toLowerCase().contains(queryLower) ||
              item.city.toLowerCase().contains(queryLower) ||
              item.state.toLowerCase().contains(queryLower) ||
              item.address.toLowerCase().contains(queryLower);
        }).toList();
      }

      // Save to search history
      addRecentSearch(trimmed);
    } catch (e) {
      _errorMessage = 'Error performing global search: $e';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }
}
