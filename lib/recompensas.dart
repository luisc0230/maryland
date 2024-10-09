import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecompensasPage extends StatefulWidget {
  final int userCoins;
  final bool isAdmin;

  RecompensasPage({required this.userCoins, required this.isAdmin});

  @override
  _RecompensasPageState createState() => _RecompensasPageState();
}

class _RecompensasPageState extends State<RecompensasPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  bool _isEditing = false;
  String? _editingRewardId;
  late int _currentUserCoins;

  @override
  void initState() {
    super.initState();
    _currentUserCoins = widget.userCoins;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recompensas Disponibles',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showRewardDialog(context),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tus monedas actuales: $_currentUserCoins',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('recompensas').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final rewards = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: rewards.length,
                    itemBuilder: (context, index) {
                      final reward = rewards[index];
                      return _buildRewardCard(
                        icon: Icons.card_giftcard,
                        title: reward['title'],
                        description: 'Costo: ${reward['cost']} monedas',
                        onPressed: _currentUserCoins >= reward['cost']
                            ? () => _claimReward(reward.id, reward['cost'], reward['title'])
                            : null,
                        onEdit: widget.isAdmin ? () => _editReward(reward) : null,
                        onDelete: widget.isAdmin ? () => _deleteReward(reward.id) : null,
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

  Widget _buildRewardCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback? onPressed,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
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
            Icon(icon, color: Colors.green, size: 40.0),
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
                    description,
                    style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text('Reclamar'),
              onPressed: onPressed,
            ),
            if (onEdit != null || onDelete != null)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit' && onEdit != null) {
                    onEdit();
                  } else if (value == 'delete' && onDelete != null) {
                    onDelete();
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  if (onEdit != null)
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Editar'),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Eliminar'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Mostrar diálogo de recompensas
  void _showRewardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_isEditing ? 'Editar Recompensa' : 'Agregar Recompensa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Título'),
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                TextField(
                  controller: _costController,
                  decoration: const InputDecoration(labelText: 'Costo (monedas)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
                _resetForm();
              },
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () {
                if (_isEditing) {
                  _updateReward();
                } else {
                  _addReward();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Agregar una nueva recompensa
  void _addReward() {
    FirebaseFirestore.instance.collection('recompensas').add({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'cost': int.parse(_costController.text),
    });

    Navigator.of(context).pop();
    _resetForm();
  }

  // Editar recompensa
  void _editReward(QueryDocumentSnapshot reward) {
    setState(() {
      _isEditing = true;
      _editingRewardId = reward.id;
      _titleController.text = reward['title'];
      _descriptionController.text = reward['description'];
      _costController.text = reward['cost'].toString();
    });

    _showRewardDialog(context);
  }

  // Actualizar recompensa
  void _updateReward() {
    FirebaseFirestore.instance.collection('recompensas').doc(_editingRewardId).update({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'cost': int.parse(_costController.text),
    });

    Navigator.of(context).pop();
    _resetForm();
  }

  // Eliminar recompensa
  void _deleteReward(String rewardId) {
    FirebaseFirestore.instance.collection('recompensas').doc(rewardId).delete();
  }

  // Reclamar recompensa con manejo de errores de Firestore
  void _claimReward(String rewardId, int cost, String title) async {
    try {
      // Descontar monedas del usuario
      await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).update({
        'coins': FieldValue.increment(-cost),
      });

      // Agregar la recompensa reclamada a la colección `rewards_claimed`
      await FirebaseFirestore.instance.collection('rewards_claimed').add({
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'reward': title,
        'claimedAt': Timestamp.now(),
      });

      // Actualizar el estado de monedas locales
      setState(() {
        _currentUserCoins -= cost;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recompensa reclamada con éxito')),
      );
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        print("Índice necesario no encontrado, se requiere creación del índice.");
        _showIndexCreationAlert();
      }
    } catch (e) {
      print("Error al reclamar la recompensa: $e");
    }
  }

  // Mostrar alerta para la creación del índice en Firestore
  void _showIndexCreationAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error al reclamar la recompensa'),
          content: const Text(
              'La consulta requiere un índice en Firestore. Por favor, crea el índice necesario y vuelve a intentarlo.'),
          actions: [
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Restablecer formulario
  void _resetForm() {
    setState(() {
      _isEditing = false;
      _editingRewardId = null;
      _titleController.clear();
      _descriptionController.clear();
      _costController.clear();
    });
  }
}
