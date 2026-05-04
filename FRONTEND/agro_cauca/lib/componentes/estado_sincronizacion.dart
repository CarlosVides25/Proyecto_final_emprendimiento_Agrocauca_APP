import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

enum SyncStatus {
  conectado,
  pendiente,
  sincronizado,
  sinConexion
}

class EstadoSincronizacion {
  static final EstadoSincronizacion _instance = EstadoSincronizacion._internal();
  factory EstadoSincronizacion() => _instance;

  EstadoSincronizacion._internal(); // ❌ sin _init aquí

  final ValueNotifier<SyncStatus> estado = ValueNotifier(SyncStatus.sinConexion);

  Future<void> init() async {
    await verificarConexion();

    Connectivity().onConnectivityChanged.listen((event) {
      verificarConexion();
    });
  }

  Future<void> verificarConexion() async {
    var result = await Connectivity().checkConnectivity();

    if (result == ConnectivityResult.none) {
      estado.value = SyncStatus.sinConexion;
      return;
    }

    try {
      final response = await http
          .get(Uri.parse("https://clients3.google.com/generate_204"))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 204) {
        estado.value = SyncStatus.conectado;
      } else {
        estado.value = SyncStatus.sinConexion;
      }
    } catch (e) {
      estado.value = SyncStatus.sinConexion;
    }
  }

  void setPendiente() => estado.value = SyncStatus.pendiente;
  void setSincronizado() => estado.value = SyncStatus.sincronizado;
}