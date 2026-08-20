import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/equipment_model.dart';

class EquipmentProvider extends ChangeNotifier {
  final Dio _dio = DioClient.instance;

  List<EquipmentModel> _equipment = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Filter & Search states
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedCondition = 'All';
  String _selectedStatus = 'All';
  String _selectedSort = 'Newest';

  // ── Nearby Equipment State ──────────────────────────────
  List<EquipmentModel> _nearbyEquipment = [];
  Map<String, dynamic>? _nearbyMeta;
  bool _isLoadingNearby = false;
  String _nearbyError = '';

  // Getters
  List<EquipmentModel> get equipment => _equipment;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedCondition => _selectedCondition;
  String get selectedStatus => _selectedStatus;
  String get selectedSort => _selectedSort;

  // Nearby getters
  List<EquipmentModel> get nearbyEquipment => _nearbyEquipment;
  Map<String, dynamic>? get nearbyMeta => _nearbyMeta;
  bool get isLoadingNearby => _isLoadingNearby;
  String get nearbyError => _nearbyError;

  // Setters for search and filter (each notifies listeners to redraw catalog instantly)
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilters({
    required String category,
    required String condition,
    required String status,
    required String sort,
  }) {
    _selectedCategory = category;
    _selectedCondition = condition;
    _selectedStatus = status;
    _selectedSort = sort;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _selectedCondition = 'All';
    _selectedStatus = 'All';
    _selectedSort = 'Newest';
    notifyListeners();
  }

