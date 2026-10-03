import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

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
      list = list
          .where(
            (item) =>
                item.category.toLowerCase() == _selectedCategory.toLowerCase(),
          )
          .toList();
    }

    // 3. Filter by Condition
    if (_selectedCondition.isNotEmpty && _selectedCondition != 'All') {
      list = list
          .where(
            (item) =>
                item.condition.toUpperCase() ==
                _selectedCondition.toUpperCase(),
          )
          .toList();
    }

    // 4. Filter by Status
    if (_selectedStatus.isNotEmpty && _selectedStatus != 'All') {
      list = list
          .where(
            (item) =>
                item.status.toUpperCase() == _selectedStatus.toUpperCase(),
          )
          .toList();
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
      final db = FirebaseFirestore.instance;
      final snapshot = await db.collection('equipment').get();
      _equipment = snapshot.docs.map((doc) {
        final data = doc.data();
        return EquipmentModel(
          id: data['id'] ?? doc.id,
          ownerId: data['ownerId'] ?? '',
          name: data['name'] ?? 'Unknown',
          category: data['category'] ?? 'Other',
          condition: data['condition'] ?? 'Good',
          status: data['status'] ?? 'AVAILABLE',
          quantity: data['quantity'] ?? 1,
          mode: data['mode'] ?? 'DONATE',
          createdAt: data['createdAt'] ?? DateTime.now().toIso8601String(),
          updatedAt: data['updatedAt'] ?? DateTime.now().toIso8601String(),
          donor: data['donor'] ?? '',
          location: data['location'] ?? '',
          latitude: data['latitude'],
          longitude: data['longitude'],
          image: data['image'] ?? '',
          images: List<String>.from(data['images'] ?? []),
          manufacturer: data['manufacturer'] ?? '',
          description: data['description'] ?? '',
        );
      }).toList();
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addEquipment({
    required String name,
    required String category,
    required String condition,
    required int quantity,
    String mode = 'DONATE',
    double? rentalPricePerDay,
    double? securityDeposit,
    String? manufacturer,
    String? description,
    String? location,
    String? image,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      debugPrint('[SAVE_DEBUG] 05 provider.addEquipment ENTERED');
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _errorMessage = 'Please log in to continue.';
        return false;
      }
      
      final db = FirebaseFirestore.instance;
      final newDoc = db.collection('equipment').doc();
      final newEquip = EquipmentModel(
        id: newDoc.id,
        ownerId: user.uid,
        name: name,
        category: category,
        condition: condition.toUpperCase(),
        status: 'AVAILABLE',
        quantity: quantity,
        mode: mode,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        donor: user.displayName ?? '',
        location: location ?? '',
        latitude: null, // Depending on geocoding
        longitude: null,
        image: image ?? '',
        images: [],
        manufacturer: manufacturer ?? '',
        description: description ?? '',
      );
      
      debugPrint('[SAVE_DEBUG] Firebase UID: ${user.uid}');
      debugPrint('[FIRESTORE_DEBUG] WRITE START');
      debugPrint('[FIRESTORE_DEBUG] Project ID: ${Firebase.app().options.projectId}');
      debugPrint('[FIRESTORE_DEBUG] Firebase UID: ${user.uid}');
      debugPrint('[FIRESTORE_DEBUG] currentUser exists: true');
      debugPrint('[FIRESTORE_DEBUG] email verified: ${user.emailVerified}');
      
      final equipmentData = {
        'id': newEquip.id,
        'ownerId': newEquip.ownerId,
        'name': newEquip.name,
        'category': newEquip.category,
        'condition': newEquip.condition,
        'status': newEquip.status,
        'quantity': newEquip.quantity,
        'mode': newEquip.mode,
        'createdAt': newEquip.createdAt,
        'updatedAt': newEquip.updatedAt,
        'donor': newEquip.donor,
        'location': newEquip.location,
        'image': newEquip.image,
        'images': newEquip.images,
        'manufacturer': newEquip.manufacturer,
        'description': newEquip.description,
      };

      debugPrint('[FIRESTORE_DEBUG] field id type: ${equipmentData['id'].runtimeType}');
      debugPrint('[FIRESTORE_DEBUG] field quantity type: ${equipmentData['quantity'].runtimeType}');
      debugPrint('[FIRESTORE_DEBUG] field ownerId type: ${equipmentData['ownerId'].runtimeType}');
      debugPrint('[FIRESTORE_DEBUG] field image type: ${equipmentData['image'].runtimeType}');

      try {
        final stopwatch = Stopwatch()..start();

        await db
            .collection('equipment')
            .doc(newDoc.id)
            .set(equipmentData)
            .timeout(const Duration(seconds: 30));

        stopwatch.stop();

        debugPrint(
          '[FIRESTORE_DEBUG] WRITE SUCCESS after ${stopwatch.elapsedMilliseconds} ms',
        );
      } on FirebaseException catch (e, stackTrace) {
        debugPrint('[FIRESTORE_DEBUG] FIREBASE EXCEPTION');
        debugPrint('[FIRESTORE_DEBUG] code: ${e.code}');
        debugPrint('[FIRESTORE_DEBUG] message: ${e.message}');
        debugPrint('[FIRESTORE_DEBUG] plugin: ${e.plugin}');
        debugPrint('[FIRESTORE_DEBUG] stack: $stackTrace');
        rethrow;
      } catch (e, stackTrace) {
        if (e.toString().contains('TimeoutException')) {
          debugPrint('[FIRESTORE_DEBUG] TIMEOUT EXCEPTION');
          debugPrint('[FIRESTORE_DEBUG] timeout: $e');
          debugPrint('[FIRESTORE_DEBUG] stack: $stackTrace');
          rethrow;
        } else {
          debugPrint('[FIRESTORE_DEBUG] UNKNOWN EXCEPTION: $e');
          debugPrint('[FIRESTORE_DEBUG] stack: $stackTrace');
          rethrow;
        }
      }

      debugPrint('[SAVE_DEBUG] 07 Firestore/API request RETURNED');
      debugPrint('[SAVE_DEBUG] 08 equipment ID RECEIVED: ${newDoc.id}');
      
      _equipment.insert(0, newEquip);
      debugPrint('[SAVE_DEBUG] 09 provider state UPDATED');
      
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _errorMessage = "Firestore error: permission-denied. You don't have permission to create this listing.";
      } else if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        _errorMessage = "Firestore error: ${e.code}. Unable to connect.";
      } else {
        _errorMessage = "Firestore error: ${e.code}. ${e.message}";
      }
      return false;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _errorMessage = "Request timed out. Please check your internet connection and try again.";
      } else {
        _errorMessage = "Something went wrong: $e";
      }
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
    String mode = 'DONATE',
    double? rentalPricePerDay,
    double? securityDeposit,
    double? latitude,
    double? longitude,
    String? address,
    String? manufacturer,
    String? description,
    String? location,
    String? image,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final db = FirebaseFirestore.instance;
      await db.collection('equipment').doc(id).update({
        'name': name,
        'category': category,
        'condition': condition.toUpperCase(),
        'status': status.toUpperCase(),
        'location': location ?? '',
        'description': description ?? '',
        'manufacturer': manufacturer ?? '',
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (image != null && image.isNotEmpty) 'image': image,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      final idx = _equipment.indexWhere((item) => item.id == id);
      if (idx != -1) {
        final old = _equipment[idx];
        _equipment[idx] = EquipmentModel(
          id: old.id,
          ownerId: old.ownerId,
          name: name,
          category: category,
          description: description ?? old.description,
          location: location ?? old.location,
          address: old.address,
          latitude: latitude ?? old.latitude,
          longitude: longitude ?? old.longitude,
          quantity: old.quantity,
          status: status.toUpperCase(),
          mode: old.mode,
          donor: old.donor,
          condition: condition.toUpperCase(),
          manufacturer: manufacturer ?? old.manufacturer,
          image: (image != null && image.isNotEmpty) ? image : old.image,
          images: old.images,
          createdAt: old.createdAt,
          updatedAt: DateTime.now().toIso8601String(),
        );
      }
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _errorMessage = "You don't have permission to update this listing.";
      } else if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        _errorMessage = "Unable to connect. Please check your internet connection.";
      } else {
        _errorMessage = "Something went wrong. Please try again.";
      }
      return false;
    } catch (e) {
      _errorMessage = "Something went wrong. Please try again.";
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
      final db = FirebaseFirestore.instance;
      await db.collection('equipment').doc(id).delete();
      _equipment.removeWhere((item) => item.id == id);
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _errorMessage = "You don't have permission to delete this listing.";
      } else if (e.code == 'unavailable' || e.code == 'network-request-failed') {
        _errorMessage = "Unable to connect. Please check your internet connection.";
      } else {
        _errorMessage = "Something went wrong. Please try again.";
      }
      return false;
    } catch (e) {
      _errorMessage = "Something went wrong. Please try again.";
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
      final response = await _dio.post(
        ApiEndpoints.request,
        data: {'equipmentId': equipmentId, 'reason': reason},
      );
      if (response.data != null && response.data['success'] == true) {
        return true;
      } else {
        _errorMessage =
            response.data?['message'] ?? 'Failed to request equipment.';
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
      final db = FirebaseFirestore.instance;
      // Note: for nearby equipment, we ideally need GeoFire or distance queries.
      // We will do a generic query for now and fetch everything to filter manually if needed, 
      // or simply rely on fetchEquipment style if radius isn't strictly necessary.
      // But we just grab 'AVAILABLE' stuff.
      final snapshot = await db.collection('equipment').where('status', isEqualTo: 'AVAILABLE').get();
      _nearbyEquipment = snapshot.docs.map((doc) {
        final data = doc.data();
        return EquipmentModel(
          id: data['id'] ?? doc.id,
          ownerId: data['ownerId'] ?? '',
          name: data['name'] ?? 'Unknown',
          category: data['category'] ?? 'Other',
          condition: data['condition'] ?? 'Good',
          status: data['status'] ?? 'AVAILABLE',
          quantity: data['quantity'] ?? 1,
          mode: data['mode'] ?? 'DONATE',
          createdAt: data['createdAt'] ?? DateTime.now().toIso8601String(),
          updatedAt: data['updatedAt'] ?? DateTime.now().toIso8601String(),
          donor: data['donor'] ?? '',
          location: data['location'] ?? '',
          latitude: data['latitude'],
          longitude: data['longitude'],
          image: data['image'] ?? '',
          images: List<String>.from(data['images'] ?? []),
          manufacturer: data['manufacturer'] ?? '',
          description: data['description'] ?? '',
        );
      }).toList();
      _nearbyMeta = {
        'count': _nearbyEquipment.length,
        'location': 'Current Location',
        'radius': radius,
        'radiusUnit': 'km',
      };
    } catch (e) {
      _nearbyError = 'An unexpected error occurred: $e';
    } finally {
      _isLoadingNearby = false;
      notifyListeners();
    }
  }
  // ── Clear State on Logout ───────────────────────────────────────────
  void clear() {
    _equipment = [];
    _nearbyEquipment = [];
    _nearbyMeta = null;
    _errorMessage = '';
    _nearbyError = '';
    _searchQuery = '';
    notifyListeners();
  }
}
