import 'package:flutter/material.dart';
import 'package:trabajo_final/componentes/estado_sincronizacion.dart';
import 'package:trabajo_final/base_datos/base_de_datos.dart';

class ReporteGeneral extends StatefulWidget {
  final int usuario;

  const ReporteGeneral({super.key, required this.usuario});

  @override
  State<ReporteGeneral> createState() => _ReporteGeneralState();
}

class _ReporteGeneralState extends State<ReporteGeneral> {
  bool cargando = true;

  int totalFincas = 0;
  int totalAnimales = 0;
  double promedioPeso = 0;

  List<Map<String, dynamic>> animalesPorFinca = [];

  @override
  void initState() {
    super.initState();
    cargarReportes();
  }

  Future<void> cargarReportes() async {
    if (EstadoSincronizacion().estado.value == SyncStatus.sinConexion) {
      await _cargarOffline();
    } else {
      await _cargarOffline(); // 🔥 puedes cambiar luego a online
    }

    setState(() {
      cargando = false;
    });
  }

  // =========================
  // 🔹 OFFLINE (SQLite)
  // =========================
  Future<void> _cargarOffline() async {
    final db = await BaseDeDatos.database;

    // 🔹 Total fincas
    final fincas = await db.rawQuery(
      "SELECT COUNT(*) as total FROM fincas WHERE usuario_id = ? AND eliminado = 0",
      [widget.usuario],
    );

    totalFincas = fincas.first["total"] as int;

    // 🔹 Total animales
    final animales = await db.rawQuery("""
      SELECT COUNT(a.id_animal) as total
      FROM animales a
      INNER JOIN fincas f ON a.finca_id = f.id_finca
      WHERE f.usuario_id = ? AND a.eliminado = 0
    """, [widget.usuario]);

    totalAnimales = animales.first["total"] as int;

    // 🔹 Promedio peso
    final peso = await db.rawQuery("""
      SELECT AVG(a.peso) as promedio
      FROM animales a
      INNER JOIN fincas f ON a.finca_id = f.id_finca
      WHERE f.usuario_id = ? AND a.eliminado = 0
    """, [widget.usuario]);

    promedioPeso = (peso.first["promedio"] ?? 0).toDouble();

    // 🔹 Animales por finca
    animalesPorFinca = await db.rawQuery("""
      SELECT f.nombre, COUNT(a.id_animal) as total
      FROM fincas f
      LEFT JOIN animales a ON a.finca_id = f.id_finca AND a.eliminado = 0
      WHERE f.usuario_id = ? AND f.eliminado = 0
      GROUP BY f.id_finca
    """, [widget.usuario]);
  }

  // =========================
  // 🎨 UI
  // =========================
  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📊 Reportes Generales",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // 🔹 CARDS RESUMEN
          Row(
            children: [
              _card("Fincas", totalFincas.toString(), Icons.home),
              _card("Animales", totalAnimales.toString(), Icons.pets),
              _card("Peso Prom.", promedioPeso.toStringAsFixed(1), Icons.scale),
            ],
          ),

          const SizedBox(height: 30),

          const Text(
            "🐄 Animales por Finca",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Expanded(child: _tablaFincas()),
        ],
      ),
    );
  }

  // =========================
  // 🔹 CARD RESUMEN
  // =========================
  Widget _card(String titulo, String valor, IconData icono) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icono, color: Colors.green, size: 30),
            const SizedBox(height: 10),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(titulo),
          ],
        ),
      ),
    );
  }

  // =========================
  // 🔹 TABLA
  // =========================
  Widget _tablaFincas() {
    return ListView.builder(
      itemCount: animalesPorFinca.length,
      itemBuilder: (context, index) {
        final f = animalesPorFinca[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                f["nombre"],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("${f["total"]} animales"),
            ],
          ),
        );
      },
    );
  }
}