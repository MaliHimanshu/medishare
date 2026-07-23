import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/hospital_model.dart';

class HospitalProvider extends ChangeNotifier {
  final Dio _dio = DioClient.instance;

  List<HospitalModel> _hospitals = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Search & Filters
  String _searchQuery = '';
  String _selectedCity = 'All';
  String _selectedState = 'All';

  // Getters
  List<HospitalModel> get hospitals => _hospitals;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCity => _selectedCity;
  String get selectedState => _selectedState;

  List<String> get availableCities {
    final cities = _hospitals.map((h) => h.city).where((c) => c.isNotEmpty).toSet().toList();
    cities.sort();
    return ['All', ...cities];
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCityFilter(String city) {
    _selectedCity = city;
    notifyListeners();
  }

  void setStateFilter(String stateName) {
    _selectedState = stateName;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCity = 'All';
    _selectedState = 'All';
    notifyListeners();
  }

  // ── Getter: Filtered Hospitals ─────────────────────────────────────
  List<HospitalModel> get filteredHospitals {
    List<HospitalModel> list = List.from(_hospitals);

    // 1. Filter by Search Query (Name, City, State)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((item) {
        final name = item.hospitalName.toLowerCase();
        final city = item.city.toLowerCase();
        final state = item.state.toLowerCase();
        return name.contains(query) || city.contains(query) || state.contains(query);
      }).toList();
    }

    // 2. Filter by City
    if (_selectedCity != 'All') {
      list = list.where((item) => item.city.toLowerCase() == _selectedCity.toLowerCase()).toList();
    }

    // 3. Filter by State
    if (_selectedState != 'All') {
      list = list.where((item) => item.state.toLowerCase() == _selectedState.toLowerCase()).toList();
    }

    return list;
  }

  // ── Fetch Hospitals (GET /api/hospital) ───────────────────────────
  Future<void> fetchHospitals() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.get(ApiEndpoints.hospital);
      if (response.data != null && response.data['success'] == true) {
        final rawData = response.data['hospitals'] ?? response.data['data'];
        if (rawData is List) {
          _hospitals = rawData
              .map((item) => HospitalModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } else {
        _errorMessage = response.data?['message'] ?? 'Failed to load hospitals.';
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

  // ── Get Hospital By ID (GET /api/hospital/:id) ───────────────────
  Future<HospitalModel?> getHospitalById(String id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.hospital}/$id');
      if (response.data != null && response.data['success'] == true) {
        return HospitalModel.fromJson(
            response.data['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return _hospitals.firstWhere((item) => item.id == id,
        orElse: () => throw Exception('Hospital not found'));
  }

  // ── Add Hospital (POST /api/hospital) ─────────────────────────────
  Future<bool> addHospital({
    required String hospitalName,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required String phone,
    required String email,
    String? website,
    String? description,
    String? image,
    String? contactPerson,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final payload = {
        'hospitalName': hospitalName,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'phone': phone,
        'email': email,
        if (website != null && website.isNotEmpty) 'website': website,
        if (description != null && description.isNotEmpty) 'description': description,
        if (image != null && image.isNotEmpty) 'image': image,
        if (contactPerson != null && contactPerson.isNotEmpty) 'contactPerson': contactPerson,
      };

      final response = await _dio.post(ApiEndpoints.hospital, data: payload);
      if (response.data != null && response.data['success'] == true) {
        final newHosp = HospitalModel.fromJson(
            response.data['data'] as Map<String, dynamic>);
        _hospitals.insert(0, newHosp);
        return true;
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Failed to add hospital.';
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

  // ── Update Hospital (PUT /api/hospital/:id) ───────────────────────
  Future<bool> updateHospital(
    String id, {
    required String hospitalName,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required String phone,
    required String email,
    String? website,
    String? description,
    String? image,
    String? contactPerson,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final payload = {
        'hospitalName': hospitalName,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'phone': phone,
        'email': email,
        if (website != null && website.isNotEmpty) 'website': website,
        if (description != null && description.isNotEmpty) 'description': description,
        if (image != null && image.isNotEmpty) 'image': image,
        if (contactPerson != null && contactPerson.isNotEmpty) 'contactPerson': contactPerson,
      };

      final response = await _dio.put('${ApiEndpoints.hospital}/$id', data: payload);
      if (response.data != null && response.data['success'] == true) {
        final updated = HospitalModel.fromJson(
            response.data['data'] as Map<String, dynamic>);
        final idx = _hospitals.indexWhere((item) => item.id == id);
        if (idx != -1) {
          _hospitals[idx] = updated;
        }
        return true;
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Failed to update hospital.';
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

  // ── Delete Hospital (DELETE /api/hospital/:id) ────────────────────
  Future<bool> deleteHospital(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.delete('${ApiEndpoints.hospital}/$id');
      if (response.data != null && response.data['success'] == true) {
        _hospitals.removeWhere((item) => item.id == id);
        return true;
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Failed to delete hospital.';
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
}
