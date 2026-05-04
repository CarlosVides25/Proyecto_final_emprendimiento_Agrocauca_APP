import 'package:flutter/material.dart';
import 'package:trabajo_final/componentes/estado_sincronizacion.dart';
import 'package:trabajo_final/inicio_sesion.dart';
import 'package:trabajo_final/manejo_sesion.dart';
import 'package:trabajo_final/menu.dart';
import 'package:trabajo_final/base_datos/base_de_datos.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgroCauca Software',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Usamos una pantalla de carga inicial para decidir a dónde ir
      home: const SplashChecker(), 
      routes: {
        '/inicio_sesion': (context) => const Inicio_sesion(),
      },
    );
  }
}


// Este widget se encarga de verificar la sesión apenas abre la app
class SplashChecker extends StatefulWidget {
  const SplashChecker({super.key});

  @override
  State<SplashChecker> createState() => _SplashCheckerState();
}

class _SplashCheckerState extends State<SplashChecker> {

  @override
  void initState() {
     super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await EstadoSincronizacion().init(); // 🔥 ahora sí
      verificarYEntrar();
    });
  }

  // Ejemplo dentro de la función de login exitoso:
  Future<void> sincronizacionInicial(int usuarioId) async {
    try {
      // 1. Consultar al servidor (Usa tu IP real, no localhost)
      final response = await http.get(
        Uri.parse("http://10.211.222.189/AgroCauca/BACKEND/obtener_todo.php?id_usuario=$usuarioId")
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // 2. Llenar la base de datos offline
        await BaseDeDatos.cargarDatosServidor(data);
        print("Base de datos offline cargada correctamente");
      }
    } catch (e) {
      print("Modo offline: No se pudo descargar datos, usando local.");
    }
  }

  void verificarYEntrar() async {
    bool valida = await SessionManager.esSesionValida();

    if (!mounted) return;

    if (valida) {
      int? id = await SessionManager.getUsuarioId();
      String? correo = await SessionManager.getUsuarioCorreo();
      String? nombre = await SessionManager.getUsuarioNombre();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Menu(
            usuario: id!,
            correo: correo!,
            nombre: nombre!,
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Inicio_sesion()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );
  }
}