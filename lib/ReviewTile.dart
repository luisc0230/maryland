import 'package:flutter/material.dart';

class ReviewTile extends StatelessWidget {
  final String displayName;
  final String comment;
  final int stars;
  final DateTime date;
  final bool liked;
  final int likeCount; // Número de "me gusta"
  final String photoURL; // URL de la foto de perfil
  final bool isOwner; // Si el usuario es el propietario de la reseña
  final bool isAdmin; // Si el usuario es administrador
  final VoidCallback onLike;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  ReviewTile({
    required this.displayName,
    required this.comment,
    required this.stars,
    required this.date,
    required this.liked,
    required this.likeCount,
    required this.photoURL,
    required this.isOwner, // Determinar si es dueño de la reseña
    required this.isAdmin, // Determinar si es administrador
    required this.onLike,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Imagen del perfil
                CircleAvatar(
                  backgroundImage: photoURL.isNotEmpty
                      ? NetworkImage(photoURL) // Mostrar la foto de perfil
                      : AssetImage('assets/default_user.png') as ImageProvider, // Imagen predeterminada
                  radius: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < stars ? Icons.star : Icons.star_border,
                            color: Colors.yellow,
                            size: 16,
                          );
                        }),
                      ),
                      Text(
                        'Fecha: ${date.hour}:${date.minute.toString().padLeft(2, '0')}', // Formateo de la hora
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    // Botón de "me gusta" con contador
                    IconButton(
                      icon: Icon(
                        liked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        color: liked ? Colors.blue : Colors.grey,
                      ),
                      onPressed: onLike,
                    ),
                    Text(likeCount.toString()), // Mostrar número de likes

                    // Solo mostrar los tres puntos si el usuario es el dueño o si es admin
                    if (isOwner || isAdmin)
                      PopupMenuButton<String>(
                        onSelected: (String result) {
                          if (result == 'editar' && isOwner) {
                            onEdit();
                          } else if (result == 'eliminar' && isAdmin) {
                            onDelete();
                          }
                        },
                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                          if (isOwner) // Solo el dueño puede editar
                            const PopupMenuItem<String>(
                              value: 'editar',
                              child: Text('Editar'),
                            ),
                          if (isAdmin) // Solo el administrador puede eliminar
                            const PopupMenuItem<String>(
                              value: 'eliminar',
                              child: Text('Eliminar'),
                            ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(comment),
          ],
        ),
      ),
    );
  }
}
