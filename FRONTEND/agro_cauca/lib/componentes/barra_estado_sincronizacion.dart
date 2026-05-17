import 'package:flutter/material.dart';
import '../componentes/estado_sincronizacion.dart';

class BarraEstadoSincronizacion extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: EstadoSincronizacion().estado,
      builder: (context, estado, _) {
        String texto = "";
        Color color = Colors.grey;

        switch (estado) {
          case SincronizacionEstado.conectado:
            texto = "Conectado";
            color = Colors.green;
            break;
          case SincronizacionEstado.pendiente:
            texto = "Pendiente";
            color = Colors.orange;
            break;
          case SincronizacionEstado.sincronizado:
            texto = "Sincronizado";
            color = Colors.blue;
            break;
          case SincronizacionEstado.sinConexion:
            texto = "Sin conexión";
            color = Colors.red;
            break;
        }

        return Row(
          mainAxisSize: MainAxisSize.min, // 🔥 CLAVE
          children: [
            Icon(Icons.circle, color: color, size: 10),
            const SizedBox(width: 4),
            Text(
              texto,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        );
      },
    );
  }
}