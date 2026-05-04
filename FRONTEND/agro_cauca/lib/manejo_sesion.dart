import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class SessionManager {
  // Llaves constantes para evitar errores de dedo
  static const String _keyToken = 'token_sesion';
  static const String _keyId = 'id_usuario';
  static const String _keyNombre = 'nombre_usuario';
  static const String _keyCorreo = 'correo_usuario';

  // Guardar sesión tras el login exitoso
  static Future<void> guardarSesion(String token, int idUsuario, String nombre, String correo) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setInt(_keyId, idUsuario);
    await prefs.setString(_keyNombre, nombre);
    await prefs.setString(_keyCorreo, correo);
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

  // Cerrar sesión - Borra todo lo relacionado
  static Future<void> cerrarSesion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyId);
    await prefs.remove(_keyNombre);
    await prefs.remove(_keyCorreo);
  }


  static Future<bool> esSesionValida() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(_keyToken);

    if (token == null) return false;

    // Verificar conexión
    var connectivityResult = await Connectivity().checkConnectivity();

    //SIN INTERNET → VALIDAR LOCAL
    if (connectivityResult == ConnectivityResult.none) {
      print("error");
      int? id = prefs.getInt(_keyId);
      String? nombre = prefs.getString(_keyNombre);
      String? correo = prefs.getString(_keyCorreo);

      // Si hay datos guardados → sesión válida
      return id != null && nombre != null && correo != null;
    }

    // CON INTERNET → VALIDAR CON SERVIDOR
    try {
      final response = await http.post(
        Uri.parse("http://10.211.222.189/AgroCauca/BACKEND/verificar_sesion.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": token}),
      );

      final data = jsonDecode(response.body);

      if (data["success"] == true) {
        await prefs.setInt(_keyId, int.parse(data['usuario'].toString()));
        await prefs.setString(_keyNombre, data['nombre'].toString());
        await prefs.setString(_keyCorreo, data['correo'].toString());
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // ⚠️ Si falla el servidor → fallback LOCAL
      int? id = prefs.getInt(_keyId);
      return id != null;
    }
  }
}