import 'package:trabajo_final/componentes/grafica_barras.dart';
import 'package:trabajo_final/componentes/grafica_ganacias.dart';
import 'package:trabajo_final/componentes/grafica_roi.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:trabajo_final/componentes/Funciones.dart';

class AnalisisFinanciero extends StatefulWidget {
  final int usuario;

  const AnalisisFinanciero({super.key, required this.usuario});

  @override
  State<AnalisisFinanciero> createState() => _AnalisisFinancieroState();
}

class _AnalisisFinancieroState extends State<AnalisisFinanciero> {

  List animales = [];
  bool cargando = true;

  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    obtenerAnimales();
  }

  String money(double v) {
    return "\$${v.toStringAsFixed(0)}";
  }

  Future<void> obtenerAnimales() async {
    final url = Uri.parse("http://10.211.222.189/AgroCauca/BACKEND/animal/listar_animales.php");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"usuario": widget.usuario}),
    );

    final res = jsonDecode(response.body);

    if (res["success"]) {
      animales = res["data"];
      cargando = false;

      procesarDatos(); // 🔥 IMPORTANTE
    }
  }

  void procesarDatos() {
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
    if (data == null) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // 🔥 CLAVE
          children: [

            Text(
              "Análisis Financiero",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 15),

            // 🔹 CARDS
            Wrap(
              children: [
                SizedBox(
                  width: 200,
                  child: card("Inversión Total", money(data!['inversion']), Colors.blue),
                ),
                SizedBox(
                  width: 200,
                  child: card("Valor Venta Proyectado", money(data!['venta']), Colors.green),
                ),
                SizedBox(
                  width: 200,
                  child: card("Ganancia Total", money(data!['ganancia']), Colors.purple),
                ),
                SizedBox(
                  width: 200,
                  child: card("ROI", "${data!['roi'].toStringAsFixed(1)}%", Colors.orange),
                ),
              ],
            ),

            SizedBox(height: 20),

            // 🔹 GRÁFICAS
            GraficaBarras(
              inversion: data!['inversion'],
              venta: data!['venta'],
            ),

            SizedBox(height: 20),

            GraficaGanancias(
              data: data!['detalle'],
            ),

            SizedBox(height: 20),

            GraficaROI(
              roi: data!['roi'],
            ),

            SizedBox(height: 20),

            ListView.builder(
              shrinkWrap: true, // 🔥 CLAVE
              physics: NeverScrollableScrollPhysics(), 
              itemCount: data!['detalle'].length,
              itemBuilder: (context, i) {
                var a = data!['detalle'][i];

                return Card(
                  child: ListTile(
                    title: Text(a['id']),
                    subtitle: Text("Raza: ${a['raza']} - Peso: ${a['peso']}"),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          money(a['ganancia']),
                          style: TextStyle(
                            color: a['ganancia'] >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        Text("${a['rentabilidad'].toStringAsFixed(1)}%"),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}