import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

class SubscriptionPage extends StatefulWidget {
  final bool isDarkMode;

  const SubscriptionPage({Key? key, required this.isDarkMode}) : super(key: key);

  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final String _subscriptionId = 'your_subscription_product_id'; // Cambia esto por el ID de tu suscripción
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  List<PurchaseDetails> _purchases = [];
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _initializeStore();
    _listenToPurchaseUpdates();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _initializeStore() async {
    final bool available = await _inAppPurchase.isAvailable();
    setState(() {
      _isAvailable = available;
    });

    if (available) {
      await _loadProducts();
    }
  }

  Future<void> _loadProducts() async {
    const Set<String> _kIds = <String>{'your_subscription_product_id'}; // Coloca aquí tu Product ID
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(_kIds);
    if (response.notFoundIDs.isNotEmpty) {
      print('Error: Productos no encontrados - ${response.notFoundIDs}');
    }

    setState(() {
      _products = response.productDetails;
    });
  }

  void _listenToPurchaseUpdates() {
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _processPurchaseUpdates(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      print('Error en la compra: $error');
    });
  }

  void _processPurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (PurchaseDetails purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        // Muestra un mensaje de "Compra en proceso"
      } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
        bool valid = _verifyPurchase(purchase);
        if (valid) {
          _deliverProduct(purchase);
          if (purchase.pendingCompletePurchase) {
            _inAppPurchase.completePurchase(purchase);
          }
        } else {
          _handleInvalidPurchase(purchase);
        }
      } else if (purchase.status == PurchaseStatus.error) {
        print('Error en la compra: ${purchase.error}');
      }
    }
  }

  bool _verifyPurchase(PurchaseDetails purchase) {
    // Lógica de verificación personalizada
    return true;
  }

  void _deliverProduct(PurchaseDetails purchase) {
    setState(() {
      _purchases.add(purchase);
    });
  }

  void _handleInvalidPurchase(PurchaseDetails purchase) {
    // Muestra un mensaje si la compra no es válida
  }

  void _buyProduct(ProductDetails productDetails) {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam); // Compra no consumible para suscripciones
  }

  void _restorePurchases() {
    _inAppPurchase.restorePurchases();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suscripciones Disponibles'),
        backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.amber,
      ),
      body: _isAvailable
          ? Column(
              children: [
                const SizedBox(height: 20),
                if (_products.isNotEmpty)
                  ..._products.map(
                    (ProductDetails product) => ListTile(
                      title: Text(product.title),
                      subtitle: Text(product.description),
                      trailing: ElevatedButton(
                        onPressed: () => _buyProduct(product),
                        child: const Text('Suscribirse'),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _restorePurchases,
                  child: const Text('Restaurar Compras'),
                ),
              ],
            )
          : Center(
              child: const Text('Tienda no disponible o sin conexión'),
            ),
    );
  }
}
