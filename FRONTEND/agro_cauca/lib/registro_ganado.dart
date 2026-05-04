import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:sqflite/sql.dart';
import 'package:trabajo_final/componentes/Funciones.dart';
import 'package:trabajo_final/componentes/texto.dart';
import 'package:trabajo_final/componentes/desplegable.dart';
import 'package:trabajo_final/componentes/estado_sincronizacion.dart';
import 'package:trabajo_final/base_datos/base_de_datos.dart';

class RegistroGanado extends StatefulWidget {
  final int usuario;
  const RegistroGanado({Key? key, required this.usuario}) : super(key: key);

  @override
  _RegistroGanadoState createState() => _RegistroGanadoState();
}

class _RegistroGanadoState extends State<RegistroGanado> {
  final TextEditingController _identificacion = TextEditingController();
  final TextEditingController _raza = TextEditingController();
  final TextEditingController _edad = TextEditingController();
  final TextEditingController _peso = TextEditingController();
  final TextEditingController _precioCompra = TextEditingController();
  final TextEditingController _precioKilo = TextEditingController();
  final TextEditingController _gastoMantenimiento = TextEditingController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  // Dropdowns
  String? _sexo_registrar;
  String? _proposito_registrar;
  String? _estado_reproductivo_registrar;
  String? _estado_registrar;
  String? _finca_registrar;
  String? _tipo_registrar;

