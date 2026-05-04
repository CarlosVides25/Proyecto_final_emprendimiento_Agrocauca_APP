import 'package:flutter/material.dart';
import 'texto.dart'; 

class Desplegable {

  static Widget desplagbleBase({
    required String hint,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: options.map((e) {
        return DropdownMenuItem(
          value: e,
          child: Text(_capitalizar(e)),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: Texto.decoracion(hint), // 👈 reutilizas tu decoración
    );
  }

  // 🔹 Función privada para capitalizar texto
  static String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }
}