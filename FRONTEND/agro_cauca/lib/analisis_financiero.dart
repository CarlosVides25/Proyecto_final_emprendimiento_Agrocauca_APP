import 'package:agrocauca/componentes/grafica_barras.dart';
import 'package:agrocauca/componentes/grafica_ganacias.dart';
import 'package:agrocauca/componentes/grafica_roi.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:agrocauca/componentes/Funciones.dart';
import 'package:intl/intl.dart';
import 'package:agrocauca/base_datos/base_de_datos.dart';
import 'package:agrocauca/componentes/estado_sincronizacion.dart';
import 'package:agrocauca/componentes/generador_pdf.dart';

class Finanzas extends StatefulWidget {
  final int usuario;
  final int idEmpresa;

  const Finanzas({super.key, required this.usuario, required this.idEmpresa});

  @override
  State<Finanzas> createState() => _FinanzasState();
}

class _FinanzasState extends State<Finanzas> {

  bool verDetalleGrafico = false;
  List animales = [];
  bool cargando = true;
  String filtroBusqueda = "";
  TextEditingController _buscadorControlador = TextEditingController();
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
     if(EstadoSincronizacion().estado.value==SincronizacionEstado.sinConexion){
      obtenerAnimalesOffline();
    }
    else{
      obtenerAnimalesOnline();

    }

  }

  String dinero(double valor) {
    final formato = NumberFormat("#,##0.00", "es_CO");
    return "\$${formato.format(valor)}";
  }

  Future<void> obtenerAnimalesOffline() async {
    print("📱 Cargando animales OFFLINE");

    try {
      final data = await BaseDeDatos.obtenerAnimales(widget.idEmpresa);

      setState(() {
        animales = data;
        cargando = false;
        procesarDatos(); 
      });

    } catch (e) {
      print("❌ Error obteniendo animales offline: $e");

    }
  }

  Future<void> obtenerAnimalesOnline() async {
    final url = Uri.parse("http://18.222.251.74/animal/listar_animales.php");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_empresa": widget.idEmpresa}),
    );

    final res = jsonDecode(response.body);

    if (res["success"]) {
      animales = res["data"];
      cargando = false;

      procesarDatos(); 
    }
  }

  void procesarDatos() {
    print("inicio");
    print(animales);

    double inversionTotal = 0;
    double ventaTotal = 0;

    List detalle = [];

    for (var a in animales) {
      double compra = double.tryParse(a["precio_compra"].toString()) ?? 0;
      double precioKilo = double.tryParse(a["precio_kilo"].toString()) ?? 0;
      double peso = double.tryParse(a["peso"].toString()) ?? 0;
      double mantenimiento = double.tryParse(a["gasto_mantenimiento"].toString()) ?? 0;

      double inversion = compra + mantenimiento;
      double venta = peso * precioKilo;
      double ganancia = venta - inversion;

      double rentabilidad = 0;
      if (inversion > 0) {
        rentabilidad = (ganancia / inversion) * 100;
      }

      inversionTotal += inversion;
      ventaTotal += venta;

      detalle.add({
        "id": a["identificador"],
        "raza": a["raza"],
        "tipo": a["tipo"],
        "peso": peso,
        "ganancia": ganancia,
        "rentabilidad": rentabilidad,
      });
    }

    double gananciaTotal = ventaTotal - inversionTotal;

    double roi = 0;
    if (inversionTotal > 0) {
      roi = (gananciaTotal / inversionTotal) * 100;
    }

    setState(() {
      data = {
        "inversion": inversionTotal,
        "venta": ventaTotal,
        "ganancia": gananciaTotal,
        "roi": roi,
        "detalle": detalle,
      };
    });
  }

  Widget card(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 12)),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          )
        ],
      ),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    if (data == null) return const Center(child: CircularProgressIndicator());

    // 🔥 Lógica de filtrado
    List listaFiltrada = (data!['detalle'] as List).where((a) {
      final query = filtroBusqueda.toLowerCase();
      final id = a['id'].toString().toLowerCase();
      final raza = a['raza'].toString().toLowerCase();
      final tipo = (a['tipo'] ?? "").toString().toLowerCase();

      return id.contains(query) || raza.contains(query) || tipo.contains(query);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Finanzas", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Spacer(),
              ElevatedButton.icon(
                onPressed: () => GeneradorPDF.generarReporteFinanciero(data!),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Exportar PDF"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 15),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _cardFinanciera("Inversión Total", dinero(data!['inversion']), Colors.blue),
              _cardFinanciera("Venta Proyectada", dinero(data!['venta']), Colors.green),
              _cardFinanciera("Ganancia Total", dinero(data!['ganancia']), Colors.purple),
              _cardFinanciera("ROI", "${data!['roi'].toStringAsFixed(1)}%", Colors.orange),
            ],
          ),// Tus cards de inversión
          const SizedBox(height: 25),

          // Selector de vista (Gráficas / Detalle)
          Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _botonToggleFinanciero(
                  label: "Gráficas",
                  icono: Icons.bar_chart,
                  activo: verDetalleGrafico,
                  onTap: () => setState(() => verDetalleGrafico = true),
                ),
              ),
              Expanded(
                child: _botonToggleFinanciero(
                  label: "Detalle Animales",
                  icono: Icons.table_rows,
                  activo: !verDetalleGrafico,
                  onTap: () => setState(() => verDetalleGrafico = false),
                ),
              ),
            ],
          ),
        ),

          const SizedBox(height: 15),

          // 🔍 BUSCADOR (Solo visible en la pestaña de Detalle)
          if (!verDetalleGrafico)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: _buscadorControlador,
                decoration: InputDecoration(
                  hintText: "Buscar por ID, Raza o Tipo...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: filtroBusqueda.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _buscadorControlador.clear();
                          setState(() => filtroBusqueda = "");
                        },
                      )
                    : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (val) => setState(() => filtroBusqueda = val),
              ),
            ),

          // CONTENIDO
          Expanded(
            child: SingleChildScrollView(
              child: verDetalleGrafico 
                ? _vistaGraficasFinancieras() 
                : _vistaListadoDetalle(listaFiltrada), // Enviamos la lista filtrada
            ),
          ),
        ],
      ),
    );
  }

  // --- MÉTODOS DE SOPORTE ---

  Widget _vistaListadoDetalle(List lista) {
    if (lista.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("No se encontraron animales con ese criterio."),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lista.length,
      itemBuilder: (context, i) {
        var a = lista[i];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            title: Text("ID: ${a['id']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${a['tipo']} • ${a['raza']}\nPeso: ${a['peso']}kg"),
            isThreeLine: true,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dinero(a['ganancia']),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: a['ganancia'] >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                Text("${a['rentabilidad'].toStringAsFixed(1)}% ROI", style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _vistaGraficasFinancieras() {
    return Column(
      children: [
        GraficaBarras(inversion: data!['inversion'], venta: data!['venta']),
        const SizedBox(height: 20),
        GraficaGanancias(data: data!['detalle']),
        const SizedBox(height: 20),
        GraficaROI(roi: data!['roi']),
        const SizedBox(height: 30),
      ],
    );
  }


  Widget _botonToggleFinanciero({required String label, required IconData icono, required bool activo, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: activo ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, color: activo ? Colors.white : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: activo ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardFinanciera(String titulo, String valor, Color color) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}