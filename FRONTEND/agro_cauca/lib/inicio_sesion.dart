
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trabajo_final/menu.dart';
import 'package:trabajo_final/manejo_sesion.dart';
import 'package:trabajo_final/base_datos/base_de_datos.dart';
import 'package:trabajo_final/componentes/barra_estado_sincronizacion.dart';
import 'package:trabajo_final/componentes/estado_sincronizacion.dart';

class Inicio_sesion extends StatefulWidget {

  const Inicio_sesion({super.key});

  @override
  State<Inicio_sesion> createState() => _inicio_sesionState();

}//Fin inicio_sesion{...}


class _inicio_sesionState extends State<Inicio_sesion>  {

  
  final TextEditingController _txt_usuario = TextEditingController();
  final TextEditingController _txt_clave =  TextEditingController();


  _inicio_sesionState();

  @override 
  void initState(){
    super.initState();
    

  }



  Future<void> _iniciarSesionClick() async {

    if (_txt_usuario.text.trim().isEmpty || _txt_clave.text.trim().isEmpty) {
      mostrarMensaje(context, "Datos incompletos", "Ingrese correo y clave", exito: false);
      return;
    }


    if (EstadoSincronizacion().estado.value == SyncStatus.sinConexion) {
      print("sin conexion");
      await _inicioSesionLocal();
    } else {
      print("CON conexion");
      await _inicioSesionOnline();
    }
  }
    
  Future<void> _inicioSesionLocal() async {

    print("inicio offline");
    final  usuario = await BaseDeDatos.inicioSesionUsuario(
      _txt_usuario.text,
      _txt_clave.text
    );
    print(usuario);
    print("sigue offline");
    if (usuario != null) {

      print("vamos al menu");
      _navegarInicio(
        usuario['nombre'],
        usuario['correo'],
        usuario['id'],);
    } else {
      mostrarMensaje(context, "Error", "Usuario no encontrado en modo offline", exito: false);
    }
  }

 
  Future<void> _inicioSesionOnline() async {
    final url = Uri.parse("http://10.211.222.189/AgroCauca/BACKEND/inicio_sesion.php");
    
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "correo": _txt_usuario.text,
        "clave": _txt_clave.text
      }),
    );

    print("intentando iniciar sesión online...");
    final data = jsonDecode(response.body);

    if (data["success"]) {

      //_cargarDatosOffline( data["usuario"]); // Carga datos offline al iniciar sesión 
      _navegarInicio(data["nombre"], data["correo"], data["usuario"]);
    } else {
      mostrarMensaje(context, "Error", data["message"], exito: false);
    }
  }
  Future <void> _cargarDatosOffline( int usuario) async {
    print("cargando datos offline para usuario $usuario");
    final url = (Uri.parse("http://10.211.222.189/AgroCauca/BACKEND/obtener_todo.php"));
  
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_usuario": usuario,
      }),
    );

    final data = jsonDecode(response.body);

    if (data["success"]) {
      
      BaseDeDatos.cargarDatosServidor(data); // SINCRONIZAR DATOS

      BaseDeDatos.depurarMostrarTodo();

    }
  }

  void _navegarInicio(String nombre,String correo, int usuario) async {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) =>  Menu( 
          nombre: nombre,
          correo: correo,
          usuario: usuario,
        ),
      ),
    );

    _txt_usuario.text = "";
    _txt_clave.text = "";

  }//Fin _navegarInicio(){...}

  void mostrarMensaje(
    BuildContext context,
    String titulo,
    String mensaje, {
    bool exito = true,
    VoidCallback? onAceptar, 
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // opcional (evita cerrar tocando fuera)
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            titulo,
            style: TextStyle(
              color: exito ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // cerrar dialog

                if (onAceptar != null) {
                  onAceptar(); // ejecutar función
                }
              },
              child: Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }
  
  

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: SafeArea( // 🔥 PROTEGE TODA LA UI
        child: Column(
          children: [
            BarraEstadoSincronizacion(),

            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("assets/images/vacas.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),

                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Text(
                                  "Agrocauca Software",
                                  style: TextStyle(
                                    color:  Color.fromARGB(255, 34, 19, 45),
                                    fontSize: 35,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 34, 19, 45),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 10),
                                            
                                          const Text(
                                            "Inicio de Sesión",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                            
                                          const SizedBox(height: 5),
                                            
                                          const Text(
                                            "Ingresa tus credenciales para acceder",
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                            
                                          const SizedBox(height: 20),
                                            
                                          const Text(
                                            "Correo",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                            
                                          const SizedBox(height: 5),
                                            
                                          TextField(
                                            controller: _txt_usuario,
                                            keyboardType: TextInputType.emailAddress,
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: Colors.white,
                                              hintText: "Digite correo...",
                                              contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 15, vertical: 12),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                            
                                          const SizedBox(height: 15),
                                            
                                          const Text(
                                            "Contraseña",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                            
                                          const SizedBox(height: 5),
                                            
                                          TextField(
                                            controller: _txt_clave,
                                            obscureText: true,
                                            textInputAction: TextInputAction.done,
                                            onSubmitted: (_) {
                                              if (_txt_usuario.text.isNotEmpty &&
                                                  _txt_clave.text.isNotEmpty) {
                                                _iniciarSesionClick();
                                              }
                                            },
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: Colors.white,
                                              hintText: "Digite contraseña...",
                                              contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 15, vertical: 12),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                            
                                          const SizedBox(height: 25),
                                            
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: _iniciarSesionClick,
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 15),
                                                backgroundColor: Colors.greenAccent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: const Text(
                                                "Iniciar Sesión",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                            
                                          const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}