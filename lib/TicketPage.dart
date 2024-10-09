import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class TicketPage extends StatefulWidget {
  final User user; // Usuario actual

  TicketPage({required this.user});

  @override
  _TicketPageState createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  int completedCircles = 0;
  bool isRedeeming = false; // Estado para deshabilitar el botón de canje
  TextEditingController _phoneController = TextEditingController();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadCompletedCircles(); // Cargar el progreso del usuario
  }

  // Inicializar notificaciones locales
  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // Lógica para manejar notificaciones en primer plano en iOS
      },
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Lógica para manejar la selección de la notificación en la versión actual
        if (notificationResponse.payload != null) {
          print('Notificación seleccionada con payload: ${notificationResponse.payload}');
        }
      },
    );
  }

  // Cargar el número de cortes completados del usuario
  void _loadCompletedCircles() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('corte_solicitudes')
        .doc(widget.user.uid)
        .get();

    if (snapshot.exists && snapshot['corte'] != null) {
      setState(() {
        completedCircles = snapshot['corte'];
      });
    }
  }

  // Verificar si hay una solicitud pendiente antes de enviar una nueva
  void _completeNextCircle() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('corte_solicitudes')
        .where('userId', isEqualTo: widget.user.uid)
        .where('status', isEqualTo: 'pendiente')
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ya tienes una solicitud pendiente.')),
      );
      return;
    }

    if (completedCircles < 5) {
      _showPhoneInputDialog(); // Solicitar el teléfono del usuario
    } else {
      _redeemDiscountRequest(); // Solicitar el canje del descuento al administrador
    }
  }

  // Mostrar el diálogo para pedir el teléfono
  void _showPhoneInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ingresar número de teléfono'),
        content: TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(hintText: 'Ingrese su número de teléfono'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              String phone = _phoneController.text.trim();
              if (phone.isNotEmpty) {
                Navigator.pop(context);
                _sendCorteRequest(phone); // Enviar solicitud con el teléfono
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Por favor, ingrese un número de teléfono válido.')),
                );
              }
            },
            child: Text('Enviar'),
          ),
        ],
      ),
    );
  }

  // Enviar la solicitud de corte a Firebase
  void _sendCorteRequest(String phone) async {
    final user = widget.user;

    // Actualizar o agregar la solicitud
    await FirebaseFirestore.instance.collection('corte_solicitudes').doc(user.uid).set({
      'userId': user.uid,
      'displayName': user.displayName,
      'email': user.email,
      'telefono': phone,
      'corte': completedCircles + 1,
      'status': 'pendiente',
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _sendNotificationToPhone('Solicitud enviada', 'Tu solicitud de corte ha sido enviada.');

    setState(() {
      completedCircles++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Solicitud de corte enviada.')),
    );
  }

  // Solicitar el canje del descuento
  void _redeemDiscountRequest() async {
    final user = widget.user;

    setState(() {
      isRedeeming = true; // Deshabilitar botón hasta que se apruebe
    });

    // Enviar la solicitud de canje del descuento
    await FirebaseFirestore.instance.collection('corte_solicitudes').doc(user.uid).update({
      'status': 'descuento_pendiente',
    });

    _sendNotificationToPhone('Descuento canjeado', 'Descuento canjeado, validar.');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Solicitud de descuento enviada. Esperando validación.')),
    );
  }

  // Enviar notificación al celular
  void _sendNotificationToPhone(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  // Método para restablecer el número de cortes a 0 después de la aprobación del descuento
  void _resetCorte() async {
    await FirebaseFirestore.instance.collection('corte_solicitudes').doc(widget.user.uid).update({
      'corte': 0,
      'status': 'aprobado',
    });

    _sendNotificationToPhone('Corte aprobado', 'Tu descuento ha sido aprobado.');
    setState(() {
      completedCircles = 0;
      isRedeeming = false; // Habilitar botón de nuevo
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Descuento aprobado. ¡Ahora puedes comenzar de nuevo!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'El 5to corte al 50%',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Progreso de cortes:',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                Icons.circle,
                size: 50,
                color: index < completedCircles ? Colors.green : Colors.grey,
              );
            }),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: (completedCircles < 5 && !isRedeeming) ? _completeNextCircle : (isRedeeming ? null : _redeemDiscountRequest),
            child: Text(completedCircles < 5 ? 'Marcar próximo corte' : 'Canjear descuento'),
          ),
          SizedBox(height: 10), // Espacio adicional
          Text(
            'Para mayor rapidez de aprobación enviar WhatsApp a "937574978"',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
