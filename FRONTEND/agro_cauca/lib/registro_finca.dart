import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:agrocauca/componentes/Funciones.dart';
import 'package:agrocauca/componentes/estado_sincronizacion.dart';
import 'package:agrocauca/componentes/texto.dart';
import 'package:agrocauca/base_datos/base_de_datos.dart';
class Registro_finca extends StatefulWidget {
  final int usuario;
  final int idEmpresa;  
  const Registro_finca({
    Key? key,
    required this.usuario,
    required this.idEmpresa,
  }) : super(key: key);
  @override
  _Registro_fincaState createState() => _Registro_fincaState();
}

class _Registro_fincaState extends State<Registro_finca> {

  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _area = TextEditingController();
  final TextEditingController _ubicacion = TextEditingController();

  bool cargando = true;
  List<dynamic> fincas = [];

  @override
  void initState() {
    super.initState();
    if(EstadoSincronizacion().estado.value==SincronizacionEstado.sinConexion){
      obtenerFincasOffline();
    }
    else{
      obtenerFincasOnline();
    }
  
  }

  Future<void> obtenerFincasOffline() async {
    print("📱 Cargando fincas OFFLINE");

    try {
      final data = await BaseDeDatos.obtenerFincas(widget.idEmpresa);

      setState(() {
        fincas = data;
        cargando = false;
      });

    } catch (e) {
      print("❌ Error obteniendo fincas offline: $e");

      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> actualizarFincaOnline(int id_finca) async {
    final url = Uri.parse("http://10.172.172.189/AgroCauca/BACKEND/finca/guardar_finca.php");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_finca": id_finca,
        "nombre": _nombre.text,
        "ubicacion": _ubicacion.text,
        "area": double.tryParse(_area.text) ?? 0,
      }),
    );

    final data = jsonDecode(response.body);

