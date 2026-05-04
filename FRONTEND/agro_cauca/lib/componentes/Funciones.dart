import 'package:flutter/material.dart';

class Funciones {
  static void mostrarMensaje(
    BuildContext context,
    String titulo,
    String mensaje, {
    bool exito = true,
    VoidCallback? onAceptar,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                exito ? Icons.check_circle : Icons.error,
                color: exito ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    color: exito ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                if (onAceptar != null) {
                  onAceptar();
                }
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }
}