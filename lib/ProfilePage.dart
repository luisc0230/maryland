import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // Para copiar al portapapeles
import 'dart:math'; // Importar para usar Random
import 'package:google_mobile_ads/google_mobile_ads.dart'; // Agregar import de Google Mobile Ads
import 'recompensas.dart';
import 'historial_recompensa.dart'; // Importar la nueva página de historial de recompensas

class ProfilePage extends StatefulWidget {
  final User user;

  ProfilePage({required this.user});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _photoURL;
  String? _inviteCode;
  TextEditingController _inviteCodeController = TextEditingController();
  bool _hasClaimedCode = false;
  int _coins = 0;
  bool _isAdmin = false; // Variable para almacenar si es administrador
  RewardedAd? _rewardedAd;
  bool _isLoadingAd = false;
  int _coinsPerAd = 5; // Monedas ganadas por anuncio
  int _adsViewedToday = 0; // Contador de anuncios vistos hoy
  int _maxAdsPerDay = 3; // Límite de anuncios por día
  Duration? _timeLeft; // Tiempo restante para ver anuncios nuevamente

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Cargar el perfil del usuario al iniciar la pantalla
    _loadRewardedAd(); // Cargar anuncio bonificado
    _loadAdsViewedToday(); // Cargar la cantidad de anuncios vistos hoy
  }

  // Función para cargar el perfil del usuario desde Firestore
  void _loadUserProfile() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .get();

    final data = userDoc.data() as Map<String, dynamic>?;

    if (data != null) {
      setState(() {
        _photoURL = data['photoURL'] ?? widget.user.photoURL;
        _inviteCode = data['inviteCode'] ?? '';
        _hasClaimedCode = data['hasClaimedCode'] ?? false;
        _coins = data['coins'] ?? 0;
        _isAdmin = data['isAdmin'] ?? false; // Cargar si el usuario es administrador
        _adsViewedToday = data['adsViewedToday'] ?? 0;
        _calculateTimeLeft(data['lastAdView'] != null ? data['lastAdView'].toDate() : DateTime.now());

        // Generar código de invitación si no existe
        if (_inviteCode == null || _inviteCode!.isEmpty) {
          _generateUniqueCode().then((code) {
            FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
              'inviteCode': code,
            });
            setState(() {
              _inviteCode = code;
            });
          });
        }
      });
    }
  }

    void _refreshUserProfile() async {
    _loadUserProfile();
    setState(() {});
  }
  

  // Función para calcular el tiempo restante para ver anuncios nuevamente
  void _calculateTimeLeft(DateTime lastView) {
    final now = DateTime.now();
    final nextAvailableTime = lastView.add(Duration(hours: 24)); // Siguiente disponibilidad 24 horas después
    if (now.isBefore(nextAvailableTime)) {
      setState(() {
        _timeLeft = nextAvailableTime.difference(now);
      });
    } else {
      setState(() {
        _timeLeft = null;
      });
    }
  }

  // Función para generar un código de invitación único
  Future<String> _generateUniqueCode() async {
    final random = Random();
    String code;
    bool exists = false;

    do {
      int randomNumber = random.nextInt(100000000);
      code = 'M-${randomNumber.toString().padLeft(8, '0')}';

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('inviteCode', isEqualTo: code)
          .get();

      exists = querySnapshot.docs.isNotEmpty;
    } while (exists);

    return code;
  }

  // Función para cargar la cantidad de anuncios vistos hoy desde Firestore
  void _loadAdsViewedToday() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .get();

    final data = userDoc.data() as Map<String, dynamic>?;

    if (data != null) {
      setState(() {
        _adsViewedToday = data['adsViewedToday'] ?? 0;
      });
    }
  }

  // Función para cargar el anuncio bonificado
  void _loadRewardedAd() {
    setState(() {
      _isLoadingAd = true;
    });

    RewardedAd.load(
      adUnitId: 'ca-app-pub-3174552065060519/1952017206', // Cambia este ID con el tuyo
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print('Anuncio bonificado cargado');
          setState(() {
            _rewardedAd = ad;
            _isLoadingAd = false;
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Error al cargar el anuncio bonificado: $error');
          setState(() {
            _rewardedAd = null;
            _isLoadingAd = false;
          });
        },
      ),
    );
  }

  // Función para mostrar el anuncio bonificado
  void _showRewardedAd() {
    if (_adsViewedToday >= _maxAdsPerDay) {
      _showAdLimitReachedAlert(); // Mostrar alerta si se alcanzó el límite de anuncios
      return;
    }

    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (RewardedAd ad) {
          print('El anuncio bonificado se está mostrando.');
        },
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          print('El anuncio bonificado se ha cerrado.');
          ad.dispose();
          _loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          print('Error al mostrar el anuncio bonificado: $error');
          ad.dispose();
          _rewardedAd = null;
          _loadRewardedAd();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          print('Usuario ha ganado la recompensa de $_coinsPerAd monedas');
          setState(() {
            _coins += _coinsPerAd; // Usar la cantidad personalizada en lugar de reward.amount
            _adsViewedToday += 1;
          });

          FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
            'coins': FieldValue.increment(_coinsPerAd),
            'adsViewedToday': _adsViewedToday,
            'lastAdView': DateTime.now(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('¡Has ganado $_coinsPerAd monedas!')),
          );

          _loadAdsViewedToday(); // Actualizar el contador
        },
      );

      setState(() {
        _rewardedAd = null;
      });
    } else {
      print('Anuncio bonificado no disponible');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anuncio no disponible, intenta más tarde.')),
      );
      _loadRewardedAd(); // Intentar cargar el anuncio nuevamente
    }
  }

  // Función para copiar el código de invitación al portapapeles
  void _copyInviteCode() {
    if (_inviteCode != null) {
      Clipboard.setData(ClipboardData(text: _inviteCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código copiado al portapapeles')),
      );
    }
  }

  // Función para reclamar el código de invitación
  void _claimInviteCode() async {
    if (_hasClaimedCode) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya has reclamado un código de invitación')));
      return;
    }

    String enteredCode = _inviteCodeController.text.trim();

    if (enteredCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor ingresa un código de invitación')));
      return;
    }

    if (enteredCode == _inviteCode) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No puedes usar tu propio código')));
      return;
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('inviteCode', isEqualTo: enteredCode)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      DocumentSnapshot doc = querySnapshot.docs.first;
      String inviterId = doc.id;

      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({
        'hasClaimedCode': true,
        'coins': FieldValue.increment(1),
      });

      await FirebaseFirestore.instance.collection('users').doc(inviterId).update({
        'coins': FieldValue.increment(5),
      });

      setState(() {
        _hasClaimedCode = true;
        _coins += 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código reclamado exitosamente')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código de invitación no válido')));
    }
  }



  // Mostrar alerta de límite de anuncios alcanzado
  void _showAdLimitReachedAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final nextAvailableTime = DateTime.now().add(_timeLeft ?? Duration());
        return AlertDialog(
          title: const Text('Límite de Anuncios Alcanzado'),
          content: _timeLeft != null
              ? Text(
                  'Has alcanzado el límite de anuncios por hoy.\n\n'
                  'Tiempo restante para ver más anuncios: ${_formatDuration(_timeLeft!)}.\n\n'
                  'Podrás ver anuncios nuevamente a las ${_formatTime(nextAvailableTime)}.',
                )
              : const Text('Has alcanzado el límite de anuncios por hoy.'),
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

  // Formatear la duración en horas y minutos
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  // Formatear la hora en formato de 24 horas (ejemplo: 14:30)
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard),
            onPressed: () async {
              // Al navegar a la página de recompensas, esperar el resultado
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecompensasPage(
                    userCoins: _coins,
                    isAdmin: _isAdmin, // Pasar la variable isAdmin para administrar recompensas
                  ),
                ),
              );
              // Al regresar, actualizar el perfil del usuario
              _refreshUserProfile();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              // Al navegar a la página de historial, esperar el resultado
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistorialRecompensaPage(),
                ),
              );
              // Al regresar, actualizar el perfil del usuario
              _refreshUserProfile();
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: isKeyboardOpen
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _photoURL != null
                          ? NetworkImage(_photoURL!)
                          : const AssetImage('assets/default_user.png') as ImageProvider,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.user.displayName ?? 'Usuario',
                      style: const TextStyle(fontSize: 20),
                    ),
                    Text(
                      widget.user.email ?? 'Correo no disponible',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    if (_inviteCode != null && _inviteCode!.isNotEmpty)
                      Column(
                        children: [
                          const Text('Tu código de invitación:'),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _copyInviteCode,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _inviteCode!,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.copy, color: Colors.blue),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 30),
                    if (!_hasClaimedCode)
                      Column(
                        children: [
                          TextField(
                            controller: _inviteCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Ingresa código de invitación',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _claimInviteCode,
                            child: const Text('Reclamar código'),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    Text('Monedas: $_coins',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showRewardedAd, // Siempre habilitado, muestra la alerta si es necesario
                      child: const Text('Ver Anuncio para Ganar Monedas'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}