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
      lastMessage:
          'Verified hospital partners ready for equipment coordination.',
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
  String _currentRole = 'DONOR';
  String? _currentUserId;

  // Getters
  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  String get errorMessage => _errorMessage;
  double get currentRadiusKm => _currentRadiusKm;
  String get conversationSearchQuery => _conversationSearchQuery;
  ChatFilter get activeFilter => _activeFilter;
  String get currentRole => _currentRole;

  List<ChatConversationModel> get filteredConversations {
    return _conversations.where((conv) {
      final matchesSearch =
          conv.name.toLowerCase().contains(
            _conversationSearchQuery.toLowerCase(),
          ) ||
          conv.lastMessage.toLowerCase().contains(
            _conversationSearchQuery.toLowerCase(),
          );

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

  void setRole(String role, [String? userId]) {
    final normalized = role.toUpperCase();
    final changed = _currentRole != normalized || _currentUserId != userId;
    _currentRole = normalized;
    _currentUserId = userId;
    if (changed) {
      _initMenu();
    }
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

  // ── Menu Initialization (Adapted by Role) ───────────────────────────
  void _initMenu() {
    _messages.clear();
    String greeting;
    List<String> options;

    switch (_currentRole) {
      case 'DONOR':
        greeting =
            "Hi 👋 Welcome to MediShare.\nHow can I help you today?\n\n"
            "1️⃣ My Equipment\n"
            "2️⃣ Add Equipment\n"
            "3️⃣ Rental Requests\n"
            "4️⃣ Donate Equipment\n"
            "5️⃣ My Rentals";
        options = const [
          "1️⃣ My Equipment",
          "2️⃣ Add Equipment",
          "3️⃣ Rental Requests",
          "4️⃣ Donate Equipment",
          "5️⃣ My Rentals",
        ];
        break;

      case 'NGO':
        greeting =
            "Hi 👋 Welcome to MediShare.\nHow can I help you today?\n\n"
            "1️⃣ View Equipment\n"
            "2️⃣ Request Equipment\n"
            "3️⃣ My Requests\n"
            "4️⃣ Donations\n"
            "5️⃣ Beneficiaries";
        options = const [
          "1️⃣ View Equipment",
          "2️⃣ Request Equipment",
          "3️⃣ My Requests",
          "4️⃣ Donations",
          "5️⃣ Beneficiaries",
        ];
        break;

      case 'HOSPITAL':
        greeting =
            "Hi 👋 Welcome to MediShare.\nHow can I help you today?\n\n"
            "1️⃣ Hospital Equipment\n"
            "2️⃣ Request Equipment\n"
            "3️⃣ Rent Equipment\n"
            "4️⃣ Donations\n"
            "5️⃣ My Requests";
        options = const [
          "1️⃣ Hospital Equipment",
          "2️⃣ Request Equipment",
          "3️⃣ Rent Equipment",
          "4️⃣ Donations",
          "5️⃣ My Requests",
        ];
        break;

      case 'RECIPIENT':
        greeting =
            "Hi 👋 Welcome to MediShare.\nHow can I help you today?\n\n"
            "1️⃣ View Available Equipment\n"
            "2️⃣ Search Equipment\n"
            "3️⃣ Rent Equipment\n"
            "4️⃣ My Requests\n"
            "5️⃣ My Rentals";
        options = const [
          "1️⃣ View Available Equipment",
          "2️⃣ Search Equipment",
          "3️⃣ Rent Equipment",
          "4️⃣ My Requests",
          "5️⃣ My Rentals",
        ];
        break;

      default:
        greeting =
            "Hi 👋 Welcome to MediShare Support.\nHow can I help you today?\n\n"
            "1️⃣ Find Available Equipment\n"
            "2️⃣ Find Nearby Hospitals\n"
            "3️⃣ My Equipment Requests\n"
            "4️⃣ Track Rental\n"
            "5️⃣ Donation Help";
        options = const [
          "1️⃣ Find Available Equipment",
          "2️⃣ Find Nearby Hospitals",
          "3️⃣ My Equipment Requests",
          "4️⃣ Track Rental",
          "5️⃣ Donation Help",
        ];
        break;
    }

    _messages.add(
      ChatMessageModel(
        id: 'welcome_menu_${DateTime.now().millisecondsSinceEpoch}',
        text: greeting,
        isUser: false,
        timestamp: DateTime.now(),
        messageType: ChatMessageType.menu,
        options: options,
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

    // ── Role-Specific Menu Routing ────────────────────────────────────
    if (_currentRole == 'DONOR') {
      if (trimmed == '1' ||
          trimmed.startsWith('1️⃣') ||
          normalized.contains('my equipment')) {
        await handleDonorMyEquipment();
      } else if (trimmed == '2' ||
          trimmed.startsWith('2️⃣') ||
          normalized.contains('add equipment')) {
        await handleDonorAddEquipment();
      } else if (trimmed == '3' ||
          trimmed.startsWith('3️⃣') ||
          normalized.contains('rental request')) {
        await handleDonorRentalRequests();
      } else if (trimmed == '4' ||
          trimmed.startsWith('4️⃣') ||
          normalized.contains('donate')) {
        await handleOption5DonationHelp();
      } else if (trimmed == '5' ||
          trimmed.startsWith('5️⃣') ||
          normalized.contains('rental') ||
          normalized.contains('my rentals')) {
        await handleOption4TrackRental();
      } else {
        _showMainMenu();
      }
    } else if (_currentRole == 'NGO') {
      if (trimmed == '1' ||
          trimmed.startsWith('1️⃣') ||
          normalized.contains('view equipment') ||
          normalized.contains('available')) {
        await handleOption1AvailableEquipment();
      } else if (trimmed == '2' ||
          trimmed.startsWith('2️⃣') ||
          normalized.contains('request equipment')) {
        await handleNgoRequestEquipment();
      } else if (trimmed == '3' ||
          trimmed.startsWith('3️⃣') ||
          normalized.contains('my requests') ||
          normalized.contains('request')) {
        await handleOption3MyRequests();
      } else if (trimmed == '4' ||
          trimmed.startsWith('4️⃣') ||
          normalized.contains('donation')) {
        await handleNgoDonations();
      } else if (trimmed == '5' ||
          trimmed.startsWith('5️⃣') ||
          normalized.contains('beneficiar')) {
        await handleNgoBeneficiaries();
      } else {
        _showMainMenu();
      }
    } else if (_currentRole == 'HOSPITAL') {
      if (trimmed == '1' ||
          trimmed.startsWith('1️⃣') ||
          normalized.contains('hospital equipment') ||
          normalized.contains('my equipment')) {
        await handleHospitalEquipment();
      } else if (trimmed == '2' ||
          trimmed.startsWith('2️⃣') ||
          normalized.contains('request equipment')) {
        await handleHospitalRequestEquipment();
      } else if (trimmed == '3' ||
          trimmed.startsWith('3️⃣') ||
          normalized.contains('rent equipment') ||
          normalized.contains('rent')) {
        await handleHospitalRentEquipment();
      } else if (trimmed == '4' ||
          trimmed.startsWith('4️⃣') ||
          normalized.contains('donation')) {
        await handleNgoDonations();
      } else if (trimmed == '5' ||
          trimmed.startsWith('5️⃣') ||
          normalized.contains('my requests') ||
          normalized.contains('request')) {
        await handleOption3MyRequests();
      } else {
        _showMainMenu();
      }
    } else if (_currentRole == 'RECIPIENT') {
      if (trimmed == '1' ||
          trimmed.startsWith('1️⃣') ||
          normalized.contains('view available') ||
          normalized.contains('available')) {
        await handleOption1AvailableEquipment();
      } else if (trimmed == '2' ||
          trimmed.startsWith('2️⃣') ||
          normalized.contains('search')) {
        await handleRecipientSearchEquipment();
      } else if (trimmed == '3' ||
          trimmed.startsWith('3️⃣') ||
          normalized.contains('rent')) {
        await handleRecipientRentEquipment();
      } else if (trimmed == '4' ||
          trimmed.startsWith('4️⃣') ||
          normalized.contains('my requests') ||
          normalized.contains('request')) {
        await handleOption3MyRequests();
      } else if (trimmed == '5' ||
          trimmed.startsWith('5️⃣') ||
          normalized.contains('rental') ||
          normalized.contains('my rentals')) {
        await handleOption4TrackRental();
      } else {
        _showMainMenu();
      }
    } else {
      // Default (ADMIN / other)
      if (trimmed == '1' ||
          trimmed.startsWith('1️⃣') ||
          normalized.contains('equipment')) {
        await handleOption1AvailableEquipment();
      } else if (trimmed == '2' ||
          trimmed.startsWith('2️⃣') ||
          normalized.contains('hospital')) {
        await handleOption2NearbyHospitals();
      } else if (trimmed == '3' ||
          trimmed.startsWith('3️⃣') ||
          normalized.contains('request')) {
        await handleOption3MyRequests();
      } else if (trimmed == '4' ||
          trimmed.startsWith('4️⃣') ||
          normalized.contains('rental') ||
          normalized.contains('track')) {
        await handleOption4TrackRental();
      } else if (trimmed == '5' ||
          trimmed.startsWith('5️⃣') ||
          normalized.contains('donate')) {
        await handleOption5DonationHelp();
      } else {
        _showMainMenu();
      }
    }

    _isTyping = false;
    notifyListeners();
  }

  void _showMainMenu() {
    String greeting;
    List<String> options;

    switch (_currentRole) {
      case 'DONOR':
        greeting =
            "Hi 👋 Welcome to MediShare.\nHow can I help you today?\n\n"
            "1️⃣ My Equipment\n"
            "2️⃣ Add Equipment\n"
            "3️⃣ Rental Requests\n"
            "4️⃣ Donate Equipment\n"
            "5️⃣ My Rentals";
        options = const [
          "1️⃣ My Equipment",
          "2️⃣ Add Equipment",
          "3️⃣ Rental Requests",
          "4️⃣ Donate Equipment",
          "5️⃣ My Rentals",
        ];
        break;

      case 'NGO':
        greeting =
            "Hi 👋 Welcome to MediShare.\nHow can I help you today?\n\n"
            "1️⃣ View Equipment\n"
            "2️⃣ Request Equipment\n"
            "3️⃣ My Requests\n"
            "4️⃣ Donations\n"
            "5️⃣ Beneficiaries";
        options = const [
          "1️⃣ View Equipment",
          "2️⃣ Request Equipment",
          "3️⃣ My Requests",
          "4️⃣ Donations",
          "5️⃣ Beneficiaries",
        ];
        break;

      case 'HOSPITAL':
        greeting =
            "Hi 👋 Welcome to MediShare.\nHow can I help you today?\n\n"
            "1️⃣ Hospital Equipment\n"
            "2️⃣ Request Equipment\n"
            "3️⃣ Rent Equipment\n"
            "4️⃣ Donations\n"
            "5️⃣ My Requests";
        options = const [
          "1️⃣ Hospital Equipment",
          "2️⃣ Request Equipment",
          "3️⃣ Rent Equipment",
          "4️⃣ Donations",
          "5️⃣ My Requests",
        ];
        break;

      case 'RECIPIENT':
        greeting =
            "Hi 👋 Welcome to MediShare.\nHow can I help you today?\n\n"
            "1️⃣ View Available Equipment\n"
            "2️⃣ Search Equipment\n"
            "3️⃣ Rent Equipment\n"
            "4️⃣ My Requests\n"
            "5️⃣ My Rentals";
        options = const [
          "1️⃣ View Available Equipment",
          "2️⃣ Search Equipment",
          "3️⃣ Rent Equipment",
          "4️⃣ My Requests",
          "5️⃣ My Rentals",
        ];
        break;

      default:
        greeting =
            "Hi 👋 Welcome to MediShare Support.\nHow can I help you today?\n\n"
            "1️⃣ Find Available Equipment\n"
            "2️⃣ Find Nearby Hospitals\n"
            "3️⃣ My Equipment Requests\n"
            "4️⃣ Track Rental\n"
            "5️⃣ Donation Help";
        options = const [
          "1️⃣ Find Available Equipment",
          "2️⃣ Find Nearby Hospitals",
          "3️⃣ My Equipment Requests",
          "4️⃣ Track Rental",
          "5️⃣ Donation Help",
        ];
        break;
    }

    _addBotMessage(
      greeting,
      messageType: ChatMessageType.menu,
      options: options,
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
            .map(
              (item) => EquipmentModel.fromJson(item as Map<String, dynamic>),
            )
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
            .map(
              (item) => EquipmentModel.fromJson(item as Map<String, dynamic>),
            )
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
            text +=
                "• ${h.hospitalName}\n  📍 ${h.address}\n  📞 ${h.phone}\n\n";
          }
          _addBotMessage(
            text.trim(),
            messageType: ChatMessageType.hospitalList,
            options: const [
              "Open Hospital Directory",
              "View Available Equipment",
            ],
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
            msg +=
                "${i + 1}. $equipName\n   Status: [${r.status}]\n   Hospital: ${r.hospital}\n   Reason: ${r.reason}\n\n";
          }
          _addBotMessage(
            msg.trim(),
            messageType: ChatMessageType.requestList,
            options: const [
              "View All Requests",
              "1️⃣ Find Available Equipment",
            ],
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
            msg +=
                "• $equipName\n  Status: ${r.status}\n  Duration: ${r.startDate.substring(0, 10)} to ${r.endDate.substring(0, 10)}\n\n";
          }
          _addBotMessage(
            msg.trim(),
            messageType: ChatMessageType.trackingList,
            options: const [
              "Open Rentals & Tracking",
              "1️⃣ Find Available Equipment",
            ],
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
        final reqId =
            reqData?['id']?.toString() ??
            'REQ-${DateTime.now().millisecondsSinceEpoch}';
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

  // ── ROLE-SPECIFIC CHATBOT HANDLERS ─────────────────────────────────

  // DONOR 1: My Equipment
  Future<void> handleDonorMyEquipment() async {
    try {
      final response = await _dio.get(ApiEndpoints.equipment);
      if (response.data != null && response.data['success'] == true) {
        final listData = response.data['data'] as List<dynamic>? ?? [];
        final items = listData
            .map(
              (item) => EquipmentModel.fromJson(item as Map<String, dynamic>),
            )
            .where((e) => _currentUserId == null || e.ownerId == _currentUserId)
            .toList();

        if (items.isEmpty) {
          _addBotMessage(
            "📦 You haven't listed any equipment yet.\n\nYou can list medical equipment to donate or rent to those in need.",
            options: const [
              "Open Add Equipment Form",
              "View Available Equipment",
            ],
            showMainMenuButton: true,
          );
        } else {
          _addBotMessage(
            "📦 Your Listed Equipment (${items.length} items):",
            messageType: ChatMessageType.equipmentList,
            equipmentList: items,
            options: const ["View My Equipment", "Open Add Equipment Form"],
            showMainMenuButton: true,
          );
        }
      } else {
        _addBotMessage(
          "⚠️ Unable to load your equipment listings. Please try again.",
          isError: true,
          showMainMenuButton: true,
        );
      }
    } catch (e) {
      _addBotMessage(
        "⚠️ Could not retrieve your equipment list.",
        isError: true,
        showMainMenuButton: true,
      );
    }
  }

  // DONOR 2: Add Equipment
  Future<void> handleDonorAddEquipment() async {
    _addBotMessage(
      "➕ List Medical Equipment\n\n"
      "1. Enter equipment name, category, and condition.\n"
      "2. Choose listing mode: DONATE (free for patients/NGOs) or RENT (daily rate + refundable deposit).\n"
      "3. Set item location and upload photos.\n"
      "4. Publish to reach patients and hospitals.",
      options: const ["Open Add Equipment Form", "View My Equipment"],
      showMainMenuButton: true,
    );
  }

  // DONOR 3: Rental Requests
  Future<void> handleDonorRentalRequests() async {
    try {
      final response = await _dio.get(ApiEndpoints.rental);
      if (response.data != null && response.data['success'] == true) {
        final listData = response.data['data'] as List<dynamic>? ?? [];
        final rentals = listData
            .map((item) => RentalModel.fromJson(item as Map<String, dynamic>))
            .toList();

        if (rentals.isEmpty) {
          _addBotMessage(
            "📋 You have no incoming rental requests for your equipment at this time.",
            options: const ["View My Equipment", "Open Add Equipment Form"],
            showMainMenuButton: true,
          );
        } else {
          String msg = "📋 Incoming Rental Requests (${rentals.length}):\n\n";
          for (final r in rentals.take(4)) {
            final equipName = r.equipment?.name ?? 'Equipment Item';
            final renter = r.renterName.isNotEmpty ? r.renterName : 'User';
            msg +=
                "• $equipName\n  Renter: $renter\n  Status: [${r.status}]\n  Duration: ${r.startDate.substring(0, 10)} to ${r.endDate.substring(0, 10)}\n\n";
          }
          _addBotMessage(
            msg.trim(),
            messageType: ChatMessageType.trackingList,
            options: const ["Open Rental Requests", "View My Equipment"],
            showMainMenuButton: true,
          );
        }
      } else {
        _addBotMessage(
          "⚠️ Unable to fetch rental requests at this moment.",
          isError: true,
          showMainMenuButton: true,
        );
      }
    } catch (e) {
      _addBotMessage(
        "⚠️ Could not load rental requests.",
        isError: true,
        showMainMenuButton: true,
      );
    }
  }

  // NGO 2: Request Equipment
  Future<void> handleNgoRequestEquipment() async {
    _addBotMessage(
      "📋 Request Equipment for Beneficiaries\n\n"
      "Browse our network of donated and available medical equipment and submit a request on behalf of patients or clinics in your service.",
      options: const ["Browse Equipment to Request", "View Requests"],
      showMainMenuButton: true,
    );
  }

  // NGO 4: Donations
  Future<void> handleNgoDonations() async {
    try {
      final response = await _dio.get(ApiEndpoints.donation);
      if (response.data != null && response.data['success'] == true) {
        final listData = response.data['data'] as List<dynamic>? ?? [];
        if (listData.isEmpty) {
          _addBotMessage(
            "🎁 No donation records found at this time. You can request equipment directly for your beneficiaries.",
            options: const ["Browse Equipment to Request", "View Requests"],
            showMainMenuButton: true,
          );
        } else {
          String msg =
              "🎁 Community Healthcare Donations (${listData.length} active):\n\n";
          for (final d in listData.take(3)) {
            final name = d['equipment']?['name'] ?? 'Medical Item';
            final donor = d['donor']?['name'] ?? 'Verified Donor';
            final status = d['status'] ?? 'PENDING';
            msg += "• $name\n  Donor: $donor\n  Status: [$status]\n\n";
          }
          _addBotMessage(
            msg.trim(),
            options: const ["View Donations", "Browse Equipment to Request"],
            showMainMenuButton: true,
          );
        }
      } else {
        _addBotMessage(
          "⚠️ Unable to load donations at this moment.",
          isError: true,
          showMainMenuButton: true,
        );
      }
    } catch (e) {
      _addBotMessage(
        "⚠️ Error retrieving donation information.",
        isError: true,
        showMainMenuButton: true,
      );
    }
  }

  // NGO 5: Beneficiaries
  Future<void> handleNgoBeneficiaries() async {
    _addBotMessage(
      "🤝 Beneficiary Services & Tracking\n\n"
      "• Request medical items and assign them to verified underprivileged beneficiaries.\n"
      "• Track equipment fulfillment to ensure it reaches those who need it most.\n"
      "• Access partner hospital coordination.",
      options: const ["Browse Equipment to Request", "View Requests"],
      showMainMenuButton: true,
    );
  }

  // HOSPITAL 1: Hospital Equipment
  Future<void> handleHospitalEquipment() async {
    await handleDonorMyEquipment();
  }

  // HOSPITAL 2: Request Equipment
  Future<void> handleHospitalRequestEquipment() async {
    _addBotMessage(
      "🏥 Hospital Equipment Requests & Coordination\n\n"
      "Partner hospitals can request surplus ventilators, oxygen cylinders, ICU beds, or monitors for surge capacity.\n\n"
      "Browse available listings or check your active requests.",
      options: const ["Browse Equipment to Request", "View Requests"],
      showMainMenuButton: true,
    );
  }

  // HOSPITAL 3: Rent Equipment
  Future<void> handleHospitalRentEquipment() async {
    _addBotMessage(
      "🏥 Equipment Rental for Medical Facilities\n\n"
      "Rent certified medical devices on daily or weekly terms from verified healthcare suppliers.\n"
      "Includes instant invoice generation and maintenance tracking.",
      options: const ["View Equipment to Rent", "Open Rentals"],
      showMainMenuButton: true,
    );
  }

  // RECIPIENT 2: Search Equipment
  Future<void> handleRecipientSearchEquipment() async {
    _addBotMessage(
      "🔍 Search Medical Equipment\n\n"
      "Find ICU equipment, wheelchairs, oxygen concentrators, hospital beds, and patient monitors.\n"
      "Filter by location, category, or rental mode.",
      options: const ["Open Search Screen", "View Available Equipment"],
      showMainMenuButton: true,
    );
  }

  // RECIPIENT 3: Rent Equipment
  Future<void> handleRecipientRentEquipment() async {
    _addBotMessage(
      "🤝 Rent Medical Equipment\n\n"
      "• Browse items marked for rent\n"
      "• Select rental start and return dates\n"
      "• Securely pay deposit & per-day rental fee via Razorpay\n"
      "• Live GPS delivery tracking once dispatched\n"
      "• 100% deposit refunded upon return in intact condition.",
      options: const ["View Equipment to Rent", "Open Rentals"],
      showMainMenuButton: true,
    );
  }

  // ── Delete a single message from state ──────────────────────────────
  void deleteMessage(String messageId) {
    _messages.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }
}
