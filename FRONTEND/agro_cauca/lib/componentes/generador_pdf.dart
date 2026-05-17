import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class GeneradorPDF {

  // =========================================
  // PDF ESTADÍSTICAS
  // =========================================
  static Future<void> generarReporteEstadisticas(
    Map<String, dynamic> data,
  ) async {

    final pdf = pw.Document();

    final fecha = DateFormat("dd/MM/yyyy").format(DateTime.now());

    final resumen = data["resumen"];
    final fincas = data["fincas"];
    final distribucion = data["distribucion"];

    final tipos = distribucion["tipo"] as List;
    final sexos = distribucion["sexo"] as List;
    final razas = distribucion["raza"] as List;
    final propositos = distribucion["proposito"] as List;
    final estados = distribucion["estado"] as List;
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,

        header: (context) => _header(
          "Reporte Estadístico",
          fecha,
        ),

        build: (context) => [

          pw.Header(
            level: 0,
            text: "Resumen General",
          ),

          pw.Row(
            mainAxisAlignment:
                pw.MainAxisAlignment.spaceAround,
            children: [

              _boxResumen(
                "Total Fincas",
                resumen["total_fincas"].toString(),
              ),

              _boxResumen(
                "Total Animales",
                resumen["total_animales"].toString(),
              ),
            ],
          ),

          pw.SizedBox(height: 25),

          pw.Text(
            "Peso Promedio por Finca",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 16,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(

            headers: [
              "Finca",
              "Animales",
              "Peso Promedio",
            ],

            data: fincas.map<List<String>>((f) {

              return [

                f["nombre"].toString(),

                f["total_animales"].toString(),

                "${f["peso_promedio"] ?? 0} kg",
              ];

            }).toList(),



            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),

            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.green,
            ),
          ),

           pw.SizedBox(height: 25),

          pw.Text(
            "Distribución por Especie",
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(
            headers: ['Especie', 'Cantidad'],
            data: tipos.map((t) => [
              t["tipo"],
              t["total"].toString(),
            ]).toList(),

            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),

            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.green,
            ),
          ),

          pw.SizedBox(height: 25),

          pw.Text(
            "Distribución por Sexo",
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(
            headers: ['Especie', 'Sexo', 'Cantidad'],
            data: sexos.map((s) => [
              s["tipo"],
              s["sexo"],
              s["total"].toString(),
            ]).toList(),

            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),

            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.green,
            ),
          ),

          pw.SizedBox(height: 25),

          pw.Text(
            "Distribución por Raza",
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(
            headers: ['Especie', 'Raza', 'Cantidad'],
            data: razas.map((r) => [
              r["tipo"],
              r["raza"],
              r["total"].toString(),
            ]).toList(),

            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),

            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.green,
            ),
          ),

          pw.Text(
          "Distribución por Propósito",
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),

        pw.SizedBox(height: 10),

        pw.TableHelper.fromTextArray(
          headers: ['Propósito', 'Cantidad'],
          data: propositos.map((p) => [
            p["proposito"],
            p["total"].toString(),
          ]).toList(),
        ),

        pw.SizedBox(height: 20),

        pw.Text(
          "Estado del Ganado",
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),

        pw.SizedBox(height: 10),

        pw.TableHelper.fromTextArray(
          headers: ['Estado', 'Cantidad'],
          data: estados.map((e) => [
            e["estado"],
            e["total"].toString(),
          ]).toList(),
        ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // =========================================
  // PDF FINANCIERO
  // =========================================
  static Future<void> generarReporteFinanciero(
    Map<String, dynamic> data,
  ) async {

    final pdf = pw.Document();

    final fecha = DateFormat("dd/MM/yyyy").format(DateTime.now());

    final detalle = data["detalle"];

    pdf.addPage(
      pw.MultiPage(

        pageFormat: PdfPageFormat.a4,

        header: (context) => _header(
          "Reporte Financiero",
          fecha,
        ),

        build: (context) => [

          pw.Header(
            level: 0,
            text: "Resumen Financiero",
          ),

          pw.Wrap(
            spacing: 15,
            runSpacing: 15,

            children: [

              _boxResumen(
                "Inversión",
                dinero(data["inversion"]),
              ),

              _boxResumen(
                "Venta",
                dinero(data["venta"]),
              ),

              _boxResumen(
                "Ganancia",
                dinero(data["ganancia"]),
              ),

              _boxResumen(
                "ROI",
                "${data["roi"].toStringAsFixed(1)}%",
              ),
            ],
          ),

          pw.SizedBox(height: 25),

          pw.Text(
            "Detalle por Animal",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 16,
            ),
          ),

          pw.SizedBox(height: 10),

          pw.TableHelper.fromTextArray(

            headers: [
              "ID",
              "Tipo",
              "Raza",
              "Ganancia",
              "ROI"
            ],

            data: detalle.map<List<String>>((a) {

              return [

                a["id"].toString(),

                a["tipo"].toString(),

                a["raza"].toString(),

                dinero(a["ganancia"]),

                "${a["rentabilidad"].toStringAsFixed(1)}%",
              ];

            }).toList(),

            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),

            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.green,
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // =========================================
  // HEADER
  // =========================================
  static pw.Widget _header(
    String titulo,
    String fecha,
  ) {

    return pw.Row(
      mainAxisAlignment:
          pw.MainAxisAlignment.spaceBetween,

      children: [

        pw.Text(
          "AgroCauca - $titulo",
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green,
          ),
        ),

        pw.Text(fecha),
      ],
    );
  }

  // =========================================
  // CARD RESUMEN
  // =========================================
  static pw.Widget _boxResumen(
    String titulo,
    String valor,
  ) {

    return pw.Container(

      padding: const pw.EdgeInsets.all(10),

      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.green,
        ),

        borderRadius:
            const pw.BorderRadius.all(
          pw.Radius.circular(5),
        ),
      ),

      child: pw.Column(
        children: [

          pw.Text(
            titulo,
            style: const pw.TextStyle(
              fontSize: 12,
            ),
          ),

          pw.SizedBox(height: 5),

          pw.Text(
            valor,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // FORMATO DINERO
  // =========================================
  static String dinero(dynamic valor) {

    final formato =
        NumberFormat("#,##0.00", "es_CO");

    return "\$${formato.format(valor)}";
  }
}