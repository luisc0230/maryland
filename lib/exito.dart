import 'package:flutter/material.dart';

class ExitoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transacción Exitosa'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 100.0,
            ),
            SizedBox(height: 20),
            Text(
              '¡Transacción realizada con éxito!',
              style: TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Gracias por su pago. Cualquier duda, contáctenos al 937574978.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Volver a la pantalla anterior
              },
              child: Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
