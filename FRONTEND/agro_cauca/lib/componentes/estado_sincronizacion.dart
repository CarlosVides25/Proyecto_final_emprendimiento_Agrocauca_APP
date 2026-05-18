import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:agrocauca/base_datos/base_de_datos.dart';
import 'dart:convert';
import 'package:agrocauca/componentes/funciones.dart';
enum SincronizacionEstado {
  conectado,
  pendiente,
  sincronizado,
  sinConexion
}

class EstadoSincronizacion {
  static final EstadoSincronizacion _instance = EstadoSincronizacion._internal();
  factory EstadoSincronizacion() => _instance;

  EstadoSincronizacion._internal(); // ❌ sin _init aquí

  final ValueNotifier<SincronizacionEstado> estado = ValueNotifier(SincronizacionEstado.sinConexion);

  Future<void> init() async {
    await verificarConexion();

    Connectivity().onConnectivityChanged.listen((event) {
      verificarConexion();
    });
  }


  Future<void> verificarConexion() async {
    bool tieneHardwareConectado = false;

    try {
      // 1. Validar si el dispositivo reporta alguna interfaz activa
      var result = await Connectivity().checkConnectivity();
      
      // Convertimos el resultado a String para evitar problemas de compatibilidad de tipos (List vs Enum)
      String resultString = result.toString();

      // Si el texto contiene 'none', explícitamente no hay red física configurada
      if (resultString.contains('none')) {
        estado.value = SincronizacionEstado.sinConexion;
        return;
      } else {
        tieneHardwareConectado = true;
      }
    } catch (e) {
      // Si el plugin falla o no es compatible con el tipo, no bloqueamos al usuario;
      // asumimos que podría haber red y dejamos que el ping real a Google decida.
      print("Alerta en Connectivity Plugin (omitida por seguridad): $e");
      tieneHardwareConectado = true; 
    }

    // 2. La prueba reina: Salida real a internet mediante HTTP GET
    if (tieneHardwareConectado) {
      try {
        final response = await http
            .get(Uri.parse("https://clients3.google.com/generate_204"), headers: {
              "User-Agent": "Mozilla/5.0 (Linux; Android) AgroCauca"
            })
            .timeout(const Duration(seconds: 10)); // Incrementamos a 10s por si la red de pruebas está inestable

        if (response.statusCode == 204) {
          estado.value = SincronizacionEstado.conectado;
          // sincronizar(); // Descomenta cuando verifiques que funciona
        } else {
          print("Código de respuesta inesperado de Google: ${response.statusCode}");
          estado.value = SincronizacionEstado.sinConexion;
        }
      } catch (e) {
        print("Error de timeout o bloqueo de red al hacer ping: $e");
        estado.value = SincronizacionEstado.sinConexion;
      }
    }
  }

  void setPendiente() => estado.value = SincronizacionEstado.pendiente;
  void setSincronizado() => estado.value = SincronizacionEstado.sincronizado;
}