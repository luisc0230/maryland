import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa Firestore
import 'package:firebase_auth/firebase_auth.dart'; // Importa FirebaseAuth para obtener el usuario actual
import 'package:url_launcher/url_launcher.dart'; // Para abrir WhatsApp
import 'EditBarberScreen.dart'; // Importa la pantalla para editar barberos
import 'AddBarberScreen.dart'; // Importa la pantalla para editar barberos

// Clase Barber para definir las propiedades de cada barbero
class Barber {
  final String id; // Añadimos un campo ID para el barbero
  final String name;
  final String imageUrl;
  final String description;
  final String phoneNumber;

  Barber({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.phoneNumber,
  });

  // Método estático para crear un Barber desde un documento de Firestore
  factory Barber.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

  return Barber(
    id: doc.id, // Obtén el ID del documento
    name: data['name'] ?? 'Sin nombre',
    imageUrl: (data['imageUrl'] != null && data['imageUrl'].isNotEmpty) 
              ? data['imageUrl'] 
              : 'https://via.placeholder.com/150', // URL de imagen por defecto si está vacía
    description: data['description'] ?? 'Sin descripción',
    phoneNumber: data['phoneNumber'] ?? 'Sin número',
  );
}
}

// Widget para mostrar la lista de barberos
class BarberList extends StatefulWidget {
  @override
  _BarberListState createState() => _BarberListState();
}

class _BarberListState extends State<BarberList> {
  bool isAdmin = false; // Para determinar si el usuario es administrador

  @override
  void initState() {
    super.initState();
    _checkAdminStatus(); // Verifica el estado de admin cuando la pantalla se inicia
  }

  Future<void> _checkAdminStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        isAdmin = doc['isAdmin'] ?? false;
      });
    }
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Lista de Barberos'),
      actions: isAdmin
          ? [
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddBarberScreen(), // Pantalla para agregar barberos
                    ),
                  );
                },
              ),
            ]
          : null,
    ),
    body: StreamBuilder(
      stream: FirebaseFirestore.instance.collection('barbers').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final barbers = snapshot.data!.docs.map((doc) => Barber.fromFirestore(doc)).toList();

        // Usamos GridView para mostrar los barberos en formato de cuadros
        return GridView.builder(
          padding: EdgeInsets.all(10),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Número de columnas en la cuadrícula
            crossAxisSpacing: 10.0, // Espacio horizontal entre los cuadros
            mainAxisSpacing: 10.0, // Espacio vertical entre los cuadros
            childAspectRatio: 3 / 4, // Relación de aspecto para ajustar la altura de los cuadros
          ),
          itemCount: barbers.length,
          itemBuilder: (context, index) {
            final barber = barbers[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BarberDetailScreen(barber: barber),
                  ),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15), // Bordes redondeados para las tarjetas
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Imagen del barbero
                      CircleAvatar(
                        backgroundImage: NetworkImage(barber.imageUrl),
                        radius: 40,
                      ),
                      SizedBox(height: 10),
                      Text(
                        barber.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 5),
                      Text(
                        barber.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      if (isAdmin)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditBarberScreen(barberId: barber.id),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _confirmDeleteBarber(barber);
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}


  // Método para confirmar la eliminación
  void _confirmDeleteBarber(Barber barber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar a ${barber.name}?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
            ),
            TextButton(
              child: Text('Eliminar'),
              onPressed: () {
                _deleteBarber(barber); // Llama al método de eliminar
                Navigator.of(context).pop(); // Cierra el diálogo después de eliminar
              },
            ),
          ],
        );
      },
    );
  }

  // Método para eliminar el barbero
  void _deleteBarber(Barber barber) async {
    await FirebaseFirestore.instance
        .collection('barbers')
        .doc(barber.id) // Elimina usando el ID del documento
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${barber.name} eliminado')),
    );
  }
}

// Pantalla de detalles del barbero
class BarberDetailScreen extends StatelessWidget {
  final Barber barber;

  BarberDetailScreen({required this.barber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles de ${barber.name}'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(barber.imageUrl),
                radius: 80,
              ),
              SizedBox(height: 20),
              Text(
                barber.name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                barber.description,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                'Contacto: ${barber.phoneNumber}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  _launchWhatsApp(barber.phoneNumber);
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
