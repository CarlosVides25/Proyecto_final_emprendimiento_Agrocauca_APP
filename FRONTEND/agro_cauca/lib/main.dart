import 'package:flutter/material.dart';
import 'package:agrocauca/componentes/estado_sincronizacion.dart';
import 'package:agrocauca/inicio_sesion.dart';
import 'package:agrocauca/manejo_sesion.dart';
import 'package:agrocauca/menu.dart';
import 'package:agrocauca/base_datos/base_de_datos.dart';
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

  void verificarYEntrar() async {
    bool valida = await SessionManager.esSesionValida();

    if (!mounted) return;

    if (valida) {
      int? id = await SessionManager.getUsuarioId();
      String? correo = await SessionManager.getUsuarioCorreo();
      String? nombre = await SessionManager.getUsuarioNombre();
      String? nombreEmpresa = await SessionManager.getNombreEmpresa();
      int? idEmpresa = await SessionManager.getEmpresa();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Menu(
            usuario: id!,
            correo: correo!,
            nombre: nombre!,
            idEmpresa: idEmpresa!,
            nombreEmpresa: nombreEmpresa!,
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