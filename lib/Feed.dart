import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ReviewTile.dart'; // Importa el panel de administración

class FeedPage extends StatefulWidget {
  final User user;

  FeedPage({required this.user});

  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final TextEditingController _reviewController = TextEditingController();
  int _rating = 0;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  // Verificar si el usuario es admin desde Firebase
  Future<void> _checkAdminStatus() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .get();

    setState(() {
      isAdmin = userDoc['isAdmin'] ?? false;
    });
  }

  // Mostrar el modal para dejar una reseña
  void _showReviewModal({String? existingReviewId, String? existingComment, int? existingStars}) {
    if (existingReviewId != null) {
      _reviewController.text = existingComment ?? '';
      _rating = existingStars ?? 0;
    } else {
      _reviewController.clear();
      _rating = 0;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(existingReviewId != null ? 'Editar reseña' : 'Dejar una reseña'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.yellow,
                      ),
                      onPressed: () {
                        setModalState(() {
                          _rating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                TextField(
                  controller: _reviewController,
                  decoration: InputDecoration(hintText: 'Escribe tu reseña'),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Cancelar'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: Text('Enviar'),
                onPressed: () {
                  if (_rating > 0 && _reviewController.text.isNotEmpty) {
                    if (existingReviewId != null) {
                      _updateReview(existingReviewId);
                    } else {
                      _addReview();
                    }
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Agregar reseña a Firebase
  void _addReview() async {
    await FirebaseFirestore.instance.collection('reseñas').add({
      'userId': widget.user.uid,
      'displayName': widget.user.displayName,
      'comment': _reviewController.text,
      'stars': _rating,
      'date': FieldValue.serverTimestamp(),
      'likes': [], // Campo "likes" inicializado como lista vacía
      'photoURL': widget.user.photoURL ?? '', // Usar photoURL de Google si está disponible
    });

    setState(() {
      _reviewController.clear();
      _rating = 0;
    });
  }

  // Editar reseña en Firebase
  void _updateReview(String reviewId) async {
    await FirebaseFirestore.instance.collection('reseñas').doc(reviewId).update({
      'comment': _reviewController.text,
      'stars': _rating,
      'date': FieldValue.serverTimestamp(),
    });

    setState(() {
      _reviewController.clear();
      _rating = 0;
    });
  }

  // Marcar "Me gusta" en una reseña
  void _likeReview(String reviewId, List<dynamic> currentLikes) async {
    final userId = widget.user.uid;

    if (currentLikes.contains(userId)) {
      // Si ya le dio "Me gusta", eliminar el "Me gusta"
      currentLikes.remove(userId);
    } else {
      // Si no ha dado "Me gusta", agregarlo
      currentLikes.add(userId);
    }

    await FirebaseFirestore.instance.collection('reseñas').doc(reviewId).update({
      'likes': currentLikes,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('reseñas').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var reviews = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              var review = reviews[index];
              var likes = List<String>.from(review['likes']);
              bool liked = likes.contains(widget.user.uid);
              String photoURL = review['photoURL'] ?? '';

              return ReviewTile(
                displayName: review['displayName'],
                comment: review['comment'],
                stars: review['stars'],
                date: review['date'] != null ? review['date'].toDate() : DateTime.now(),
                liked: liked,
                likeCount: likes.length,
                photoURL: photoURL, // Asignar la URL de la foto
                isOwner: review['userId'] == widget.user.uid, // Verificar si es el dueño de la reseña
                isAdmin: isAdmin, // Pasar si es administrador
                onLike: () => _likeReview(review.id, likes),
                onEdit: () {
                  if (review['userId'] == widget.user.uid) {
                    _showReviewModal(
                      existingReviewId: review.id,
                      existingComment: review['comment'],
                      existingStars: review['stars'],
                    );
                  }
                },
                onDelete: () async {
                  if (isAdmin) { // Solo el administrador puede eliminar
                    await FirebaseFirestore.instance.collection('reseñas').doc(review.id).delete();
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReviewModal(),
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
