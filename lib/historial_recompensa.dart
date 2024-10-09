import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialRecompensaPage extends StatefulWidget {
  @override
  _HistorialRecompensaPageState createState() => _HistorialRecompensaPageState();
}

class _HistorialRecompensaPageState extends State<HistorialRecompensaPage> {
  final String _userId = FirebaseAuth.instance.currentUser!.uid; // Obtener ID del usuario actual
  bool _hasError = false; // Bandera para indicar si hubo un error de índice
  String _errorMessage = ''; // Mensaje de error para mostrar al usuario

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial de Recompensas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recompensas reclamadas:',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: _hasError
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 60),
                          const SizedBox(height: 20),
                          Text(
                            'Error al cargar recompensas:',
                            style: TextStyle(fontSize: 16.0, color: Colors.red),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _errorMessage,
                            style: TextStyle(fontSize: 14.0, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              _resetErrorState();
                              _loadRewards(); // Intentar cargar nuevamente
                            },
                            child: const Text('Intentar de nuevo'),
                          ),
                        ],
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('rewards_claimed')
                          .where('userId', isEqualTo: _userId)
                          .orderBy('claimedAt', descending: true) // Ordenar por fecha
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          // Mover el manejo de errores fuera del ciclo de construcción
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _handleFirestoreError(snapshot.error);
                          });
                          return const SizedBox.shrink(); // No mostrar nada si hay un error
                        }

                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final rewards = snapshot.data!.docs;

                        if (rewards.isEmpty) {
                          return const Center(
                            child: Text(
                              'No has reclamado ninguna recompensa aún.',
                              style: TextStyle(fontSize: 16.0, color: Colors.grey),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: rewards.length,
                          itemBuilder: (context, index) {
                            final reward = rewards[index];
                            return _buildRewardCard(
                              title: reward['reward'],
                              claimedAt: (reward['claimedAt'] as Timestamp).toDate(),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Construir la tarjeta de cada recompensa reclamada
  Widget _buildRewardCard({
    required String title,
    required DateTime claimedAt,
  }) {
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.card_giftcard, color: Colors.green, size: 40.0),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Reclamado el: ${_formatDate(claimedAt)}',
                    style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Formatear la fecha en un formato legible
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} a las ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Manejar el error de Firestore y detectar si es un problema de índice
  void _handleFirestoreError(Object? error) {
    if (mounted) {
      setState(() {
        _hasError = true;
        if (error.toString().contains('failed-precondition')) {
          _errorMessage =
              'La consulta requiere un índice. Por favor, crea el índice en Firestore e inténtalo nuevamente.';
        } else {
          _errorMessage = 'Ocurrió un error inesperado: $error';
        }
      });
    }
  }

  // Resetear el estado de error
  void _resetErrorState() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
  }

  // Intentar cargar recompensas nuevamente
  void _loadRewards() {
    setState(() {});
  }
}
