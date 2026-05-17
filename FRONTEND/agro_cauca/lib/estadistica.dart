import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:agrocauca/base_datos/base_de_datos.dart';
import 'package:agrocauca/componentes/grafica_circular.dart';
import 'package:agrocauca/componentes/generador_pdf.dart';
import 'package:agrocauca/componentes/estado_sincronizacion.dart';
class Estadisticas extends StatefulWidget {
  final int usuario;
  final int idEmpresa;
  const Estadisticas({super.key, required this.usuario, required this.idEmpresa});

  @override
  State<Estadisticas> createState() => _EstadisticasState();
}

class _EstadisticasState extends State<Estadisticas> {

  bool cargando = true;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    
    cargar();
  }

  Future<void> cargar() async {

    if(EstadoSincronizacion().estado.value==SincronizacionEstado.sinConexion){
      data = await obtenerReportesOffline(widget.idEmpresa);
    }
    else{
      data = await obtenerReportesOnline(widget.idEmpresa);
    }

    
    setState(() => cargando = false);
  }

  Future<Map<String, dynamic>> obtenerReportesOnline(int idEmpresa) async {
    final url = Uri.parse("http://10.172.172.189/AgroCauca/BACKEND/reportes/reporte.php");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_empresa": idEmpresa}),
    );

    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> obtenerReportesOffline(int idEmpresa) async {
    print("cargando consulta offline");
    final resultado = await BaseDeDatos.obtenerReportes(idEmpresa);

    return resultado;
  }


  @override
  Widget build(BuildContext context) {
    if (cargando) return const Center(child: CircularProgressIndicator());

    final resumen = data!["resumen"];
    final fincas = data!["fincas"];
    final dist = data!["distribucion"];
    final propositos = dist["proposito"];
    final estados = dist["estado"];

    // 1. Extraemos la lista de tipos únicos (Bovino, Equino, etc.)
    final List tiposEncontrados = dist["tipo"] ?? [];

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          Row(
            children: [
              const Text("Estadisticas Ganaderas", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => GeneradorPDF.generarReporteEstadisticas(data!),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text("Exportar PDF"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- CARDS DE RESUMEN ---
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _cardIndividual("Total Fincas", resumen["total_fincas"].toString(), Icons.landscape),
                      _cardIndividual("Total Animales", resumen["total_animales"].toString(), Icons.pets),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // --- PESO PROMEDIO ---
                  const Text("Peso promedio por finca", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...fincas.map<Widget>((f) => Card(
                    child: ListTile(
                      title: Text(f["nombre"]),
                      subtitle: Text("Peso promedio: ${(f["peso_promedio"] ?? 0)} kg"),
                      trailing: Text("${f["total_animales"]} animales"),
                    ),
                  )).toList(),

                  const SizedBox(height: 30),
                  const Divider(thickness: 2),
                  SizedBox(
                          height: 370,
                          child: GraficaCircularPersonalizada(
                            datos: estados,
                            campoNombre: "estado",
                            titulo: "Estado del Ganado",
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(),
                        ),


                         SizedBox(
                          height: 370,
                          child: GraficaCircularPersonalizada(
                            datos: propositos,
                            campoNombre: "proposito",
                            titulo: "Distribución por Propósito",
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(),
                        ),

                        Text("Distribución por tipo de raza y sexo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  // 2. GENERACIÓN AUTOMÁTICA DE TODAS LAS GRÁFICAS POR TIPO
                  ...tiposEncontrados.map<Widget>((t) {
                    final String nombreTipo = t["tipo"];

                    // Filtramos los datos específicos para este tipo
                    final List razasDeEsteTipo = (dist["raza"] as List)
                        .where((r) => r["tipo"] == nombreTipo).toList();
                    
                    final List sexosDeEsteTipo = (dist["sexo"] as List)
                        .where((s) => s["tipo"] == nombreTipo).toList();
                     
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            
                            child: Text(
                              "ESPECIE: ${nombreTipo.toUpperCase()}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        
                        // Gráfica de Raza para este tipo
                        SizedBox(
                          height: 370,
                          child: GraficaCircularPersonalizada(
                            datos: razasDeEsteTipo,
                            campoNombre: "raza",
                            titulo: "Distribución de Razas ($nombreTipo)",
                          ),
                        ),
                        
                        const SizedBox(height: 20),

                        // Gráfica de Sexo para este tipo
                        SizedBox(
                          height: 370,
                          child: GraficaCircularPersonalizada(
                            datos: sexosDeEsteTipo,
                            campoNombre: "sexo",
                            titulo: "Distribución por Sexo ($nombreTipo)",
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    );
                  }).toList(),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Auxiliar para las tarjetas de arriba (agrégalo al final de tu clase)
  Widget _cardIndividual(String t, String v, IconData icono) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Icon(icono, color: Colors.green),
          const SizedBox(height: 5),
          Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(t, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

}
