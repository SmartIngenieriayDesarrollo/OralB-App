import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'dart:developer' as developer;

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});
  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget>
    with SingleTickerProviderStateMixin {
  late WebViewController _webViewController;
  // Prueba ambos protocolos para ver cuál funciona mejor
  final String _baseUrl = 'https://oralb2.smartapp.com.co';
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  bool _isConnected = true;
  bool _initialLoadComplete = false;
  int _loadAttempts = 0;
  Timer? _loadTimeoutTimer;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Set fullscreen mode
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    // Initialize animation controller for loading animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    developer.log('Iniciando aplicación', name: 'OralB App');

    // Check connectivity and initialize
    _checkConnectivity().then((_) {
      if (_isConnected) {
        _initializeWebView();
      }
    });

    // Monitor connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      final hasConnection = result != ConnectivityResult.none;
      if (hasConnection != _isConnected) {
        setState(() {
          _isConnected = hasConnection;
        });

        developer.log('Estado de conexión cambiado: $_isConnected',
            name: 'OralB App');

        if (hasConnection && _isError) {
          _initializeWebView();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loadTimeoutTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    super.dispose();
  }

  // Check initial connectivity
  Future<void> _checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    developer.log('Resultado de conectividad: $connectivityResult',
        name: 'OralB App');

    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
      if (!_isConnected) {
        _isError = true;
        _errorMessage = 'Sin conexión a Internet';
        developer.log('Sin conexión a Internet', name: 'OralB App');
      }
    });
  }

  // Probar directamente con HTTP
  void _testHTTPConnection() async {
    try {
      developer.log('Probando conexión HTTP directa a $_baseUrl',
          name: 'OralB App');

      // Este código solo se ejecuta en debug mode
      // En producción, usar esta función solo como referencia
      // _initializeWebView(); // Continuar con la inicialización normal
    } catch (e) {
      developer.log('Error en prueba HTTP: $e', name: 'OralB App');
      setState(() {
        _isError = true;
        _errorMessage = 'Error de conexión: $e';
      });
    }
  }

  // Initialize WebView
  void _initializeWebView() {
    setState(() {
      _isLoading = true;
      _isError = false;
      _loadAttempts++;
    });

    developer.log('Inicializando WebView, intento: $_loadAttempts',
        name: 'OralB App');

    // Set a timeout for loading
    _loadTimeoutTimer?.cancel();
    _loadTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_isLoading) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'Tiempo de carga agotado. La página no respondió.';
        });
        developer.log('Timeout al cargar la página', name: 'OralB App');
      }
    });

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            developer.log('Página comenzando a cargar: $url',
                name: 'OralB App');
            setState(() {
              _isLoading = true;
              _isError = false;
            });
          },
          onPageFinished: (String url) async {
            developer.log('Página terminó de cargar: $url', name: 'OralB App');

            // Comprobar si la página tiene contenido
            _checkPageHasContent();

            // Finalmente, consideramos que la página ha cargado
            setState(() {
              _isLoading = false;
              _initialLoadComplete = true;
            });

            // Inject JavaScript to detect DOM loaded and notify
            _injectTouchEnhancements();
          },
          onWebResourceError: (WebResourceError error) {
            developer.log(
                'Error de recurso web: ${error.errorCode} - ${error.description}',
                name: 'OralB App');
            setState(() {
              _isLoading = false;
              _isError = true;
              _errorMessage =
                  'Error al cargar el contenido: ${error.description}';
            });
          },
        ),
      )
      ..enableZoom(false) // Disable pinch zoom for kiosk mode
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 11; TV) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.101 Safari/537.36')
      ..loadRequest(Uri.parse(_baseUrl));
  }

  // Comprobar si la página tiene contenido real
  Future<void> _checkPageHasContent() async {
    try {
      final hasBodyContent =
          await _webViewController.runJavaScriptReturningResult(
              "document.body && document.body.innerHTML.trim().length > 0;");

      developer.log('Verificación de contenido del body: $hasBodyContent',
          name: 'OralB App');

      if (hasBodyContent.toString() == 'false') {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = 'La página cargó pero no tiene contenido';
        });
      }
    } catch (e) {
      developer.log('Error al verificar contenido: $e', name: 'OralB App');
    }
  }

  // Inject JavaScript to improve touch interaction
  void _injectTouchEnhancements() {
    _webViewController.runJavaScript('''
      // Improve touch interactions for large display
      document.body.style.fontSize = '120%';
      
      // Make all buttons and clickable elements larger
      const clickables = document.querySelectorAll('button, a, input[type="button"], input[type="submit"]');
      clickables.forEach(element => {
        element.style.minHeight = '44px';
        element.style.minWidth = '44px';
        element.style.padding = '12px';
        element.style.margin = '8px';
      });
      
      // Improve form input focus
      const inputs = document.querySelectorAll('input, textarea, select');
      inputs.forEach(input => {
        input.style.fontSize = '120%';
        input.style.padding = '12px';
        
        // Add event listener to scroll to input when focused
        input.addEventListener('focus', function() {
          setTimeout(() => {
            this.scrollIntoView({
              behavior: 'smooth',
              block: 'center'
            });
          }, 300);
        });
      });
      
      // Log información para depuración
      console.log('Mejoras táctiles aplicadas');
    ''');
  }

  // Reload WebView
  void _reloadWebView() {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    developer.log('Recargando WebView', name: 'OralB App');

    _checkConnectivity().then((_) {
      if (_isConnected) {
        _webViewController.reload();
      }
    });
  }

  // Show toast messages
  void _showToast(String message, ToastType type) {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (type) {
      case ToastType.SUCCESS:
        backgroundColor = Colors.green;
        break;
      case ToastType.ERROR:
        backgroundColor = Colors.red;
        break;
      case ToastType.WARNING:
        backgroundColor = Colors.orange;
        break;
      default:
        backgroundColor = Colors.blue;
    }

    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: 16.0);

    developer.log('Toast mostrado: $message', name: 'OralB App');
  }

  // Error screen widget with retry option
  Widget _buildErrorWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Image.asset(
            'assets/images/oralb_logo.png',
            width: 300,
            height: 300,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              developer.log('Error al cargar logo: $error', name: 'OralB App');
              // Fallback si no existe la imagen
              return Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(150),
                ),
                child: Icon(
                  Icons.brush,
                  size: 150,
                  color: Colors.blue.shade800,
                ),
              );
            },
          ),
          const SizedBox(height: 30),

          // Error message
          Text(
            _errorMessage,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50),

          // Retry button
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, size: 30),
            label: const Text(
              'Intentar nuevamente',
              style: TextStyle(fontSize: 20),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _reloadWebView,
          ),

          const SizedBox(height: 20),

          // Try alternative URL button
          ElevatedButton.icon(
            icon: const Icon(Icons.swap_horiz, size: 24),
            label: const Text(
              'Probar URL alternativa',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // Alternar entre HTTP y HTTPS
              final newUrl = _baseUrl.startsWith('https:')
                  ? _baseUrl.replaceFirst('https:', 'http:')
                  : _baseUrl.replaceFirst('http:', 'https:');

              developer.log('Cambiando a URL alternativa: $newUrl',
                  name: 'OralB App');

              // Cargar la nueva URL
              _webViewController.loadRequest(Uri.parse(newUrl));

              // Reiniciar el estado
              setState(() {
                _isLoading = true;
                _isError = false;
              });
            },
          ),
        ],
      ),
    );
  }

  // Loading widget
  Widget _buildLoadingWidget() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Image.asset(
            'assets/images/oralb_logo.png',
            width: 300,
            height: 300,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              developer.log('Error al cargar logo: $error', name: 'OralB App');
              // Fallback si no existe la imagen
              return Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(150),
                ),
                child: Icon(
                  Icons.brush,
                  size: 150,
                  color: Colors.blue.shade800,
                ),
              );
            },
          ),
          const SizedBox(height: 40),

          // Loading animation
          SpinKitWave(
            color: Colors.blue,
            size: 50.0,
            controller: _animationController,
          ),
          const SizedBox(height: 30),

          Text(
            'Cargando...',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800]),
          ),

          const SizedBox(height: 50),

          // Manual reload button
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, size: 24),
            label: const Text(
              'Cargar manualmente',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _reloadWebView,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar to create fullscreen experience
      body: WillPopScope(
        onWillPop: () async =>
            false, // Prevenir que el botón Atrás cierre la app
        child: Stack(
          children: [
            // WebView (only visible when not loading or in error state)
            if (!_isError && _initialLoadComplete)
              SafeArea(
                child: Stack(
                  children: [
                    WebViewWidget(controller: _webViewController),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.blue.withOpacity(0.7),
                        child: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _reloadWebView,
                      ),
                    ),
                  ],
                ),
              ),

            // Error screen
            if (_isError) _buildErrorWidget(),

            // Loading screen
            if (_isLoading && !_isError) _buildLoadingWidget(),
          ],
        ),
      ),
    );
  }
}

// Enum for toast types
enum ToastType { SUCCESS, ERROR, WARNING, INFO }
