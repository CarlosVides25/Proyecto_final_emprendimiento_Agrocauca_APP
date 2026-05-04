import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Texto {

  // 🔹 TextField completo reutilizable
  static Widget campoTexto(
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool soloEnteros = false,
    bool soloDecimales = false,
  }) {
    List<TextInputFormatter> formatters = [];

    if (soloEnteros) {
      formatters = [
        FilteringTextInputFormatter.digitsOnly, // 🔢 solo números enteros
      ];
      keyboardType = TextInputType.number;
    } else if (soloDecimales) {
      formatters = [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // 🔢 decimales
      ];
      keyboardType = const TextInputType.numberWithOptions(decimal: true);
    }

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      decoration: decoracion(hint),
    );
  }

  // 🔹 Decoración reutilizable
  static InputDecoration decoracion(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }
}