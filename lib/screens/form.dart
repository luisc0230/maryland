import 'dart:convert';
import 'dart:math'; // Para generar el orderId automáticamente
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MainForm extends StatefulWidget {
  MainForm({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MainFormState createState() => _MainFormState();
}

class _MainFormState extends State<MainForm> {
  String urlValue = "https://secure.micuentaweb.pe/vads-payment/entry.silentInit.a";
  String currencyValue = '604'; // Dólar 840 - Sol 604 - Euro 978
  String languageValue = 'es';
  late String? _dataModel;

  final formGlobalKey = GlobalKey<FormState>();
  String paymentModeValue = 'TEST'; // TEST - PRODUCTION

  // Controladores para los campos del formulario
  TextEditingController amountController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController(); // Teléfono

  // Función para generar orderId automáticamente
  String _generateOrderId() {
    final random = Random();
    int randomNumber = random.nextInt(999999); // Genera un número aleatorio de 6 dígitos
    return 'myOrderId-$randomNumber';
  }

  // Función para enviar el formulario
  Future<String?> _submitForm(String language, String amount, String email,
      String phone, String paymentMode, String currency) async {
    String amountInteger = (int.parse(amount) * 100).toString();
    String orderId = _generateOrderId(); // Generar orderId automáticamente

    try {
      var url = Uri.parse('https://nodejs-v8o9.onrender.com/url');

      var body = {
        'email': email,
        'phone': phone, // Campo de teléfono
        'amount': amountInteger,
        'currency': currency,
        'mode': paymentMode,
        'language': language,
        'orderId': orderId
      };

      var jsonData = json.encode(body);

      // Imprime los datos que se están enviando en la solicitud HTTP
      print("Datos enviados: $jsonData");

      var response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonData,
      );

      // Manejo de redirecciones 308 Permanent Redirect
      if (response.statusCode == 308 || response.statusCode == 301 || response.statusCode == 302) {
        var redirectUrl = response.headers['location'];
        if (redirectUrl != null) {
          print('Redirigiendo a: $redirectUrl');
          response = await http.post(
            Uri.parse(redirectUrl),
            headers: <String, String>{
              'Content-Type': 'application/json',
            },
            body: jsonData,
          );
        }
      }

      // Imprime el código de respuesta y el cuerpo de la respuesta
      print('Código de respuesta: ${response.statusCode}');
      print('Respuesta del servidor: ${response.body}');

      if (response.statusCode != 200) return null;
      var data = jsonDecode(response.body);
      String responseString = data['redirectionUrl'].toString();
      return responseString;
    } catch (error) {
      print('Error al realizar la solicitud HTTP: $error');
      return null;
    }
  }

  _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      urlValue = (prefs.getString("url") ?? "");
      currencyValue = (prefs.getString("currency") ?? currencyValue);
      languageValue = (prefs.getString("language") ?? languageValue);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(widget.title),
              new IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/configuration');
                  },
                  icon: new Icon(Icons.settings_rounded))
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: formGlobalKey,
            child: Wrap(
              spacing: 10,
              children: [
                // Amount
                const SizedBox(height: 50),
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                  ],
                  decoration: InputDecoration(labelText: "Monto", hintText: "0"),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Please enter an amount";
                    }
                  },
                ),
                // Email
                const SizedBox(height: 15),
                TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                        labelText: "Email", hintText: "example@email.com"),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return "Por favor ingresa tu correo";
                      }
                    }),
                // Phone (Teléfono)
                const SizedBox(height: 15),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                      labelText: "Teléfono", hintText: "Ingresa tu teléfono"),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "Por favor ingresa tu número de teléfono";
                    }
                  },
                ),
                const SizedBox(height: 60),

                ElevatedButton(
                    onPressed: () async {
                      String language = languageValue;
                      String amount = amountController.text;
                      String email = emailController.text;
                      String phone = phoneController.text.isNotEmpty ? phoneController.text : "+51999999999"; // Valor por defecto
                      String paymentMode = paymentModeValue;
                      String currency = currencyValue;

                      if (formGlobalKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Redirecting')),
                        );
                        String? data = await _submitForm(
                            language, amount, email, phone, paymentMode, currency);
                        setState(() {
                          _dataModel = data;
                        });
                        Navigator.pushNamed(context, '/webview',
                            arguments: {'response': data});
                      }
                    },
                    child: Text("Pagar ahora"))
              ],
            ),
          ),
        ));
  }
}
