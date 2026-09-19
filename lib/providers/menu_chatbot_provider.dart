import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../core/network/dio_client.dart';
import '../core/network/api_endpoints.dart';
import '../models/chat_message_model.dart';
import '../models/equipment_model.dart';
import '../models/request_model.dart';
import '../models/rental_model.dart';
import '../models/hospital_model.dart';

enum ChatFilter { all, unread }

class MenuChatbotProvider extends ChangeNotifier {
  final Dio _dio = DioClient.instance;

  // ── Conversation List State ─────────────────────────────────────────
  String _conversationSearchQuery = '';
  ChatFilter _activeFilter = ChatFilter.all;

  final List<ChatConversationModel> _conversations = [
    ChatConversationModel(
      id: 'support',
      name: 'MediShare Support',
      lastMessage: 'Hi 👋 Welcome to MediShare. How can I help you today?',
      lastTimestamp: DateTime.now(),
      unreadCount: 1,
      isOnline: true,
      isSupport: true,
      category: 'Official Support',
    ),
    ChatConversationModel(
      id: 'hospital_help',
      name: 'Hospital Network Desk',
      lastMessage: 'Verified hospital partners ready for equipment coordination.',
      lastTimestamp: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 0,
      isOnline: true,
      isSupport: false,
      category: 'Coordination',
    ),
    ChatConversationModel(
      id: 'donation_desk',
      name: 'Donation & Redistribution Center',
      lastMessage: 'Thank you for supporting community healthcare needs.',
      lastTimestamp: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      isOnline: false,
      isSupport: false,
      category: 'Donations',
    ),
  ];

  // ── Support Conversation State ──────────────────────────────────────
  final List<ChatMessageModel> _messages = [];
  bool _isTyping = false;
  String _errorMessage = '';
  double _currentRadiusKm = 20.0;
  double? _lastKnownLat;
  double? _lastKnownLng;

  // Getters
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  String get errorMessage => _errorMessage;
  double get currentRadiusKm => _currentRadiusKm;
  String get conversationSearchQuery => _conversationSearchQuery;
  ChatFilter get activeFilter => _activeFilter;

  List<ChatConversationModel> get filteredConversations {
    return _conversations.where((conv) {
      final matchesSearch = conv.name
              .toLowerCase()
              .contains(_conversationSearchQuery.toLowerCase()) ||
          conv.lastMessage
              .toLowerCase()
              .contains(_conversationSearchQuery.toLowerCase());

      if (_activeFilter == ChatFilter.unread) {
        return matchesSearch && conv.unreadCount > 0;
      }
      return matchesSearch;
    }).toList();
  }

  // Navigation / screen redirection callback
  Function(String routeName, Object? arguments)? onRedirect;

  MenuChatbotProvider() {
    _initMenu();
  }

  void updateLanguage(String lang) {
    // Retained for backwards-compatibility
  }

  void setConversationSearchQuery(String query) {
    _conversationSearchQuery = query;
    notifyListeners();
  }

