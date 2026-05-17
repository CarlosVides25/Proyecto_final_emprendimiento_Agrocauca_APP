import 'package:flutter/material.dart';
import 'package:agrocauca/componentes/barra_estado_sincronizacion.dart';
import 'package:agrocauca/componentes/estado_sincronizacion.dart';
import 'package:agrocauca/base_datos/base_de_datos.dart';
import 'package:agrocauca/inicio_sesion.dart';
import 'package:agrocauca/registro_finca.dart';
import 'package:agrocauca/registro_ganado.dart';
import 'package:agrocauca/estadistica.dart';
import 'package:agrocauca/analisis_financiero.dart';
import 'package:agrocauca/manejo_sesion.dart';
import 'package:agrocauca/componentes/funciones.dart';
import 'package:http/http.dart' as http;
import 'package:agrocauca/base_datos/base_de_datos.dart';
import 'dart:convert';
import 'package:agrocauca/componentes/funciones.dart';

import 'package:flutter/services.dart';


class Menu extends StatefulWidget {
  final String nombre;
  final String correo;
  final int usuario;
  final int idEmpresa;
  final String nombreEmpresa;

  const Menu({
    super.key,
    required this.nombre,
    required this.correo,
    required this.usuario,
    required this.idEmpresa,
    required this.nombreEmpresa,
  });

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {

  int _index = 0;
  bool sincronizando = false; // Para mostrar un indicador de carga durante la sincronización
  late List<Widget> _paginas;
  bool _hayCambiosParaSincronizar = false; // El bool que activa el botón
  final _sincronizacionManejo= EstadoSincronizacion();


  @override
  void initState() {
    super.initState();

    _paginas = [
      Registro_finca(usuario: widget.usuario, idEmpresa: widget.idEmpresa),
      RegistroGanado(usuario: widget.usuario, idEmpresa: widget.idEmpresa),
      Estadisticas(usuario: widget.usuario, idEmpresa: widget.idEmpresa),
      Finanzas(usuario: widget.usuario, idEmpresa: widget.idEmpresa),
    ];
  }
  void _btnCerrarSesion() async {
    Funciones.mostrarMensaje(
      context,
      "¿Cerrar sesión?",
      "¿Estás seguro de que deseas cerrar sesión?",
      onAceptar: _cerrarSesion,
    );
  }

  Future<void> _chequearBaseDatos() async {
    final cambios = await BaseDeDatos.obtenerCambiosLocales();
  
    final fincas = cambios["fincas"] as List;
    final animales = cambios["animales"] as List;

    setState(() {
      _hayCambiosParaSincronizar =
          fincas.isNotEmpty || animales.isNotEmpty;
    });
  }

  Future<void> _cerrarSesion() async {

    await SessionManager.cerrarSesion();

    Funciones.mostrarMensaje(context, "Sesión cerrada", "Has cerrado sesión exitosamente.", onAceptar: () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Inicio_sesion()),
        (route) => false,
      );
    });
  }

  Future<void> sincronizar() async {
    print("Iniciando sincronización...");
    final cambios = await BaseDeDatos.obtenerCambiosLocales();
    cambios["id_empresa"] = widget.idEmpresa; // Agrega el ID de empresa al objeto de cambios
    print( cambios);
    print("sigue...");
    final response = await http.post(
      Uri.parse("http://18.222.251.74//AgroCauca/sincronizacion/sincronizacion.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(cambios),
    );
    print(response.body);
    final data = jsonDecode(response.body);

    if (data["success"]) {
      await BaseDeDatos.cargarDatosServidor(data);
      await BaseDeDatos.depurarMostrarTodo();
      await BaseDeDatos.marcarComoSincronizado();

      await BaseDeDatos.guardarUltimaSincronizacion(data["server_time"]);
      EstadoSincronizacion().estado.value = SincronizacionEstado.sincronizado; // Cambia a estado sincronizado
      Funciones.mostrarMensaje(context, "Sincronización exitosa", "Los datos se han sincronizado correctamente.");
      _chequearBaseDatos(); // Revisa de nuevo para desactivar el botón

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      /// 🔹 APPBAR MODERNA
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 159, 218, 161),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${widget.nombre} - ${widget.nombreEmpresa}" , style: TextStyle(fontSize: 16)),
                  Text(widget.correo, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            ValueListenableBuilder<SincronizacionEstado>(
                valueListenable: _sincronizacionManejo.estado,
                builder: (context, status, child) {
                  
                  // 1. Si hay señal, revisamos cambios automáticamente
                  if (status == SincronizacionEstado.conectado) {
                    _chequearBaseDatos(); 
                  }

                  // 2. El botón solo se activa si hay internet Y el bool de cambios es true
                  bool sePuedePresionar = (status == SincronizacionEstado.conectado) && _hayCambiosParaSincronizar;

                  return IconButton(
                    icon: Icon( Icons.sync_rounded ,
                      color: sePuedePresionar ? Colors.green : Colors.grey,
                      size: 30,
                    ),
                    onPressed: sePuedePresionar 
                      ? () async {
                          _sincronizacionManejo.setPendiente(); // Cambia a estado carga
                          await sincronizar(); // Ejecuta la función
                          await _chequearBaseDatos(); // Revisa de nuevo para desactivar el botón

                          _sincronizacionManejo.verificarConexion(); // Revisa conexión para actualizar estado global (en caso de que se haya perdido durante la sincronización)
                        } 
                      : null, // Si es null, el botón se ve desactivado
                  );
                },
              ),

            ],
          ),   
        actions: [
          /// ESTADO GLOBAL
          /// 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: BarraEstadoSincronizacion(),
          ),
          
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _btnCerrarSesion,
          )
        ],
      ),

      /// CONTENIDO
      body: sincronizando ? const Center(child: CircularProgressIndicator()) :  _paginas[_index],

      /// NAVEGACIÓN MÓVIL
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          setState(() {
            _index = i;
          });
        },
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work),
            label: "Fincas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            label: "Animales",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Estadísticas",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: "Finanzas",
          ),
        ],
      ),
    );
  }
}