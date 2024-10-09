import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SignInPage.dart';
import 'locales.dart';
import 'TicketPage.dart'; // Importa la página de tickets
import 'AdminPanel.dart'; // Importa el panel de administración
import 'Feed.dart'; // Importa la página de reseñas
import 'ProfilePage.dart'; // Importa la página de perfil
import 'Pasarela.dart'; // Importa la pasarela de pagos
import 'BarberList.dart';
import 'subscripcion.dart';
class HomePage extends StatefulWidget {
  final User user;
  final VoidCallback toggleTheme; // Función para alternar entre modo oscuro y claro
  final bool isDarkMode; // Booleano para determinar si el tema actual es oscuro

  HomePage({required this.user, required this.toggleTheme, required this.isDarkMode});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool isAdmin = false;
  bool _isMenuOpen = false; // Variable para controlar el estado del menú flotante

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  // Verifica si el usuario tiene permisos de administrador
  Future<void> _checkAdminStatus() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get();
    setState(() {
      isAdmin = doc['isAdmin'] ?? false;
    });
  }

  // Función para alternar el estado del botón de hamburguesa y el menú flotante
  void _toggleMenuState() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  // Muestra un modal con la información de pago
  void _showPasarelaModal() {
    TextEditingController _amountController = TextEditingController();
    TextEditingController _phoneController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detalles de Pago'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto a Cobrar (S/)',
                  hintText: 'Ejemplo: 10.00',
                ),
              ),
              SizedBox(height: 15),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Número de Teléfono',
                  hintText: 'Ejemplo: +51987654321',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Continuar'),
              onPressed: () {
                String amountText = _amountController.text;
                String phoneText = _phoneController.text;

                if (amountText.isNotEmpty && phoneText.isNotEmpty) {
                  double? amountDouble = double.tryParse(amountText);
                  if (amountDouble != null && amountDouble > 0) {
                    int amountInCents = (amountDouble * 100).round();
                    Navigator.of(context).pop(); // Cierra el modal anterior
                    _redirectToPasarela(amountInCents, phoneText); // Redirige a la nueva página
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ingrese un monto válido')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Complete todos los campos')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Redirige a la página de la pasarela de pago
  void _redirectToPasarela(int amountInCents, String phone) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Pasarela(
          amount: amountInCents,
          phone: phone,
          user: widget.user,
        ),
      ),
    );
  }

  // Obtiene el título del AppBar según la pestaña seleccionada
  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return '¡Bienvenido, ${widget.user.displayName}!';
      case 1:
        return 'Nuestros Locales';
      case 2:
        return 'Reseñas';
      case 3:
        return 'Pasarela';
      case 4:
        return 'Ticket';
      default:
        return 'App';
    }
  }

  final List<Widget> _widgetOptions = <Widget>[
    BarberList(),
    Locales(),
    FeedPage(user: FirebaseAuth.instance.currentUser!), // Página de reseñas
    Text('Pasarela'), // Placeholder para la pasarela
    TicketPage(user: FirebaseAuth.instance.currentUser!), // Página de ticket
  ];

  // Controla el cambio de pestaña en el BottomNavigationBar
  void _onItemTapped(int index) {
    if (index == 3) {
      _showPasarelaModal(); // Mostrar modal al seleccionar "Pasarela"
    } else {
      setState(() {
        _selectedIndex = index;
        _isMenuOpen = false; // Restablecer el estado del menú cada vez que se cambia de pestaña
      });
    }
  }

  // Cerrar sesión y redirigir a la página de inicio de sesión
  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SignInPage(
          toggleTheme: widget.toggleTheme,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Integración de FutureBuilder para verificar y mostrar el valor de isDarkMode desde Firestore
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()), // Muestra un indicador de carga mientras se obtienen los datos
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error al obtener datos del usuario")),
          );
        }

        if (snapshot.hasData) {
          // Actualiza el valor de isDarkMode según la base de datos
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          bool isDarkModeFromDb = userData['isDarkMode'] ?? widget.isDarkMode;

          return Scaffold(
            appBar: AppBar(
              backgroundColor: isDarkModeFromDb ? Colors.grey[900] : Colors.amber,
              title: Text(
                _getAppBarTitle(),
                style: TextStyle(
                  fontSize: _selectedIndex == 0 ? 16.0 : 20.0,
                  fontFamily: 'KGRedHands',
                  color: isDarkModeFromDb ? Colors.white : Colors.black,
                ),
              ),
              actions: [
                if (isAdmin)
                  IconButton(
                    icon: Icon(Icons.admin_panel_settings, color: isDarkModeFromDb ? Colors.white : Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AdminPanel()),
                      );
                    },
                  ),
                IconButton(
                  icon: Icon(isDarkModeFromDb ? Icons.brightness_7 : Icons.brightness_2, color: isDarkModeFromDb ? Colors.white : Colors.black),
                  onPressed: () {
                    widget.toggleTheme();
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: Icon(Icons.person, color: isDarkModeFromDb ? Colors.white : Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(user: widget.user),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.exit_to_app, color: isDarkModeFromDb ? Colors.white : Colors.black),
                  onPressed: _signOut,
                ),
              ],
            ),
            body: _widgetOptions.elementAt(_selectedIndex),
            bottomNavigationBar: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDarkModeFromDb ? Colors.black : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: isDarkModeFromDb ? Colors.black54 : Colors.black12,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.home),
                        color: _selectedIndex == 0
                            ? (isDarkModeFromDb ? Colors.amber : Colors.blue)
                            : (isDarkModeFromDb ? Colors.grey[400] : Colors.grey),
                        onPressed: () => _onItemTapped(0),
                      ),
                      IconButton(
                        icon: Icon(Icons.location_on),
                        color: _selectedIndex == 1
                            ? (isDarkModeFromDb ? Colors.amber : Colors.blue)
                            : (isDarkModeFromDb ? Colors.grey[400] : Colors.grey),
                        onPressed: () => _onItemTapped(1),
                      ),
                      SizedBox(width: 68),
                      IconButton(
                        icon: Icon(Icons.payment),
                        color: _selectedIndex == 3
                            ? (isDarkModeFromDb ? Colors.amber : Colors.blue)
                            : (isDarkModeFromDb ? Colors.grey[400] : Colors.grey),
                        onPressed: () => _onItemTapped(3),
                      ),
                      IconButton(
                        icon: Icon(Icons.confirmation_number),
                        color: _selectedIndex == 4
                            ? (isDarkModeFromDb ? Colors.amber : Colors.blue)
                            : (isDarkModeFromDb ? Colors.grey[400] : Colors.grey),
                        onPressed: () => _onItemTapped(4),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDarkModeFromDb ? Colors.grey[850] : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isDarkModeFromDb ? Colors.black54 : Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FloatingActionButton(
                      onPressed: () {
                        _showHamburgerMenu(context, _toggleMenuState);
                      },
                      backgroundColor: isDarkModeFromDb ? Colors.deepPurple[700] : Colors.purple,
                      child: Icon(
                        _isMenuOpen ? Icons.close : Icons.menu,
                        color: isDarkModeFromDb ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return CircularProgressIndicator(); // Mostrar indicador de carga si los datos no están listos
      },
    );
  }

  // Método para mostrar el menú flotante con más opciones y botón de cierre centrado
  void _showHamburgerMenu(BuildContext context, Function toggleMenuState) {
    toggleMenuState();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Stack(
        alignment: Alignment.bottomCenter,
        children: [
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.only(top: 20, bottom: 60),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 10,
                      children: [
                        _buildMenuOption('Orders', Icons.shopping_bag, widget.isDarkMode ? Colors.white : Colors.purple, () {
                          Navigator.pop(context);
                          toggleMenuState();
                        }),
                       // Cambia esta parte en tu código HomePage o donde esté definida la función _buildMenuOption:
_buildMenuOption('Payments', Icons.payment, widget.isDarkMode ? Colors.white : Colors.pink, () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SubscriptionPage(
        isDarkMode: widget.isDarkMode, // Pasa el valor del modo oscuro a la nueva página
      ),
    ),
  );
  toggleMenuState();
}),

                        _buildMenuOption('Addresses', Icons.location_on, widget.isDarkMode ? Colors.white : Colors.green, () {
                          Navigator.pop(context);
                          toggleMenuState();
                        }),
                        _buildMenuOption('Wishlist', Icons.favorite, widget.isDarkMode ? Colors.white : Colors.red, () {
                          Navigator.pop(context);
                          toggleMenuState();
                        }),
                        _buildMenuOption('Buy again', Icons.refresh, widget.isDarkMode ? Colors.white : Colors.lightBlue, () {
                          Navigator.pop(context);
                          toggleMenuState();
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'MORE OPTIONS',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.purple,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.settings, color: widget.isDarkMode ? Colors.white : Colors.grey),
                    title: Text('Settings', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
                    onTap: () {
                      Navigator.pop(context);
                      toggleMenuState();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.support_agent, color: widget.isDarkMode ? Colors.white : Colors.orange),
                    title: Text('Help & Support', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
                    onTap: () {
                      Navigator.pop(context);
                      toggleMenuState();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.info, color: widget.isDarkMode ? Colors.white : Colors.blue),
                    title: Text('About', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
                    onTap: () {
                      Navigator.pop(context);
                      toggleMenuState();
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.pop(context);
                toggleMenuState();
              },
              backgroundColor: widget.isDarkMode ? Colors.deepPurple[700] : Colors.purple,
              child: Icon(Icons.close, color: widget.isDarkMode ? Colors.white : Colors.black),
            ),
          ),
        ],
      ),
    ).then((_) {
      if (_isMenuOpen) {
        _toggleMenuState();
      }
    });
  }

  // Método auxiliar para crear las opciones del menú
  Widget _buildMenuOption(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
