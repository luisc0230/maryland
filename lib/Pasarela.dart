import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'exito.dart';  // Importar la página de éxito

class Pasarela extends StatefulWidget {
  final int amount;
  final String phone;
  final User user;

  Pasarela({required this.amount, required this.phone, required this.user});

  @override
  _PasarelaState createState() => _PasarelaState();
}

class _PasarelaState extends State<Pasarela> {
  late WebViewController _controller;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _orderId = _generateOrderId();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            print('Página cargada: $url');
            _checkForSuccess(url);  // Verificar si la transacción fue exitosa
          },
        ),
      );
    _initPaymentProcess();  // Inicia el proceso de pago
  }

  // Función para generar orderId automáticamente
  String _generateOrderId() {
    final random = Random();
    int randomNumber = random.nextInt(999999);
    return 'Maryland-$randomNumber';
  }

  // Función para enviar los datos del formulario y obtener la URL de la pasarela
  Future<void> _initPaymentProcess() async {
    String amountInCents = widget.amount.toString();
    String email = widget.user.email ?? 'correo@default.com';
    String phone = widget.phone;
    String orderId = _orderId ?? _generateOrderId();

    var url = Uri.parse('https://izimaryland.vercel.app/url');
    var body = {
      'email': email,
      'phone': phone,
      'amount': amountInCents,
      'currency': '604',
      'mode': 'TEST',
      'language': 'es',
      'orderId': orderId
    };

    var jsonData = json.encode(body);
    print("Datos enviados: $jsonData");

    try {
      var response = await http.post(
        url,
        headers: <String, String>{'Content-Type': 'application/json'},
        body: jsonData,
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        String redirectUrl = data['redirectionUrl'];
        print('Redirigiendo a: $redirectUrl');
        _controller.loadRequest(Uri.parse(redirectUrl));  // Cargar la URL en el WebView
      } else {
        print('Error en el servidor: ${response.statusCode}');
      }
    } catch (error) {
      print('Error en la solicitud HTTP: $error');
    }
  }

  // Función para detectar si la transacción fue exitosa o está en proceso de tarjeta
  void _checkForSuccess(String url) {
    if (url.contains('success') || url.contains('card_input')) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => ExitoPage()),  // Navegamos a la página de éxito
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Procesando Pago...'),
        backgroundColor: Colors.amber, // Cambia el color de fondo del AppBar
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // Icono para regresar
          onPressed: () {
            Navigator.pop(context); // Cerrar la pantalla al presionar el botón de retroceso
          },
        ),
      ),
      body: SafeArea( // Usamos SafeArea para que ocupe toda la pantalla de manera correcta
        child: Container(
          color: Colors.white, // Fondo blanco para evitar sombras
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }
}
