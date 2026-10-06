import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/app.dart';
import '../../providers/emergency_alert_provider.dart';

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background execution
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message received: ${message.messageId}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'medishare_alerts_v2', // id
    'MediShare Alerts', // name
    description: 'High priority alerts for emergencies',
    importance: Importance.max,
    playSound: true,
  );

  Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _requestPermission();
    await _initLocalNotifications();

    // Listen for Auth changes to update token
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await registerDeviceToken(user.uid);
        
        _messaging.onTokenRefresh.listen((newToken) {
          _saveTokenToFirestore(newToken, user.uid);
        });
      }
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle initial message if app was terminated
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
    debugPrint(
      '[FCM] User granted permission: ${settings.authorizationStatus}',
    );
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          _routeNotificationTap(data);
        }
      },
    );

    final platformPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (platformPlugin != null) {
      await platformPlugin.createNotificationChannel(_channel);
    }
  }

  Future<void> registerDeviceToken(String uid) async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] token generated');
        await _saveTokenToFirestore(token, uid);
      }
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token, String uid) async {
    try {
      debugPrint('[FCM] token write started');
      await _db.collection('users').doc(uid).collection('notificationTokens').doc(token).set({
        'token': token,
        'createdAt': FieldValue.serverTimestamp(),
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });
      debugPrint('[FCM] token write success');
    } catch (e) {
      debugPrint('[FCM] token write failed: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground notification received: ${message.messageId}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      debugPrint('[FCM] Showing local notification for foreground message');
      final isEmergency = message.data['notificationType'] == 'EMERGENCY_ALERT';

      _localNotificationsPlugin.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: !isEmergency,
          ),
        ),
        payload: jsonEncode(message.data),
      );
      
      if (isEmergency) {
        // Trigger a background provider refresh in case Socket didn't catch it
        final context = MediShareApp.navigatorKey.currentContext;
        if (context != null) {
          try {
            Provider.of<EmergencyAlertProvider>(context, listen: false).fetchActiveAlerts();
          } catch (_) {}
        }
      }
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint(
      '[FCM] Notification tapped (onMessageOpenedApp): ${message.messageId}',
    );
    _routeNotificationTap(message.data);
  }

  void _routeNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    final rentalId = data['rentalId'];
    final deliveryId = data['deliveryId'];
    
    // Use the global navigator key
    final navigator = MediShareApp.navigatorKey.currentState;
    if (navigator == null) return;
    
    // Just a placeholder routing logic, actual screens may differ.
    // In production, we'd load the model and navigate to specific detailed screens.
    if (type == 'rental' && rentalId != null) {
      debugPrint('[FCM] Navigate to rental: $rentalId');
      // navigator.pushNamed('/rental_detail', arguments: rentalId);
    } else if (type == 'delivery' && deliveryId != null) {
      debugPrint('[FCM] Navigate to delivery: $deliveryId');
      // navigator.pushNamed('/delivery_detail', arguments: deliveryId);
    }
  }
}