  List animales = [];
  List fincas = [];
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    if(EstadoSincronizacion().estado.value==SyncStatus.sinConexion){
      obtenerAnimalesOffline();
      obtenerFincasOffline();
    }
    else{
      obtenerAnimalesOnline();
      obtenerFincasOnline();
    }
  
    
  }

  Future<void> obtenerFincasOffline() async {
    print("📱 Cargando fincas OFFLINE");

    try {
      final data = await BaseDeDatos.obtenerFincas(widget.usuario);

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

  Future<void> obtenerAnimalesOffline() async {
    print("📱 Cargando animales OFFLINE");

    try {
      final data = await BaseDeDatos.obtenerAnimales(widget.usuario);

      setState(() {
        animales = data;
        cargando = false;
      });

    } catch (e) {
      print("❌ Error obteniendo animales offline: $e");

      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> obtenerAnimalesOnline() async {
    final url = Uri.parse("http://10.211.222.189/AgroCauca/BACKEND/animal/listar_animales.php");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"usuario": widget.usuario}),
    );
    print(response.body);
    final data = jsonDecode(response.body);
    if (data["success"]) {
      setState(() {
        animales = data["data"];
        cargando = false;
      });
    }
  }

  Future<void> insertarAnimalOnline() async {
    final url = Uri.parse("http://10.211.222.189/AgroCauca/BACKEND/animal/guardar_animal.php");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "identificador": _identificacion.text,
        "tipo": _tipo_registrar,
        "raza": _raza.text,
        "edad": _edad.text,
        "peso": _peso.text,
        "sexo": _sexo_registrar,
        "proposito": _proposito_registrar,
        "estado_reproductivo": _estado_reproductivo_registrar,
        "precio_kilo": _precioKilo.text,
        "estado": _estado_registrar,
        "precio_compra": _precioCompra.text,
        "gasto_mantenimiento": _gastoMantenimiento.text,
        "id_finca": _finca_registrar,
      }),
    );
    print("ejecuto");
    print(response.body);
    final data = json.decode(response.body);
    if (data["success"]) {
      Funciones.mostrarMensaje(context, "Animal registrado", "El animal ha sido registrado exitosamente.",
        onAceptar: obtenerAnimalesOnline);
    } else {
      Funciones.mostrarMensaje(context, "Error", "${data["error"]}");
    }
  }

  void btningresaranimal(){
    
    if(EstadoSincronizacion().estado.value==SyncStatus.sinConexion){
      insertarAnimalOflline();
    }
    else{
      insertarAnimalOnline();
    }
  }


  Future<void> insertarAnimalOflline() async {

    try {
      await BaseDeDatos.ingresarAnimal({
        "identificador": _identificacion.text,
        "tipo": _tipo_registrar,
        "raza": _raza.text,
        "edad": int.tryParse(_edad.text) ?? 0,
        "peso": double.tryParse(_peso.text) ?? 0.0,
        "sexo": _sexo_registrar,
        "proposito": _proposito_registrar,
        "estado_reproductivo": _estado_reproductivo_registrar,
        "precio_kilo": double.tryParse(_precioKilo.text) ?? 0.0,
        "estado": _estado_registrar,
        "precio_compra": double.tryParse(_precioCompra.text) ?? 0.0,
        "gasto_mantenimiento": double.tryParse(_gastoMantenimiento.text) ?? 0.0,
        "id_finca": _finca_registrar, // Asegúrate que este sea el ID de la finca
        "fecha_compra": DateTime.now().toString().split(' ')[0], // Fecha actual YYYY-MM-DD
      });

      Funciones.mostrarMensaje(context, "Animal registrada", "El animal ha sido registrada exitosamente.", onAceptar: obtenerAnimalesOffline);
    } catch (e) {
      Funciones.mostrarMensaje(context, "Error", "Error al guardar el animal localmente: $e"); 
    }

  }

  Future<void> actualizarAnimal(int id_animal) async {
    final url = Uri.parse("http://10.211.222.189/AgroCauca/BACKEND/animal/guardar_animal.php");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id_animal": id_animal,
        "identificador": _identificacion.text,
        "tipo": _tipo_registrar,
        "raza": _raza.text,
        "edad": _edad.text,
        "peso": _peso.text,
        "sexo": _sexo_registrar,
        "proposito": _proposito_registrar,
        "estado_reproductivo": _estado_reproductivo_registrar,
        "precio_kilo": _precioKilo.text,
        "estado": _estado_registrar,
        "precio_compra": _precioCompra.text,
        "gasto_mantenimiento": _gastoMantenimiento.text,
        "id_finca": _finca_registrar,
      }),
    );

    final data = jsonDecode(response.body);
    if (data["success"]) {
      Funciones.mostrarMensaje(
        context,
        "Animal actualizado",
        data["message"],
        onAceptar: () {
            obtenerAnimalesOnline();
          limpiarCampos();
        },
      );
    } else {
      Funciones.mostrarMensaje(context, "Error", data["message"], exito: false);
    }
  }

  

  Future<void> eliminarAnimalOnline(int id_animal) async {
    final url = Uri.parse("http://10.211.222.189/AgroCauca/BACKEND/animal/eliminar_animal.php");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_animal": id_animal}),
    );

    final data = jsonDecode(response.body);
    if (data["success"]) {
      Funciones.mostrarMensaje(context, "Éxito", "Animal eliminado", onAceptar: obtenerAnimalesOnline);
    } else {
      Funciones.mostrarMensaje(context, "Error", data["message"]);
    }
  }

  Future<void> obtenerFincasOnline() async {
    final url = Uri.parse("http://10.211.222.189/AgroCauca/BACKEND/finca/listar_fincas.php");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"usuario": widget.usuario}),
    );

    final data = jsonDecode(response.body);
    setState(() {
      fincas = data;
      cargando = false;
    });
  }

  // --- WIDGETS DE UI Y AUXILIARES ---

  void limpiarCampos() {
    _identificacion.clear();
    _raza.clear();
    _edad.clear();
    _peso.clear();
    _precioKilo.clear();
    _precioCompra.clear();
    _gastoMantenimiento.clear();
    _tipo_registrar = null;
    _sexo_registrar = null;
    _estado_registrar = null;
    _finca_registrar = null;

    _estado_reproductivo_registrar = null;
    _proposito_registrar = null;
  }

  

  // --- Desplegables ---

  Widget _dropdownSexo() => _baseDropdown("Sexo", _sexo_registrar, ["Macho", "Hembra"], (v) => setState(() => _sexo_registrar = v));
  Widget _dropdownProposito() => _baseDropdown("Propósito", _proposito_registrar, ["Carne", "Leche", "Cria", "Doble Proposito"], (v) => setState(() => _proposito_registrar = v));
  Widget _dropdownEstado() => _baseDropdown("Estado", _estado_registrar, ["Activo", "Vendido", "Enfermo", "Fallecido"], (v) => setState(() => _estado_registrar = v));
  Widget _dropdownTipo() => _baseDropdown("Tipo", _tipo_registrar, ["Bovino", "Porcino", "Ovino", "Equino"], (v) => setState(() => _tipo_registrar = v));
  Widget _dropdownEstadoReproductivo() => _baseDropdown("Estado reproductivo", _estado_reproductivo_registrar, ["Prenada", "Vacia", "Apto", "No Aplica"], (v) => setState(() => _estado_reproductivo_registrar = v));

  Widget _baseDropdown(String hint, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: options.map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1)))).toList(),
      onChanged: onChanged,
      decoration: Texto.decoracion(hint),
    );
  }



  Widget _dropdownFinca() {
    return DropdownButtonFormField<String>(
      value: _finca_registrar,
      items: fincas.map<DropdownMenuItem<String>>((finca) {
        return DropdownMenuItem<String>(
          value: finca["id_finca"].toString(),
          child: Text(finca["nombre"]),
        );
      }).toList(),
      onChanged: (value) => setState(() => _finca_registrar = value),
      decoration: Texto.decoracion("Seleccionar finca"),
    );
  }


  void _btneliminarAnimal(int id_animal) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar"),
        content: const Text("¿Deseas eliminar este animal?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              btnAceptareliminado(id_animal);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }



  void btnAceptareliminado(int id_animal) {
    if(EstadoSincronizacion().estado.value==SyncStatus.sinConexion){

      eliminarAnimalOffline(id_animal);
    }
    else{
      eliminarAnimalOnline(id_animal);

    }

  }

   Future<void> eliminarAnimalOffline(int id_animal) async {
    try {
      await BaseDeDatos.eliminarAnimalLogico(id_animal);

      Funciones.mostrarMensaje(
        context,
        "Animal eliminado",
        "El animal ha sido eliminada exitosamente.",
        onAceptar: () {
          obtenerAnimalesOffline(); // recargar lista
        },
      );
    } catch (e) {
      Funciones.mostrarMensaje(context, "Error", "Error al eliminar animal offline: $e", exito: false);
    }
  }


  // Formulario compartido para Registro y Modificación
  Widget _formularioAnimal() {
    return Column(
      mainAxisSize: MainAxisSize.min, // 🔥 IMPORTANTE
      children: [
        Row(
          children: [
            Expanded(child: Texto.campoTexto(_identificacion, "Identificación")),
            const SizedBox(width: 10),
            Expanded(child: _dropdownFinca()),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(child: _dropdownTipo()),
            const SizedBox(width: 10),
            Expanded(child: Texto.campoTexto(_raza, "Raza")),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: Texto.campoTexto(_edad, "Edad", keyboardType: TextInputType.number, soloEnteros: true),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Texto.campoTexto(_peso, "Peso", keyboardType: TextInputType.number, soloDecimales: true)
            ),
            const SizedBox(width: 10),
            Expanded(child: _dropdownSexo()),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(child: _dropdownProposito()),
            const SizedBox(width: 10),
            Expanded(child: _dropdownEstadoReproductivo()),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(child: Texto.campoTexto(_gastoMantenimiento, "Gasto mantenimiento", soloEnteros: true, keyboardType: TextInputType.number )),
            const SizedBox(width: 10),
            Expanded(
              child: Texto.campoTexto( _precioKilo,keyboardType: TextInputType.number, soloDecimales: true, "Precio x Kilo"),
              
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(child: _dropdownEstado()),
            const SizedBox(width: 10),
            Expanded(
              child: Texto.campoTexto( _precioCompra,keyboardType: TextInputType.number, soloEnteros: true, "Precio compra"),
            ),
          ],
        ),
      ],
    );
  }

  void _modificarAnimal(BuildContext context, Map animal) {
    limpiarCampos();
    _identificacion.text = animal["identificador"].toString();
    _raza.text = animal["raza"].toString();
    _edad.text = animal["edad"].toString();
    _peso.text = animal["peso"].toString();
    _precioKilo.text = animal["precio_kilo"].toString() == "null" ? "" : animal["precio_kilo"].toString();
    _precioCompra.text = animal["precio_compra"].toString();
    _gastoMantenimiento.text = animal["gasto_mantenimiento"].toString();
    _tipo_registrar = animal["tipo"].toString() == "" ? null : animal["tipo"].toString();
    _estado_registrar = animal["estado"].toString() == "" ? null : animal["estado"].toString();
    _proposito_registrar = animal["proposito"].toString() == "" ? null : animal["proposito"].toString();
    _sexo_registrar = animal["sexo"].toString() == "" ? null : animal["sexo"].toString();
    _estado_reproductivo_registrar = animal["estado_reproductivo"].toString() == "" ? null : animal["estado_reproductivo"].toString();
    _finca_registrar = animal["id_finca"].toString() == "" ? null : animal["id_finca"].toString();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color.fromARGB(255, 126, 179, 128), borderRadius: BorderRadius.circular(15)),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text("Actualizar Animal", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _formularioAnimal(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar", style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A8F5D)),
                      onPressed: () {
                        actualizarAnimal(int.parse(animal["id_animal"].toString()));
                        Navigator.pop(context);
                      },
                      child: const Text("Actualizar Animal"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _registroanimal(BuildContext context) {

    limpiarCampos();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color.fromARGB(255, 126, 179, 128), borderRadius: BorderRadius.circular(15)),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text("Registrar Animal", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _formularioAnimal(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300]),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar", style: TextStyle(color: Colors.black)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A8F5D)),
                      onPressed: () {
                        btningresaranimal();
                        limpiarCampos();
                        Navigator.pop(context);
                      },
                      child: const Text("Registrar Animal"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Color de fondo gris claro
      body: Column(
        children: [
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Inventario de Animales",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                
                // Buscador
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: "Buscador...",
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.tune)),
                  ],
                ),
                const SizedBox(height: 15),
                
                // Filtros de Especies
                const Text("Especies", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chipEspecie("Bovino", null, true),
                      _chipEspecie("Ovino", null, false),
                      _chipEspecie("Todos", null, false),
                      ElevatedButton.icon(
                        onPressed:  () =>_registroanimal(context),
                        icon: const Icon(Icons.add),
                        label: const Text("Nuevo Animal"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de Animales (Reemplaza a la Tabla)
          Expanded(
            child: cargando 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: animales.length,
                  itemBuilder: (context, index) => _cardAnimal(animales[index]),
                ),
          ),
        ],
      ),
    );
  }

  Widget _chipEspecie(String label, IconData? icon, bool selected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.green.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? Colors.green : Colors.grey.shade300),
      ),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 16, color: selected ? Colors.green : Colors.black),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: selected ? Colors.green : Colors.black, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  Widget _cardAnimal(dynamic animal) {
    // Lógica de sincronización basada en tu base de datos offline
    bool estaSincronizado = animal["estado_sincronizacion"] == 1 || animal["estado_sincronizacion"] == 0; 

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // Información central
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal["identificador"] ?? "Sin ID",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 4),
                          Text(animal["tipo"] ?? "", style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Grid de datos (Peso, Edad, Finca)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoMiniCol("Peso", "${animal["peso"]} kg"),
                          _infoMiniCol("Edad", "${animal["edad"]} años"),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _infoMiniCol("Finca", animal["nombre_finca"] ?? "N/A"),
                    ],
                  ),
                ),

                // Columna de Estado y Acciones
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Icono de sincronización
                    Icon(
                      estaSincronizado ? Icons.sync : Icons.hourglass_empty,
                      color: estaSincronizado ? Colors.green : Colors.orange,
                    ),
                    Text(
                      estaSincronizado ? "Sincronizado" : "Pendiente",
                      style: TextStyle(fontSize: 10, color: estaSincronizado ? Colors.green : Colors.orange),
                    ),
                    const SizedBox(height: 20),
                    
                    // Botones de acción estilo texto
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _modificarAnimal(context, animal),
                          icon: const Icon(Icons.edit, color: Colors.green),
                        ),
                        IconButton(
                          onPressed: () => _btneliminarAnimal(int.parse(animal["id_animal"].toString())),
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoMiniCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}