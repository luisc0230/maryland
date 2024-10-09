import 'package:flutter/material.dart';

class Locales extends StatefulWidget {
  @override
  _LocalesState createState() => _LocalesState();
}

class _LocalesState extends State<Locales> {
  final List<Map<String, String>> locales = [
    {
      'nombre': 'Local 1 - Miraflores',
      'direccion': 'Av. Larco 1234, Miraflores, Lima',
      'imagen': 'assets/local1.png',
    },
    {
      'nombre': 'Local 2 - San Borja',
      'direccion': 'Av. Javier Prado 5678, San Borja, Lima',
      'imagen': 'assets/local2.png',
    },
    {
      'nombre': 'Local 3 - San Isidro',
      'direccion': 'Av. Camino Real 4321, San Isidro, Lima',
      'imagen': 'assets/local3.png',
    },
  ];

  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark; // Verifica si está en modo oscuro

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              scrollDirection: Axis.horizontal,
              itemCount: locales.length,
              itemBuilder: (context, index) {
                final local = locales[index];
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.height * 0.7,
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.black : Colors.white, // Fondo negro en modo oscuro, blanco en modo claro
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Image.asset(
                                    local['imagen']!,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      local['nombre']!,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : Colors.black, // Texto blanco en modo oscuro, negro en claro
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      local['direccion']!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDarkMode ? Colors.white70 : Colors.black87, // Texto más claro en modo oscuro
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Indicador interactivo de páginas
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(locales.length, (index) {
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.0),
                    width: _currentPage == index ? 16.0 : 12.0,
                    height: _currentPage == index ? 16.0 : 12.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index ? Colors.blue : Colors.grey,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
