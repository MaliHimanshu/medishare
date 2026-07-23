import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final Dio _dio = DioClient.instance;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Search and Filter states
  String _searchQuery = '';
  String _selectedFilter = 'All';

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedFilter = 'All';
    notifyListeners();
  }

  // ── Getter: Filtered Notifications ─────────────────────────────────
  List<NotificationModel> get filteredNotifications {
    List<NotificationModel> list = List.from(_notifications);

    // 1. Filter by Search Query (Title, Message, Module)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((item) {
        final title = item.title.toLowerCase();
        final message = item.message.toLowerCase();
        final module = item.module.toLowerCase();
        return title.contains(query) ||
            message.contains(query) ||
            module.contains(query);
      }).toList();
    }

    // 2. Filter by Chip Option
    if (_selectedFilter != 'All') {
      if (_selectedFilter == 'Unread') {
        list = list.where((item) => !item.isRead).toList();
      } else if (_selectedFilter == 'Read') {
        list = list.where((item) => item.isRead).toList();
      } else {
        // Module match (Donations, Requests, Hospitals, Announcements)
        list = list.where((item) {
          return item.module.toLowerCase() == _selectedFilter.toLowerCase() ||
              item.type.toLowerCase() == _selectedFilter.toLowerCase();
        }).toList();
      }
    }

    return list;
  }

  // ── Fetch Notifications (GET /api/notification) ────────────────────
  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _dio.get(ApiEndpoints.notifications);
      if (response.data != null && response.data['success'] == true) {
        final listData = (response.data['notifications'] ?? response.data['data']) as List<dynamic>?;
        if (listData != null) {
          _notifications = listData
              .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } else {
        _errorMessage = response.data?['message'] ?? 'Failed to load notifications.';
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

  // ── Mark Notification as Read (PATCH /api/notification/:id/read) ────
  Future<bool> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return false;

    // Optimistic update
    _notifications[idx] = _notifications[idx].copyWith(isRead: true);
    notifyListeners();

    try {
      final response = await _dio.patch('${ApiEndpoints.notifications}/$id/read');
      if (response.data != null && response.data['success'] == true) {
        return true;
      }
    } catch (_) {}
    return true;
  }

  // ── Delete Notification (DELETE /api/notification/:id) ────────────
  Future<bool> deleteNotification(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return false;

    final removedItem = _notifications[idx];
    _notifications.removeAt(idx);
    notifyListeners();

    try {
      final response = await _dio.delete('${ApiEndpoints.notifications}/$id');
      if (response.data != null && response.data['success'] == true) {
        return true;
      }
    } catch (_) {
      // Revert if API fails
      _notifications.insert(idx, removedItem);
      notifyListeners();
      return false;
    }
    return true;
  }
}
