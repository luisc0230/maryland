import 'dart:convert';
import 'dart:io'; // Importar para usar Platform y condicionales basados en el sistema operativo
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Mantener la importación para Android

class Notificaciones extends StatefulWidget {
  @override
  _NotificacionesState createState() => _NotificacionesState();
}

class _NotificacionesState extends State<Notificaciones> {
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _mensajeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inicializar FirebaseMessaging solo en Android
    if (Platform.isAndroid) {
      _initFirebaseMessaging();
    } else {
      print("FirebaseMessaging no se inicializa en iOS.");
    }
  }

  // Inicialización de Firebase Messaging
  void _initFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permisos de notificación otorgados en Android');
    } else {
      print('Permisos de notificación denegados en Android');
    }
  }

  // Cargar el archivo JSON de claves desde assets
  Future<ServiceAccountCredentials> _loadServiceAccountKey() async {
    final String serviceAccountKey =
        await rootBundle.loadString('assets/key.json'); // Asegúrate de que el archivo key.json esté en la carpeta assets.
    return ServiceAccountCredentials.fromJson(serviceAccountKey);
  }

  // Obtener un token de acceso mediante la clave privada
  Future<String> _getAccessToken() async {
    final credentials = await _loadServiceAccountKey();

    final authClient = await clientViaServiceAccount(
      credentials,
      ['https://www.googleapis.com/auth/firebase.messaging'], // Cambiamos a permisos específicos
    );

    try {
      return authClient.credentials.accessToken.data;
    } finally {
      authClient.close(); // Asegúrate de cerrar el cliente después de obtener el token.
    }
  }

  // Enviar notificación a todos los usuarios suscritos al tema "general"
  Future<void> _enviarNotificacionATodos() async {
    try {
      final accessToken = await _getAccessToken();

      final url = Uri.parse(
          'https://fcm.googleapis.com/v1/projects/marylandbarber-3f2c9/messages:send');

      final Map<String, dynamic> body = {
        "message": {
          "topic": "general", // Envía la notificación a todos los usuarios suscritos a este tema
          "notification": {
            "title": _tituloController.text,
            "body": _mensajeController.text,
          },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "id": "1",
            "status": "done"
          }
        }
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('Notificación enviada con éxito');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificación enviada con éxito')),
        );
      } else {
        print('Error al enviar la notificación: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar la notificación')),
        );
      }
    } catch (e) {
      print('Error al obtener el token o enviar la notificación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enviar Notificaciones"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(
                labelText: 'Título de la notificación',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _mensajeController,
              decoration: const InputDecoration(
                labelText: 'Mensaje de la notificación',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _enviarNotificacionATodos,
              child: const Text('Enviar Notificación a Todos'),
            ),
          ],
        ),
      ),
    );
  }
}
