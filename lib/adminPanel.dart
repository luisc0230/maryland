import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'notificaciones.dart'; // Importa la nueva pantalla

class AdminPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Notificaciones()), // Redirige a NotificacionPage
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('corte_solicitudes')
                  .where('status', whereIn: ['pendiente', 'descuento_pendiente'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var solicitudes = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: solicitudes.length,
                  itemBuilder: (context, index) {
                    var solicitud = solicitudes[index];
                    bool isDiscountRequest = solicitud['status'] == 'descuento_pendiente';

                    return ListTile(
                      title: Text(solicitud['displayName']),
                      subtitle: Text(
                        isDiscountRequest
                            ? 'Solicitud de descuento: ${solicitud['corte']} cortes, Teléfono: ${solicitud['telefono']}'
                            : 'Corte: ${solicitud['corte']}, Teléfono: ${solicitud['telefono']}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () async {
                          if (isDiscountRequest) {
                            await _approveDiscount(solicitud);
                          } else {
                            await _approveCorte(solicitud);
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isDiscountRequest
                                  ? 'Descuento aprobado para ${solicitud['displayName']}'
                                  : 'Corte aprobado para ${solicitud['displayName']}'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Recompensas Reclamadas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('rewards_claimed')
                  .orderBy('claimedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var rewards = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    var reward = rewards[index];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(reward['userId']).get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const ListTile(
                            title: Text('Cargando información del usuario...'),
                          );
                        }

                        var userData = userSnapshot.data!.data() as Map<String, dynamic>?;

                        return ListTile(
                          title: Text('Nombre: ${userData?['displayName'] ?? 'Desconocido'}'),
                          subtitle: Text('Correo: ${userData?['email'] ?? 'Desconocido'}'),
                          trailing: Text(
                            'Recompensa: ${reward['reward']}\nFecha: ${(reward['claimedAt'] as Timestamp).toDate()}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveCorte(DocumentSnapshot solicitud) async {
    await FirebaseFirestore.instance.collection('corte_solicitudes').doc(solicitud.id).update({
      'status': 'aprobado',
      'corte': FieldValue.increment(1),
    });
  }

  Future<void> _approveDiscount(DocumentSnapshot solicitud) async {
    await FirebaseFirestore.instance.collection('corte_solicitudes').doc(solicitud.id).update({
      'status': 'aprobado',
      'corte': 0,
    });
  }
}
