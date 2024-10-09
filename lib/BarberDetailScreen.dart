import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BarberDetailScreen extends StatelessWidget {
  final QueryDocumentSnapshot barber;

  BarberDetailScreen({required this.barber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de ${barber['name']}'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(barber['imageUrl']),
                radius: 80,
              ),
              SizedBox(height: 20),
              Text(
                barber['name'],
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                barber['description'],
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                'Contacto: ${barber['phoneNumber']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  _launchWhatsApp(barber['phoneNumber']);
                },
                child: Text('Contactar por WhatsApp'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchWhatsApp(String phoneNumber) async {
    final url = 'https://wa.me/$phoneNumber?text=Hola%20quisiera%20saber%20sobre%20tus%20servicios';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print('No se pudo abrir WhatsApp');
    }
  }
}