  void setFilter(ChatFilter filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void markSupportAsRead() {
    final idx = _conversations.indexWhere((c) => c.id == 'support');
    if (idx != -1 && _conversations[idx].unreadCount > 0) {
      _conversations[idx] = ChatConversationModel(
        id: _conversations[idx].id,
        name: _conversations[idx].name,
        lastMessage: _conversations[idx].lastMessage,
        lastTimestamp: _conversations[idx].lastTimestamp,
        unreadCount: 0,
        isOnline: _conversations[idx].isOnline,
        isSupport: _conversations[idx].isSupport,
        category: _conversations[idx].category,
      );
      notifyListeners();
    }
  }

  // ── Menu Initialization ─────────────────────────────────────────────
  void _initMenu() {
    _messages.clear();
    _messages.add(
      ChatMessageModel(
        id: 'welcome_menu_${DateTime.now().millisecondsSinceEpoch}',
        text: "Hi 👋 Welcome to MediShare.\nHow can I help you today?\n\n"
            "1️⃣ Find Available Equipment\n"
            "2️⃣ Find Nearby Hospitals\n"
            "3️⃣ My Equipment Requests\n"
            "4️⃣ Track Rental\n"
            "5️⃣ Donation Help\n"
            "6️⃣ Payment Help",
        isUser: false,
        timestamp: DateTime.now(),
        messageType: ChatMessageType.menu,
        options: const [
          "1️⃣ Find Available Equipment",
          "2️⃣ Find Nearby Hospitals",
          "3️⃣ My Equipment Requests",
          "4️⃣ Track Rental",
          "5️⃣ Donation Help",
          "6️⃣ Payment Help",
        ],
      ),
    );
    notifyListeners();
  }

  void clearChat([String lang = 'English']) {
    _initMenu();
  }

  void _addBotMessage(
    String text, {
    bool isError = false,
    ChatMessageType messageType = ChatMessageType.text,
    List<EquipmentModel>? equipmentList,
    List<String>? options,
    Map<String, dynamic>? customData,
    bool showMainMenuButton = false,
  }) {
    _messages.add(
      ChatMessageModel(
        id: 'bot_${DateTime.now().millisecondsSinceEpoch}_${_messages.length}',
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
        isError: isError,
        messageType: messageType,
        equipmentList: equipmentList,
        options: options,
        customData: customData,
        showMainMenuButton: showMainMenuButton,
      ),
    );

    // Update conversation snippet
    final idx = _conversations.indexWhere((c) => c.id == 'support');
    if (idx != -1) {
      _conversations[idx] = ChatConversationModel(
        id: _conversations[idx].id,
        name: _conversations[idx].name,
        lastMessage: text.split('\n').first,
        lastTimestamp: DateTime.now(),
        unreadCount: 0,
        isOnline: true,
        isSupport: true,
        category: 'Official Support',
      );
    }
  }

  void _addUserMessage(String text) {
    _messages.add(
      ChatMessageModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}_${_messages.length}',
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
        status: MessageStatus.read,
      ),
    );
  }

  // ── Main User Input Handler ─────────────────────────────────────────
  Future<void> sendMessage(String text, {String lang = 'English'}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;

    _errorMessage = '';
    _addUserMessage(trimmed);
    _isTyping = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 350));

    final normalized = trimmed.toLowerCase();

    // Check for Main Menu request
    if (normalized == 'menu' ||
        normalized == 'main menu' ||
        normalized == '[ main menu ]' ||
        normalized == 'home') {
      _showMainMenu();
      _isTyping = false;
      notifyListeners();
      return;
    }

    // Check for radius selection (e.g., "5km", "10 km", "20km", "50km")
    final radiusMatch = RegExp(r'^(\d+)\s*(?:km)?$').firstMatch(normalized);
    if (radiusMatch != null &&
        ['5', '10', '20', '50'].contains(radiusMatch.group(1))) {
      final selectedRadius = double.parse(radiusMatch.group(1)!);
      await _fetchEquipmentWithRadius(selectedRadius);
      _isTyping = false;
      notifyListeners();
      return;
    }

    // Option triggers (Number or keywords)
    if (trimmed == '1' ||
        trimmed.startsWith('1️⃣') ||
        normalized.contains('find available equipment') ||
        normalized.contains('equipment') ||
        normalized.contains('items')) {
      await handleOption1AvailableEquipment();
    } else if (trimmed == '2' ||
        trimmed.startsWith('2️⃣') ||
        normalized.contains('hospital') ||
        normalized.contains('nearby hospitals')) {
      await handleOption2NearbyHospitals();
    } else if (trimmed == '3' ||
        trimmed.startsWith('3️⃣') ||
        normalized.contains('request') ||
        normalized.contains('my requests')) {
      await handleOption3MyRequests();
    } else if (trimmed == '4' ||
        trimmed.startsWith('4️⃣') ||
        normalized.contains('track') ||
        normalized.contains('rental') ||
        normalized.contains('tracking')) {
      await handleOption4TrackRental();
    } else if (trimmed == '5' ||
        trimmed.startsWith('5️⃣') ||
        normalized.contains('donate') ||
        normalized.contains('donation')) {
      await handleOption5DonationHelp();
    } else if (trimmed == '6' ||
        trimmed.startsWith('6️⃣') ||
        normalized.contains('payment') ||
        normalized.contains('deposit') ||
        normalized.contains('razorpay')) {
      await handleOption6PaymentHelp();
    } else {
      // Fallback helpful guidance with options
      _addBotMessage(
        "I can help you with medical equipment, nearby hospitals, rental tracking, requests, donations, or payments.\n\n"
        "Please choose an option below or type a number from 1 to 6:",
        messageType: ChatMessageType.menu,
        options: const [
          "1️⃣ Find Available Equipment",
          "2️⃣ Find Nearby Hospitals",
          "3️⃣ My Equipment Requests",
          "4️⃣ Track Rental",
          "5️⃣ Donation Help",
          "6️⃣ Payment Help",
        ],
        showMainMenuButton: true,
      );
    }

    _isTyping = false;
    notifyListeners();
  }

  void _showMainMenu() {
    _addBotMessage(
      "Hi 👋 Welcome to MediShare.\nHow can I help you today?\n\n"
      "1️⃣ Find Available Equipment\n"
      "2️⃣ Find Nearby Hospitals\n"
      "3️⃣ My Equipment Requests\n"
      "4️⃣ Track Rental\n"
      "5️⃣ Donation Help\n"
      "6️⃣ Payment Help",
      messageType: ChatMessageType.menu,
      options: const [
        "1️⃣ Find Available Equipment",
        "2️⃣ Find Nearby Hospitals",
        "3️⃣ My Equipment Requests",
        "4️⃣ Track Rental",
        "5️⃣ Donation Help",
        "6️⃣ Payment Help",
      ],
      showMainMenuButton: false,
    );
  }

  // ── 1. REAL AVAILABLE EQUIPMENT FLOW ────────────────────────────────
  Future<void> handleOption1AvailableEquipment({double radiusKm = 20.0}) async {
    _currentRadiusKm = radiusKm;

    // Check GPS permission & service
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _addBotMessage(
          "📍 Location services (GPS) are currently disabled on your device. Please enable location to find equipment near you, or view all available listings across the network.",
          messageType: ChatMessageType.radiusPicker,
          options: const ["View All Equipment", "Grant Permission / Retry"],
          showMainMenuButton: true,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _addBotMessage(
          "📍 Location permission was not granted. Distance calculation is unavailable without GPS permission.\n\nWould you like to browse all available equipment network-wide?",
          options: const ["View All Equipment", "Grant Permission / Retry"],
          showMainMenuButton: true,
        );
        return;
      }

      // Fresh or cached GPS location
      Position? position;
      try {
        LocationSettings locationSettings;
        if (Platform.isAndroid) {
          locationSettings = AndroidSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 15),
          );
        } else if (Platform.isIOS) {
          locationSettings = AppleSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 15),
          );
        } else {
          locationSettings = const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          );
        }

        position = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null) {
        _lastKnownLat = position.latitude;
        _lastKnownLng = position.longitude;
        await _queryNearbyEquipment(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusKm: radiusKm,
        );
      } else {
        // Fallback to city-wide equipment if position timed out
        await _queryAllEquipment();
      }
    } catch (e) {
      await _queryAllEquipment();
    }
  }

  Future<void> _fetchEquipmentWithRadius(double radiusKm) async {
    _currentRadiusKm = radiusKm;
    if (_lastKnownLat != null && _lastKnownLng != null) {
      await _queryNearbyEquipment(
        latitude: _lastKnownLat!,
        longitude: _lastKnownLng!,
        radiusKm: radiusKm,
      );
    } else {
      await handleOption1AvailableEquipment(radiusKm: radiusKm);
    }
  }

  Future<void> _queryNearbyEquipment({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.nearbyEquipment,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radiusKm': radiusKm,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final listData = response.data['equipment'] as List<dynamic>? ?? [];
        final items = listData
            .map((item) =>
                EquipmentModel.fromJson(item as Map<String, dynamic>))
            .where((e) => e.status.toUpperCase() == 'AVAILABLE')
            .toList();

        if (items.isEmpty) {
          _addBotMessage(
            "No available equipment found within ${radiusKm.toInt()} km.",
            messageType: ChatMessageType.radiusPicker,
            options: const ["5 km", "10 km", "20 km", "50 km"],
            showMainMenuButton: true,
          );
        } else {
          _addBotMessage(
            "Here are the medical equipment items currently available (${items.length} items within ${radiusKm.toInt()} km):",
            messageType: ChatMessageType.equipmentList,
            equipmentList: items,
            showMainMenuButton: true,
          );
        }
      } else {
        await _queryAllEquipment();
      }
    } on DioException catch (e) {
      _addBotMessage(
        "⚠️ ${DioClient.handleError(e)}",
        isError: true,
        showMainMenuButton: true,
      );
    } catch (e) {
      _addBotMessage(
        "⚠️ Could not load nearby equipment. Please check your connection and try again.",
        isError: true,
        showMainMenuButton: true,
      );
    }
  }

  Future<void> _queryAllEquipment() async {
    try {
      final response = await _dio.get(ApiEndpoints.equipment);
      if (response.data != null && response.data['success'] == true) {
        final listData = response.data['data'] as List<dynamic>? ?? [];
        final items = listData
            .map((item) =>
                EquipmentModel.fromJson(item as Map<String, dynamic>))
            .where((e) => e.status.toUpperCase() == 'AVAILABLE')
            .toList();

        if (items.isEmpty) {
          _addBotMessage(
            "No available equipment found in the MediShare registry at this time.",
            showMainMenuButton: true,
          );
        } else {
          _addBotMessage(
            "Here are the medical equipment items currently available across MediShare:",
            messageType: ChatMessageType.equipmentList,
            equipmentList: items,
            showMainMenuButton: true,
          );
        }
      } else {
        _addBotMessage(
          "⚠️ Unable to load equipment at this moment. Please try again.",
          isError: true,
          showMainMenuButton: true,
        );
      }
    } on DioException catch (e) {
      _addBotMessage(
        "⚠️ ${DioClient.handleError(e)}",
        isError: true,
        showMainMenuButton: true,
      );
    } catch (e) {
      _addBotMessage(
        "⚠️ An error occurred while retrieving equipment.",
        isError: true,
        showMainMenuButton: true,
      );
    }
  }

  // ── 2. NEARBY HOSPITALS FLOW ────────────────────────────────────────
  Future<void> handleOption2NearbyHospitals() async {
    try {
      final response = await _dio.get(ApiEndpoints.hospital);
      if (response.data != null && response.data['success'] == true) {
        final listData = response.data['data'] as List<dynamic>? ?? [];
        final hospitals = listData
            .map((item) => HospitalModel.fromJson(item as Map<String, dynamic>))
            .take(4)
            .toList();

        if (hospitals.isEmpty) {
          _addBotMessage(
            "No partner hospitals currently listed in this sector.",
            showMainMenuButton: true,
          );
        } else {
          String text = "🏥 Partner Hospitals registered with MediShare:\n\n";
          for (final h in hospitals) {
            text += "• ${h.hospitalName}\n  📍 ${h.address}\n  📞 ${h.phone}\n\n";
          }
          _addBotMessage(
            text.trim(),
            messageType: ChatMessageType.hospitalList,
            options: const ["Open Hospital Directory", "View Available Equipment"],
            showMainMenuButton: true,
          );
        }
      } else {
        _addBotMessage(
          "🏥 Partner hospitals provide verified medical equipment, storage, and pick-up services.\nTap below to open the complete Hospital Directory.",
          messageType: ChatMessageType.hospitalList,
          options: const ["Open Hospital Directory"],
          showMainMenuButton: true,
        );
      }
    } catch (_) {
      _addBotMessage(
        "🏥 Partner hospitals provide verified medical equipment, storage, and pick-up services.\nTap below to open the complete Hospital Directory.",
        messageType: ChatMessageType.hospitalList,
        options: const ["Open Hospital Directory"],
        showMainMenuButton: true,
      );
    }
  }

  // ── 3. MY EQUIPMENT REQUESTS FLOW ───────────────────────────────────
  Future<void> handleOption3MyRequests() async {
    try {
      final response = await _dio.get(ApiEndpoints.request);
      if (response.data != null && response.data['success'] == true) {
        final listData = response.data['data'] as List<dynamic>? ?? [];
        final requests = listData
            .map((item) => RequestModel.fromJson(item as Map<String, dynamic>))
            .toList();

        if (requests.isEmpty) {
          _addBotMessage(
            "You have no equipment requests yet. You can browse available equipment to submit a new request.",
            options: const ["1️⃣ Find Available Equipment"],
            showMainMenuButton: true,
          );
        } else {
          String msg = "📋 Your Equipment Requests (${requests.length}):\n\n";
          for (int i = 0; i < requests.length && i < 4; i++) {
            final r = requests[i];
            final equipName = r.equipment?.name ?? 'Medical Equipment';
            msg += "${i + 1}. $equipName\n   Status: [${r.status}]\n   Hospital: ${r.hospital}\n   Reason: ${r.reason}\n\n";
          }
          _addBotMessage(
            msg.trim(),
            messageType: ChatMessageType.requestList,
            options: const ["View All Requests", "1️⃣ Find Available Equipment"],
            showMainMenuButton: true,
          );
        }
      } else {
        _addBotMessage(
          "⚠️ Unable to load your requests. Please ensure you are logged in.",
          isError: true,
          showMainMenuButton: true,
        );
      }
    } on DioException catch (e) {
      _addBotMessage(
        "⚠️ ${DioClient.handleError(e)}",
        isError: true,
        showMainMenuButton: true,
      );
    } catch (e) {
      _addBotMessage(
        "⚠️ Could not fetch requests at this time.",
        isError: true,
        showMainMenuButton: true,
      );
    }
  }

  // ── 4. TRACK RENTAL FLOW ────────────────────────────────────────────
  Future<void> handleOption4TrackRental() async {
    try {
      final response = await _dio.get(ApiEndpoints.rental);
      if (response.data != null && response.data['success'] == true) {
        final listData = response.data['data'] as List<dynamic>? ?? [];
        final rentals = listData
            .map((item) => RentalModel.fromJson(item as Map<String, dynamic>))
            .toList();

        if (rentals.isEmpty) {
          _addBotMessage(
            "You have no active equipment rentals to track.\nBrowse available equipment to rent items with secure tracking.",
            options: const ["1️⃣ Find Available Equipment"],
            showMainMenuButton: true,
          );
        } else {
          String msg = "🚚 Real-time Equipment Rentals:\n\n";
          for (final r in rentals.take(3)) {
            final equipName = r.equipment?.name ?? 'Equipment #${r.id}';
            msg += "• $equipName\n  Status: ${r.status}\n  Duration: ${r.startDate.substring(0, 10)} to ${r.endDate.substring(0, 10)}\n\n";
          }
          _addBotMessage(
            msg.trim(),
            messageType: ChatMessageType.trackingList,
            options: const ["Open Rentals & Tracking", "1️⃣ Find Available Equipment"],
            showMainMenuButton: true,
          );
        }
      } else {
        _addBotMessage(
          "⚠️ Unable to fetch your rentals at this moment.",
          isError: true,
          showMainMenuButton: true,
        );
      }
    } on DioException catch (e) {
      _addBotMessage(
        "⚠️ ${DioClient.handleError(e)}",
        isError: true,
        showMainMenuButton: true,
      );
    } catch (e) {
      _addBotMessage(
        "⚠️ Error retrieving rental details.",
        isError: true,
        showMainMenuButton: true,
      );
    }
  }

  // ── 5. DONATION HELP FLOW ───────────────────────────────────────────
  Future<void> handleOption5DonationHelp() async {
    const text =
        "❤️ MediShare Equipment Donation:\n\n"
        "1. List equipment you wish to donate (wheelchairs, oxygen concentrators, hospital beds, etc.).\n"
        "2. Our partner hospitals inspect and verify the item's condition.\n"
        "3. Equipment is directly redistributed to underprivileged patients and clinics free of cost.\n\n"
        "Ready to list an item for donation?";

    _addBotMessage(
      text,
      messageType: ChatMessageType.helpInfo,
      options: const ["Start a Donation", "View My Donations"],
      showMainMenuButton: true,
    );
  }

  // ── 6. PAYMENT HELP FLOW ────────────────────────────────────────────
  Future<void> handleOption6PaymentHelp() async {
    const text =
        "💳 MediShare Rental & Payment Guide:\n\n"
        "• Rental Price: Affordable per-day fee agreed with equipment owners.\n"
        "• Security Deposit: Fully refundable upon equipment return in intact condition.\n"
        "• Payment Gateway: 100% secure payments via Razorpay (UPI, Credit/Debit Cards, Net Banking).\n"
        "• Zero Commission on Donations: MediShare does not charge for non-profit redistributions.\n\n"
        "Need personalized help with a payment or refund?";

    _addBotMessage(
      text,
      messageType: ChatMessageType.helpInfo,
      options: const ["Contact Support", "1️⃣ Find Available Equipment"],
      showMainMenuButton: true,
    );
  }

  // ── 7. SUBMIT EQUIPMENT REQUEST (Chat Action) ───────────────────────
  Future<bool> submitEquipmentRequest({
    required String equipmentId,
    required String reason,
  }) async {
    _isTyping = true;
    notifyListeners();

    try {
      final payload = {
        'equipmentId': equipmentId,
        'reason': reason,
        'quantity': 1,
      };

      final response = await _dio.post(ApiEndpoints.request, data: payload);
      if (response.data != null && response.data['success'] == true) {
        final reqData = response.data['data'] as Map<String, dynamic>?;
        final reqId = reqData?['id']?.toString() ?? 'REQ-${DateTime.now().millisecondsSinceEpoch}';
        final status = reqData?['status']?.toString() ?? 'PENDING';

        _addBotMessage(
          "✅ Equipment request submitted.\n"
          "Request ID: $reqId\n"
          "Status: $status\n\n"
          "The owner and partner hospital have been notified.",
          messageType: ChatMessageType.successNotice,
          showMainMenuButton: true,
        );
        _isTyping = false;
        notifyListeners();
        return true;
      } else {
        final err = response.data?['message'] ?? 'Failed to submit request.';
        _addBotMessage("⚠️ $err", isError: true, showMainMenuButton: true);
        _isTyping = false;
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      _addBotMessage(
        "⚠️ ${DioClient.handleError(e)}",
        isError: true,
        showMainMenuButton: true,
      );
      _isTyping = false;
      notifyListeners();
      return false;
    } catch (e) {
      _addBotMessage(
        "⚠️ An unexpected error occurred while submitting your request.",
        isError: true,
        showMainMenuButton: true,
      );
      _isTyping = false;
      notifyListeners();
      return false;
    }
  }

  // ── Delete a single message from state ──────────────────────────────
  void deleteMessage(String messageId) {
    _messages.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }
}