  // ── Getter: Filtered & Sorted Equipment ────────────────────────────
  List<EquipmentModel> get filteredEquipment {
    List<EquipmentModel> list = List.from(_equipment);

    // 1. Filter by Search Query (Name, Category, Donor)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query) ||
            item.donor.toLowerCase().contains(query) ||
            item.manufacturer.toLowerCase().contains(query);
      }).toList();
    }

    // 2. Filter by Category
    if (_selectedCategory.isNotEmpty && _selectedCategory != 'All') {
      list = list.where((item) => item.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    // 3. Filter by Condition
    if (_selectedCondition.isNotEmpty && _selectedCondition != 'All') {
      list = list.where((item) => item.condition.toUpperCase() == _selectedCondition.toUpperCase()).toList();
    }

    // 4. Filter by Status
    if (_selectedStatus.isNotEmpty && _selectedStatus != 'All') {
      list = list.where((item) => item.status.toUpperCase() == _selectedStatus.toUpperCase()).toList();
    }

    // 5. Sort Options
    if (_selectedSort == 'Newest') {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_selectedSort == 'Oldest') {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_selectedSort == 'A-Z') {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_selectedSort == 'Z-A') {
      list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    } else if (_selectedSort == 'Quantity') {
      list.sort((a, b) => b.quantity.compareTo(a.quantity));
    } else if (_selectedSort == 'Availability') {
      // Sort AVAILABLE first
      list.sort((a, b) {
        if (a.status == 'AVAILABLE' && b.status != 'AVAILABLE') return -1;
        if (a.status != 'AVAILABLE' && b.status == 'AVAILABLE') return 1;
        return 0;
      });
    }

    return list;
  }

  // ── Fetch Equipment List (GET /api/equipment) ──────────────────────
  Future<void> fetchEquipment() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.get(ApiEndpoints.equipment);
      if (response.data != null && response.data['success'] == true) {
        final listData = response.data['data'] as List<dynamic>;
        _equipment = listData.map((item) => EquipmentModel.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        _errorMessage = response.data?['message'] ?? 'Failed to load equipment catalog.';
      }
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Add Equipment Listing (POST /api/equipment) ────────────────────
  Future<bool> addEquipment({
    required String name,
    required String category,
    required String condition,
    required int quantity,
    String? manufacturer,
    String? description,
    String? location,
    String? image,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final payload = {
        'name': name,
        'category': category,
        'condition': condition.toUpperCase(),
        'quantity': quantity,
        if (manufacturer != null && manufacturer.isNotEmpty) 'manufacturer': manufacturer,
        if (description != null && description.isNotEmpty) 'description': description,
        if (location != null && location.isNotEmpty) 'location': location,
        if (image != null && image.isNotEmpty) 'image': image,
      };

      final response = await _dio.post(ApiEndpoints.equipment, data: payload);
      if (response.data != null && response.data['success'] == true) {
        final newEquip = EquipmentModel.fromJson(response.data['data'] as Map<String, dynamic>);
        _equipment.insert(0, newEquip);
        return true;
      } else {
        _errorMessage = response.data?['message'] ?? 'Failed to list equipment.';
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Update Equipment Listing (PUT /api/equipment/:id) ──────────────
  Future<bool> updateEquipment(
    String id, {
    required String name,
    required String category,
    required String condition,
    required int quantity,
    required String status,
    String? manufacturer,
    String? description,
    String? location,
    String? image,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final payload = {
        'name': name,
        'category': category,
        'condition': condition.toUpperCase(),
        'quantity': quantity,
        'status': status.toUpperCase(),
        if (manufacturer != null && manufacturer.isNotEmpty) 'manufacturer': manufacturer,
        if (description != null && description.isNotEmpty) 'description': description,
        if (location != null && location.isNotEmpty) 'location': location,
        if (image != null && image.isNotEmpty) 'image': image,
      };

      final response = await _dio.put('${ApiEndpoints.equipment}/$id', data: payload);
      if (response.data != null && response.data['success'] == true) {
        final updated = EquipmentModel.fromJson(response.data['data'] as Map<String, dynamic>);
        final idx = _equipment.indexWhere((item) => item.id == id);
        if (idx != -1) {
          _equipment[idx] = updated;
        }
        return true;
      } else {
        _errorMessage = response.data?['message'] ?? 'Failed to update equipment listing.';
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Delete Equipment Listing (DELETE /api/equipment/:id) ───────────
  Future<bool> deleteEquipment(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.delete('${ApiEndpoints.equipment}/$id');
      if (response.data != null && response.data['success'] == true) {
        _equipment.removeWhere((item) => item.id == id);
        return true;
      } else {
        _errorMessage = response.data?['message'] ?? 'Failed to delete equipment listing.';
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Request Equipment (POST /api/request) ──────────────────────────
  Future<bool> requestEquipment({
    required String equipmentId,
    required String reason,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.post(ApiEndpoints.request, data: {
        'equipmentId': equipmentId,
        'reason': reason,
      });
      if (response.data != null && response.data['success'] == true) {
        return true;
      } else {
        _errorMessage = response.data?['message'] ?? 'Failed to request equipment.';
        return false;
      }
    } on DioException catch (e) {
      _errorMessage = DioClient.handleError(e);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch Nearby Equipment (GET /api/equipment/nearby) ─────────────
  Future<void> fetchNearbyEquipment({
    required double latitude,
    required double longitude,
    double radius = 20,
    String? category,
    String? mode,
  }) async {
    _isLoadingNearby = true;
    _nearbyError = '';
    _nearbyEquipment = [];
    _nearbyMeta = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
        if (category != null && category != 'All') 'category': category,
        if (mode != null && mode != 'All') 'mode': mode,
      };

      final response = await _dio.get(
        ApiEndpoints.nearbyEquipment,
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['success'] == true) {
        final listData = response.data['equipment'] as List<dynamic>? ?? [];
        _nearbyEquipment = listData
            .map((item) =>
                EquipmentModel.fromJson(item as Map<String, dynamic>))
            .toList();
        _nearbyMeta = {
          'count': response.data['count'] ?? _nearbyEquipment.length,
          'location': response.data['location'],
          'radius': response.data['radius'] ?? radius,
          'radiusUnit': response.data['radiusUnit'] ?? 'km',
        };
      } else {
        _nearbyError =
            response.data?['message'] ?? 'Failed to load nearby equipment.';
      }
    } on DioException catch (e) {
      _nearbyError = DioClient.handleError(e);
    } catch (e) {
      _nearbyError = 'An unexpected error occurred: $e';
    } finally {
      _isLoadingNearby = false;
      notifyListeners();
    }
  }
}
