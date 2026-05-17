import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GraficaCircularPersonalizada extends StatelessWidget {
  final List datos;
  final String campoNombre; // ej: "tipo", "raza"
  final String titulo;

  const GraficaCircularPersonalizada({
    super.key,
    required this.datos,
    required this.campoNombre,
    required this.titulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 45,
                sections: _generarSecciones(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _crearLeyenda(), // Agregamos una leyenda debajo para mayor claridad
        ],
      ),
    );
  }

  List<PieChartSectionData> _generarSecciones() {
    final List<Color> colores = [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.teal];
    
    return datos.asMap().entries.map((e) {
      int i = e.key;
      var item = e.value;
      return PieChartSectionData(
        color: colores[i % colores.length],
        value: double.parse(item["total"].toString()),
        title: item["total"].toString(), // Solo el número dentro del pastel
        radius: 50,
        titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _crearLeyenda() {
    final List<Color> colores = [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.teal];
    return Wrap(
      spacing: 15,
      children: datos.asMap().entries.map((e) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: colores[e.key % colores.length]),
            const SizedBox(width: 5),
            Text(e.value[campoNombre], style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }
}