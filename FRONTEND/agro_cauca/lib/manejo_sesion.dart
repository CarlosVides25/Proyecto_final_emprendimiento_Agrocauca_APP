import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:agrocauca/componentes/estado_sincronizacion.dart';

class SessionManager {
  // Llaves constantes para evitar errores de dedo
  static const String _keyToken = 'token_sesion';
  static const String _keyId = 'id_usuario';
  static const String _keyNombre = 'nombre_usuario';
  static const String _keyCorreo = 'correo_usuario';
  static const String _keyempresa = 'id_empresa';
  static const String _keyNombreEmpresa = 'nombre_empresa';

  // Guardar sesión tras el login exitoso
  static Future<void> guardarSesion(String token, int idUsuario, String nombre, String correo, int idEmpresa, String nombreEmpresa) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setInt(_keyId, idUsuario);
    await prefs.setString(_keyNombre, nombre);
    await prefs.setString(_keyCorreo, correo);
    await prefs.setInt(_keyempresa, idEmpresa);
    await prefs.setString(_keyNombreEmpresa, nombreEmpresa);
  }

  // Obtener el ID
  static Future<int?> getUsuarioId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyId);
  }

  // Obtener Nombre
  static Future<String?> getUsuarioNombre() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNombre);
  }

  // Obtener Correo
  static Future<String?> getUsuarioCorreo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCorreo);
  }
  
  static Future<int?> getEmpresa() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyempresa);
  }
  static Future<String?> getNombreEmpresa() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNombreEmpresa);
  }

  // Cerrar sesión - Borra todo lo relacionado
  static Future<void> cerrarSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyId);
    await prefs.remove(_keyNombre);
    await prefs.remove(_keyCorreo);
    await prefs.remove(_keyempresa);
    await prefs.remove(_keyNombreEmpresa);
  }


  static Future<bool> esSesionValida() async {
    print("Validando sesión...");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(_keyToken);

    if (token == null) return false;

    // Verificar conexión

    //SIN INTERNET → VALIDAR LOCAL
    if (EstadoSincronizacion().estado.value == SincronizacionEstado.sinConexion) {
      int? id = prefs.getInt(_keyId);
      String? nombre = prefs.getString(_keyNombre);
      String? correo = prefs.getString(_keyCorreo);
      int? empresa = prefs.getInt(_keyempresa);
      String? nombreEmpresa = prefs.getString(_keyNombreEmpresa);

      // Si hay datos guardados → sesión válida
      return id != null && nombre != null && correo != null && empresa != null && nombreEmpresa != null;
    }
    else{
      print("Validando sesión con servidor...");
      final response = await http.post(
        Uri.parse("http://10.172.172.189/AgroCauca/BACKEND/verificar_sesion.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": token}),
      );

      final data = jsonDecode(response.body);
      print(response.body);

      if (data["success"] == true) {
        print("Sesión válida en servidor, guardando datos localmente...");
        await prefs.setInt(_keyId, int.parse(data['usuario'].toString()));
        await prefs.setString(_keyNombre, data['nombre'].toString());
        await prefs.setString(_keyCorreo, data['correo'].toString());
        await prefs.setInt(_keyempresa, int.parse(data['id_empresa'].toString()));
        await prefs.setString(_keyNombreEmpresa, data['nombre_empresa'].toString());
        return true;
      } else {
        return false;
      }
      
    }
    // CON INTERNET → VALIDAR CON SERVIDOR
    
  }
}