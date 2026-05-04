import 'package:flutter/material.dart';
import 'package:trabajo_final/componentes/barra_estado_sincronizacion.dart';
import 'package:trabajo_final/inicio_sesion.dart';
import 'package:trabajo_final/registro_finca.dart';
import 'package:trabajo_final/registro_ganado.dart';
import 'package:trabajo_final/consulta.dart';
import 'package:trabajo_final/analisis_financiero.dart';
import 'package:trabajo_final/manejo_sesion.dart';
import 'package:trabajo_final/componentes/funciones.dart';

class Menu extends StatefulWidget {
  final String nombre;
  final String correo;
  final int usuario;

  const Menu({
    super.key,
    required this.nombre,
    required this.correo,
    required this.usuario,
  });

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {

  int _index = 0;

  late List<Widget> _paginas;

  @override
  void initState() {
    super.initState();

    _paginas = [
      Registro_finca(usuario: widget.usuario),
      RegistroGanado(usuario: widget.usuario),
      ReporteGeneral(usuario: widget.usuario),
      AnalisisFinanciero(usuario: widget.usuario),
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

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      /// 🔹 APPBAR MODERNA
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromARGB(255, 159, 218, 161),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.nombre, style: TextStyle(fontSize: 16)),
            Text(widget.correo, style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          /// ESTADO GLOBAL
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
      body: _paginas[_index],

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
            icon: Icon(Icons.search),
            label: "Consulta",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: "Análisis",
          ),
        ],
      ),
    );
  }
}