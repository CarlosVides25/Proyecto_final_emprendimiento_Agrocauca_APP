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
    var result = await Connectivity().checkConnectivity();

    if (result == ConnectivityResult.none) {
      estado.value = SincronizacionEstado.sinConexion;
      return;
    }

    try {
      final response = await http
          .get(Uri.parse("https://clients3.google.com/generate_204"))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 204) {
        estado.value = SincronizacionEstado.conectado;
        //sincronizar();
      } else {
        estado.value = SincronizacionEstado.sinConexion;
      }
    } catch (e) {
      estado.value = SincronizacionEstado.sinConexion;
    }
  }

  void setPendiente() => estado.value = SincronizacionEstado.pendiente;
  void setSincronizado() => estado.value = SincronizacionEstado.sincronizado;
}