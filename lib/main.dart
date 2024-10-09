import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

import 'HomePage.dart';
import 'SignInPage.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con las opciones de la plataforma actual
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configura Firebase Messaging y Local Notifications para Android
  if (Platform.isAndroid) {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    String? fcmToken = await messaging.getToken();
    print("Token de FCM en Android: $fcmToken");

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings, onDidReceiveNotificationResponse: (notificationResponse) async {
      if (notificationResponse.payload != null) {
        print('Notificación seleccionada con payload: ${notificationResponse.payload}');
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'channel_id',
              'channel_name',
              channelDescription: 'channel_description',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: false,
            ),
          ),
        );
      }
    });
  } else {
    print("Notificaciones locales y FCM no se inicializarán en iOS.");
  }

  // Cargar preferencia de tema desde SharedPreferences
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;

  runApp(MyApp(isDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool isDarkMode;

  MyApp({required this.isDarkMode});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
  }

  // Alternar entre tema claro y oscuro y actualizar preferencia en Firebase
  void toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = !isDarkMode;
      prefs.setBool('isDarkMode', isDarkMode); // Guardar la preferencia
    });

    // Actualizar la preferencia de tema en la base de datos del usuario
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'isDarkMode': isDarkMode});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: isDarkMode
          ? ThemeData.dark().copyWith(
              primaryColor: Colors.amber,
              appBarTheme: AppBarTheme(backgroundColor: Colors.grey[900]),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white),
                labelLarge: TextStyle(color: Colors.white),
              ).apply(fontFamily: 'KGRedHands'),
            )
          : ThemeData(
              primaryColor: const Color(0xFFFFD700),
              appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFFD700)),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD700),
                  foregroundColor: const Color(0xFF000000),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black),
                bodyMedium: TextStyle(color: Colors.black),
                labelLarge: TextStyle(color: Colors.black),
              ).apply(fontFamily: 'KGRedHands'),
            ),
      home: AuthWrapper(toggleTheme: toggleTheme, isDarkMode: isDarkMode),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  AuthWrapper({required this.toggleTheme, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            var userData = snapshot.data!.data() as Map<String, dynamic>;
            // Obtener el valor de isDarkMode desde la base de datos de Firebase
            bool isDarkModeFromDb = userData['isDarkMode'] ?? isDarkMode;

            return HomePage(
              user: user,
              toggleTheme: toggleTheme,
              isDarkMode: isDarkModeFromDb, // Pasar el valor actualizado a HomePage
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()), // Muestra un indicador de carga mientras se obtienen los datos
            );
          } else {
            return Scaffold(
              body: Center(child: Text("Error al obtener datos del usuario")),
            );
          }
        },
      );
    } else {
      return SignInPage(toggleTheme: toggleTheme, isDarkMode: isDarkMode);
    }
  }
}
