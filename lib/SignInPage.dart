import 'dart:math'; // Importar para generar números aleatorios
import 'dart:io'; // Importar para usar Platform y condicionales basados en el sistema operativo
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Importa Firebase Messaging solo para Android
import 'HomePage.dart'; // Importa HomePage para la redirección después del inicio de sesión

class SignInPage extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  SignInPage({required this.toggleTheme, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inicio',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black, // Siempre cambia el color según el modo
            fontFamily: 'KGRedHands', // Aplicando la fuente KGRedHands
          ),
        ),
        backgroundColor: isDarkMode ? Colors.black : Color(0xFFFFD700), // Color de fondo del AppBar
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.brightness_7 : Icons.brightness_2), // Cambiar el icono de brillo
            onPressed: () {
              toggleTheme(); // Alterna entre el tema oscuro y claro
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png', // Asegúrate de que este archivo exista en tu proyecto
              height: 250.0,
            ),
            SizedBox(height: 30.0),
            ElevatedButton.icon(
              onPressed: () async {
                User? user = await signInWithGoogle(); // Iniciar sesión con Google
                if (user != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(
                        user: user,
                        toggleTheme: toggleTheme,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  );
                }
              },
              icon: Icon(Icons.login, size: 24, color: isDarkMode ? Colors.black : Colors.black),
              label: Text(
                'Iniciar sesión con Google',
                style: TextStyle(
                  fontFamily: 'KGRedHands', // Aplicando la fuente KGRedHands al botón
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método para iniciar sesión con Google
  Future<User?> signInWithGoogle() async {
    try {
      await GoogleSignIn().signOut(); // Cerrar sesión activa, si la hay

      // Inicia el flujo de autenticación de Google
      GoogleSignInAuthentication? googleSignInAuthentication = await (await GoogleSignIn(
        scopes: ["profile", "email"],
      ).signIn())
          ?.authentication;

      if (googleSignInAuthentication == null) {
        return null; // El usuario canceló el inicio de sesión
      }

      // Crear credenciales de Firebase a partir del token de Google
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      // Iniciar sesión en Firebase con las credenciales de Google
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        String? photoURL = user.photoURL;

        // Verificar si el usuario ya existe en Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (!userDoc.exists) {
          // Si el documento no existe, crear un nuevo usuario en Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'displayName': user.displayName,
            'email': user.email,
            'isAdmin': false,
            'photoURL': photoURL,
            'coins': 0, // Inicializa las monedas en 0 para nuevos usuarios
            'hasUsedInviteCode': false,
            'subscribedToGeneral': true, // Aquí marcamos la suscripción al tema
          });
        } else {
          // Si ya existe, actualiza solo la foto de perfil si es necesario
          if (userDoc['photoURL'] != photoURL) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'photoURL': photoURL,
            });
          }

          // Actualizar la suscripción al tema en Firestore
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'subscribedToGeneral': true,
          });
        }

        // Suscribir al usuario al tema "general" en FCM, solo en Android
        if (Platform.isAndroid) {
          await FirebaseMessaging.instance.subscribeToTopic('general');
        }
      }

      return user;
    } catch (e) {
      print('Error en la autenticación con Google: $e');
      return null;
    }
  }

  // Función para generar un código único en el formato M-00000000
  Future<String> _generateUniqueCode() async {
    final random = Random();
    String code;
    bool exists = false;

    do {
      // Generar código aleatorio con el formato M-00000000
      int randomNumber = random.nextInt(100000000);
      code = 'M-${randomNumber.toString().padLeft(8, '0')}';

      // Verificar si ya existe el código en Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('inviteCode', isEqualTo: code)
          .get();

      exists = querySnapshot.docs.isNotEmpty; // Si no está vacío, el código ya existe
    } while (exists); // Repetir si el código ya existe

    return code; // Retornar el código único generado
  }
}