    if (data["success"]) {
      Funciones.mostrarMensaje(
        context,
        "Finca actualizada",
        data["message"],
        onAceptar: () {
          Navigator.pop(context); // cerrar formulario
          obtenerFincasOnline(); // recargar lista
        },
      );
    } else {
      Funciones.mostrarMensaje(context, "Error", data["message"], exito: false);
    }
  }

  Future<void> actualizarFincaOffline(int id_finca) async {
    print("actualizando finca offline");
    try {
      await BaseDeDatos.actualizarFinca({
        "id_finca": id_finca, // El ID de la finca que se está editando
        "nombre": _nombre.text,
        "ubicacion": _ubicacion.text,
        "area": double.tryParse(_area.text) ?? 0.0,
        "id_empresa": widget.idEmpresa, // Mantenemos la empresa a la que pertenece la finca
      });

      Funciones.mostrarMensaje(
        context,
        "Finca actualizada",
        "La finca ha sido actualizada exitosamente.",
        onAceptar: () {
          Navigator.pop(context); // cerrar formulario
          obtenerFincasOffline(); // recargar lista
        },
      );
    } catch (e) {
      Funciones.mostrarMensaje(context, "Error", "Error al actualizar finca offline: $e", exito: false);

    }
  }



  Future<void> obtenerFincasOnline() async {

    final url = Uri.parse("http://10.172.172.189/AgroCauca/BACKEND/finca/listar_fincas.php");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_empresa": widget.idEmpresa,
      }),
    );

    final data = jsonDecode(response.body);
    
    setState(() {
      fincas = data;
      cargando = false;
    });
  }
  
  void _btneliminarfinca(int id_finca){
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Confirmar"),
        content: Text("¿Deseas eliminar esta finca?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              btnAceptareliminado(id_finca);
            },
            child: Text("Eliminar"),
          ),
        ],
      ),
    );

  }
  void btnAceptareliminado(int id_finca){
    if(EstadoSincronizacion().estado.value==SincronizacionEstado.sinConexion){
      eliminarFincaOffline(id_finca);
    }
    else{
      eliminarFincaOnline(id_finca);
    }
  }

  Future<void> eliminarFincaOffline(int id_finca) async {
    try {
      await BaseDeDatos.eliminarFincaLogico(id_finca);

      Funciones.mostrarMensaje(
        context,
        "Finca eliminada",
        "La finca ha sido eliminada exitosamente.",
        onAceptar: () {
          obtenerFincasOffline(); // recargar lista
        },
      );
    } catch (e) {
      Funciones.mostrarMensaje(context, "Error", "Error al eliminar finca offline: $e", exito: false);
    }
  }

  Future<void> eliminarFincaOnline(int id_finca) async {
    final url = Uri.parse("http://10.172.172.189/AgroCauca/BACKEND/finca/eliminar_finca.php");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_finca": id_finca,
      }),
    );
    final data = jsonDecode(response.body);
    if (data["success"]) {
      Funciones.mostrarMensaje(context, "Éxito", "Finca eliminada", onAceptar: obtenerFincasOnline);
     
    } else {
      Funciones.mostrarMensaje(context, "Error", data["message"]);
    }

  }


  Future<void> insertarFinca() async {
    final url = Uri.parse("http://10.172.172.189/AgroCauca/BACKEND/finca/guardar_finca.php");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "nombre": _nombre.text,
        "ubicacion": _ubicacion.text,
        "area": double.tryParse(_area.text) ?? 0,
        "id_empresa": widget.idEmpresa,

      }),
    );  

    final data = json.decode(response.body);

    if (data["success"]) {
      Funciones.mostrarMensaje(context, "Finca registrada", "La finca ha sido registrada exitosamente.", onAceptar: obtenerFincasOnline); 
      
    } else {
      Funciones.mostrarMensaje(context, "Error", "${data["error"]}"); 
    }
  }

  Future<void> insertarFincaOflline() async {

    try {
      await BaseDeDatos.ingresarFinca({
        "nombre": _nombre.text,
        "ubicacion": _ubicacion.text,
        "area": double.tryParse(_area.text) ?? 0.0,
        "id_empresa": widget.idEmpresa, // El ID de la empresa a la que pertenece
      });

      Funciones.mostrarMensaje(context, "Finca registrada", "La finca ha sido registrada exitosamente.", onAceptar: obtenerFincasOffline);
    } catch (e) {
      Funciones.mostrarMensaje(context, "Error", "Error al guardar la finca localmente: $e"); 
    }

  }


  void btn_nuevafinca(){    
    limpiarCampos(); 
    _registrofinca(context);
  }

  void limpiarCampos() {
    _nombre.text = "";
    _area.text = "";
    _ubicacion.text = "";

  }

  void btn_actualizarfinca(int id_finca){

    if(EstadoSincronizacion().estado.value==SincronizacionEstado.sinConexion){

      actualizarFincaOffline(id_finca);
    }
    else{
      actualizarFincaOnline(id_finca);

    }
  }

  void _modificafinca(Map finca) {
    limpiarCampos();
    _nombre.text = finca["nombre"];
    _ubicacion.text = finca["ubicacion"];
    _area.text = finca["area"].toString();
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: 500,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 126, 179, 128), // tu verde
              borderRadius: BorderRadius.circular(15),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    "Actualizacion de Finca",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Nombre de la finca",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Texto.campoTexto(_nombre, "Ej: La Esperanza"),
                      SizedBox(height: 10),
                      Text(
                        "Ubicacion",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Texto.campoTexto(_ubicacion, "Ej: Caucasia"),
                      SizedBox(height: 10),
                      Text(
                        "Area (ha)",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Texto.campoTexto(_area, "Area", keyboardType: TextInputType.number, soloDecimales: true),
                    ],
                  ),
                  SizedBox(height: 20),
                  // 🔹 BOTONES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("Cancelar", style: TextStyle(color: Colors.black)),
                      ),

                      ElevatedButton(
                        onPressed: () {
                          btn_actualizarfinca(int.parse(finca["id_finca"].toString()));
                        },
                        child: Text("Actualizar Finca", style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void btningresarfinca(){
    
    if(EstadoSincronizacion().estado.value==SincronizacionEstado.sinConexion){
      insertarFincaOflline();
    }
    else{
      insertarFinca();
    }
  }

  void _registrofinca(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: 500,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 126, 179, 128), // tu verde
              borderRadius: BorderRadius.circular(15),
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    "Registrar Finca",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Nombre de la finca",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Texto.campoTexto(_nombre, "Ej: La Esperanza"),
                      SizedBox(height: 10),
                      Text(
                        "Ubicacion",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Texto.campoTexto(_ubicacion, "Ej: Caucasia"),
                      SizedBox(height: 10),
                      Text(
                        "Area (ha)",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                     Texto.campoTexto(_area, "Area", keyboardType: TextInputType.number, soloDecimales: true),
                    ],
                  ),
                  SizedBox(height: 20),
                  // 🔹 BOTONES
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("Cancelar", style: TextStyle(color: Colors.black)),
                      ),

                      ElevatedButton(
                        onPressed: () {
                          btningresarfinca();
                          Navigator.pop(context);
                        },
                        child: Text("Guardar Finca", style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override

  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera estática
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Gestión de Fincas",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: btn_nuevafinca,
                icon: const Icon(Icons.add),
                label: const Text("Nueva Finca"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              )
            ],
          ),

          const SizedBox(height: 20),

          // Área con Scroll
          Expanded( // 🔥 Esto permite que la lista ocupe el espacio sobrante y haga scroll
            child: cargando
                ? const Center(child: CircularProgressIndicator())
                : _gridFincas(),
          ),
        ],
      ),
    );
  }

  Widget _gridFincas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columnas = 4;

        if (constraints.maxWidth < 1200) columnas = 3;
        if (constraints.maxWidth < 800) columnas = 2;
        if (constraints.maxWidth < 500) columnas = 1;

        return GridView.builder(
          // 🔥 Quitamos shrinkWrap y NeverScrollableScrollPhysics para habilitar el scroll
          itemCount: fincas.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 1.3, // Ajusta según el contenido de tu card
          ),
          itemBuilder: (context, index) {
            return _cardFinca(fincas[index]);
          },
        );
      },
    );
  }
  
  Widget _cardFinca(dynamic finca) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on, color: Colors.green),
              SizedBox(width: 5),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      finca["nombre"],
                      style: TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      finca["ubicacion"],
                      style: TextStyle(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, size: 18),
                    onPressed: () => _modificafinca(finca),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red, size: 18),
                    onPressed: () => _btneliminarfinca(
                      int.parse(finca["id_finca"].toString()),
                    ),
                  ),
                ],
              )
            ],
          ),
          Divider(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _filaDato("Área", "${finca["area"]} ha"),
                _filaDato("Animales", finca["total_animales"].toString()),
                _filaDato(
                  "Fecha de Creacion",
                  finca["fecha_creacion"].toString().substring(0, 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _filaDato(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: TextStyle(color: Colors.grey[700])),
          Text(
            valor,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}