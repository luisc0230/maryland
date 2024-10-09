import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentWebView extends StatefulWidget {
  PaymentWebView({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  PaymentWebViewState createState() => PaymentWebViewState();
}

class PaymentWebViewState extends State<PaymentWebView> {
  late final WebViewController _webViewController;

  @override
  void initState() {
    super.initState();

    // Inicializamos el controlador de la WebView
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Puedes agregar una barra de carga aquí si lo deseas
          },
          onPageStarted: (String url) {
            print('Comenzó a cargar la URL: $url');
          },
          onPageFinished: (String url) {
            print('Terminó de cargar la URL: $url');
          },
          onHttpError: (HttpResponseError error) {
            print('Error HTTP: $error');
          },
          onWebResourceError: (WebResourceError error) {
            print('Error en el recurso web: $error');
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            if (url.contains('success')) {
              Navigator.pushNamedAndRemoveUntil(context, '/success', (r) => false);
              return NavigationDecision.prevent;
            } else if (url.contains('error') || url.contains('cancel')) {
              Navigator.pushNamedAndRemoveUntil(context, '/fail', (r) => false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Se accede a los argumentos en el método build, cuando el widget está completamente construido
    final responseArgument = ModalRoute.of(context)!.settings.arguments as Map;
    final String redirectionUrl = responseArgument['response'];

    // Imprime la URL que se va a cargar en la WebView
    print("Cargando redirectionUrl: $redirectionUrl");

    // Cargar la URL redirigida en la WebView
    _webViewController.loadRequest(Uri.parse(redirectionUrl));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: WebViewWidget(controller: _webViewController),
    );
  }

  @override
  void dispose() {
    _clearCache();
    super.dispose();
  }

  Future<void> _clearCache() async {
    // Limpiar la cache del WebView
    await _webViewController.clearCache();
  }
}
