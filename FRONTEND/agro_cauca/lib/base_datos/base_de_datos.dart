import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BaseDeDatos {
  static Database? _database;

  // 🔹 Obtener instancia de la BD
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _iniciarDB();
    return _database!;
  }

  //Inicializar BD
  static Future<Database> _iniciarDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'agrocauca.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _crearBaseDatos,
    );
  }

  static Future _crearBaseDatos(Database db, int version) async {

    //TABLA Empresa
    await db.execute('''
      CREATE TABLE empresas (
        id_empresa INTEGER PRIMARY KEY,
        nombre_empresa TEXT,
        nit TEXT
      );
    ''');
    //TABLA USUARIO

    await db.execute('''
      CREATE TABLE config (
        clave TEXT PRIMARY KEY,
        valor TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE usuarios (
        id_usuario INTEGER PRIMARY KEY,
        nombre TEXT,
        correo TEXT,
        clave TEXT,
        id_empresa INTEGER, -- Relación con la empresa
        FOREIGN KEY (id_empresa) REFERENCES empresas (id_empresa)
      )
    ''');

    // TABLA FINCAS
    await db.execute('''
      CREATE TABLE fincas (
        id_finca INTEGER PRIMARY KEY, 
        nombre TEXT,
        ubicacion TEXT,
        area REAL,
        id_empresa INTEGER, -- A qué empresa pertenece

        total_animales INTEGER DEFAULT 0,

        fecha_creacion TEXT,
        actualizado_fecha TEXT,

        estado_sincronizacion INTEGER DEFAULT 0, -- 0 pendiente, 1 sincronizado
        eliminado INTEGER DEFAULT 0, -- 🔥 para borrado offline
        FOREIGN KEY (id_empresa) REFERENCES empresas (id_empresa)
      )
    ''');

    // TABLA ANIMALES
    await db.execute('''
      CREATE TABLE animales (
        id_animal INTEGER PRIMARY KEY,
        identificador TEXT,
        tipo TEXT,
        raza TEXT,
        edad INTEGER,
        peso REAL,
        sexo TEXT,
        proposito TEXT,
        estado_reproductivo TEXT,
        estado TEXT,
        id_finca INTEGER,
        
        precio_compra REAL,
        precio_kilo REAL,
        gasto_mantenimiento REAL,
        fecha_compra TEXT,

        fecha_creacion TEXT,
        actualizado_fecha TEXT,
        estado_sincronizacion INTEGER DEFAULT 0,
        eliminado INTEGER DEFAULT 0,

        FOREIGN KEY (id_finca) REFERENCES fincas (id_finca)
      )
    ''');
    
  }


  static Future<Map<String, dynamic>?> inicioSesionUsuario(String correo, String clave) async {
    final db = await database;

    // Usamos rawQuery para poder hacer el INNER JOIN con la tabla empresas
    final List<Map<String, dynamic>> res = await db.rawQuery('''
      SELECT 
        u.id_usuario,
        u.id_empresa,
        u.nombre,
        u.correo,
        u.clave, 
        e.nombre_empresa
      FROM usuarios u
      INNER JOIN empresas e ON e.id_empresa = u.id_empresa
      WHERE LOWER(TRIM(u.correo)) = ? AND TRIM(u.clave) = ?
    ''', [
      correo.trim().toLowerCase(),
      clave.trim(),
    ]);

    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  static Future<int> ingresarFinca(Map<String, dynamic> finca) async {
    final db = await database;
    int tempId = -DateTime.now().millisecondsSinceEpoch;
    // Creamos una copia para no modificar el objeto original y asegurar campos offline
    Map<String, dynamic> datosFinca = Map.from(finca);
    datosFinca['id_finca'] = tempId;
    datosFinca['estado_sincronizacion'] = 0; // 0 = Pendiente de subir al servidor
    datosFinca['eliminado'] = 0;
    datosFinca['fecha_creacion'] = DateTime.now().toString();
    datosFinca['actualizado_fecha'] = DateTime.now().toString();

    return await db.insert(
      'fincas', 
      datosFinca, 
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  // 🔹 Ingresar Animal Offline
  static Future<int> ingresarAnimal(Map<String, dynamic> animal) async {
    final db = await database;
    int tempId = -DateTime.now().millisecondsSinceEpoch;

    Map<String, dynamic> datosAnimal = Map.from(animal);
    datosAnimal['id_animal'] = tempId;
    datosAnimal['estado_sincronizacion'] = 0; // 0 = Pendiente de subir al servidor
    datosAnimal['eliminado'] = 0;
    datosAnimal['fecha_creacion'] = DateTime.now().toString();
    datosAnimal['actualizado_fecha'] = DateTime.now().toString();

    return await db.insert(
      'animales', 
      datosAnimal, 
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  static Future<int> actualizarFinca(Map<String, dynamic> finca) async {
    final db = await database;
    return await db.update(
      'fincas',
      {
        ...finca,
        'estado_sincronizacion': 0, // Pendiente de actualizar en la nube
        'actualizado_fecha': DateTime.now().toString(),
      },
      where: 'id_finca = ?',
      whereArgs: [finca['id_finca']],
    );
  }

  static Future<bool> baseDatosVacia() async {
    final db = await database;

    final fincas = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM fincas")
    ) ?? 0;

    final animales = Sqflite.firstIntValue(
      await db.rawQuery("SELECT COUNT(*) FROM animales")
    ) ?? 0;

    return fincas == 0 && animales == 0;
  }

  static Future<int> eliminarFincaLogico(int idFinca) async {
    final db = await database;
    return await db.update(
      'fincas',
      {
        'eliminado': 1,
        'estado_sincronizacion': 0,
        'actualizado_fecha': DateTime.now().toString(),
      },
      where: 'id_finca = ?',
      whereArgs: [idFinca],
    );
  }

  static Future<void> marcarComoSincronizado() async {
    final db = await database;
    print("marcando como sincronizado...");
    await db.update(
      'fincas',
      {'estado_sincronizacion': 1},
      where: 'estado_sincronizacion = ?',
      whereArgs: [0],
    );

    await db.update(
      'animales',
      {'estado_sincronizacion': 1},
      where: 'estado_sincronizacion = ?',
      whereArgs: [0],
    );
  }

  static Future<void> guardarUltimaSincronizacion(String fecha) async {
    final db = await database;

    await db.insert(
      'config',
      {
        'clave': 'ultima_sincronizacion',
        'valor': fecha,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<int> actualizarAnimal(Map<String, dynamic> animal) async {
    final db = await database;
    return await db.update(
      'animales',
      {
        ...animal,
        'estado_sincronizacion': 0,
        'actualizado_fecha': DateTime.now().toString(),
      },
      where: 'id_animal = ?',
      whereArgs: [animal['id_animal']],
    );
  }

  static Future<int> eliminarAnimalLogico(int idAnimal) async {
    final db = await database;
    return await db.update(
      'animales',
      {
        'eliminado': 1,
        'estado_sincronizacion': 0,
        'actualizado_fecha': DateTime.now().toString(),
      },
      where: 'id_animal = ?',
      whereArgs: [idAnimal],
    );
  }

  static Future<List<Map<String, dynamic>>> obtenerFincas(int empresaId) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      'fincas',
      where: 'id_empresa = ? AND eliminado = 0',
      whereArgs: [empresaId],
      orderBy: 'fecha_creacion DESC',
    );

    return result;
  }

  static Future<List<Map<String, dynamic>>> obtenerAnimales(int empresaId) async {
    final db = await database;

    return await db.rawQuery('''
      SELECT a.*,
      f.nombre AS nombre_finca
      FROM animales a
      INNER JOIN fincas f
        ON a.id_finca = f.id_finca
      WHERE f.id_empresa = ?
      AND a.eliminado = 0
      AND f.eliminado = 0
    ''', [empresaId]);
  }

  static Future<List<Map<String, dynamic>>> obtenerPendientes(String tabla) async {
    final db = await database;

    return await db.query(
      tabla,
      where: 'estado_sincronizacion = ?',
      whereArgs: [0],
    );
  }

  static Future<int> marcarSincronizado(
    String tabla,
    int id,
  ) async {

    final db = await database;

    String campoId =
        tabla == "fincas"
        ? "id_finca"
        : "id_animal";

    return await db.update(
      tabla,
      {'estado_sincronizacion': 1},
      where: '$campoId = ?',
      whereArgs: [id],
    );
  }

  // Función para limpiar y cargar datos nuevos desde el servidor
  static Future<void> cargarDatosServidor(Map<String, dynamic> data) async {
    final db = await database;

    Batch batch = db.batch();


    print("se hizo la carga de datos de la empresa");
    if (data['empresa'] != null) {
      var u = data['empresa'];

      batch.insert(
        'empresas',
        {
          'id_empresa': int.parse(u['id_empresa'].toString()),
          'nombre_empresa': u['nombre'].toString(),
          'nit': int.parse(u['nit'].toString()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    print("se hizo la carga de datos del usaurio");
    if (data['usuario'] != null) {
      var u = data['usuario'];

      batch.insert(
        'usuarios',
        {
          'id_usuario': int.parse(u['id_usuario'].toString()),
          'nombre': u['nombre'].toString(),
          'correo': u['correo'].toString(),
          'clave': u['contrasena']?.toString() ?? '',
          'id_empresa': int.parse(u['id_empresa'].toString()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    print("se hizo la carga de datos del finca");
    // 
    if (data['fincas'] != null) {
      for (var f in data['fincas']) {
          batch.insert(
            'fincas',
            {'id_finca': int.parse(f['id_finca'].toString()),
              'nombre': f['nombre'].toString(),
              'ubicacion': f['ubicacion'].toString(),
              'area': double.tryParse(f['area'].toString()) ?? 0,
              'id_empresa': int.parse(f['id_empresa'].toString()),
              'total_animales': int.tryParse(f['total_animales']?.toString() ?? "0") ?? 0,

              'fecha_creacion': f['fecha_creacion'].toString(),
              'actualizado_fecha': f['actualizado_fecha']?.toString() ?? f['fecha_creacion'].toString(),

              'estado_sincronizacion': 1, // viene del servidor → ya sincronizado
              'eliminado': int.tryParse(f['eliminado'].toString()) ?? 0,
            },
          conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
  
    //ANIMALES
    if (data['animales'] != null) {

      for (var a in data['animales']) {

        batch.insert(
          'animales',
            {
            'id_animal': int.parse(a['id_animal'].toString()),
            'identificador': a['identificador'].toString(),
            'tipo': a['tipo'].toString(),
            'raza': a['raza'].toString(),
            'edad': int.tryParse(a['edad'].toString()) ?? 0,
            'peso': double.tryParse(a['peso'].toString()) ?? 0,
            'sexo': a['sexo'].toString(),
            'proposito': a['proposito'].toString(),
            'estado_reproductivo': a['estado_reproductivo'].toString(),
            'estado': a['estado'].toString(),
            'precio_compra': double.tryParse(a['precio_compra'].toString()) ?? 0,
            'precio_kilo': double.tryParse(a['precio_kilo'].toString()) ?? 0,
            'gasto_mantenimiento': double.tryParse(a['gasto_mantenimiento'].toString()) ?? 0,
            'fecha_compra': a['fecha_compra'].toString(),
            'id_finca': int.parse(a['id_finca'].toString()),
            'fecha_creacion': a['fecha_creacion'].toString(),
            'actualizado_fecha': a['actualizado_fecha'].toString(),
            'estado_sincronizacion': 1,
            'eliminado': int.tryParse(a['eliminado'].toString()) ?? 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
          );

      }
    }

    await batch.commit(noResult: true);
  }

  static Future<Map<String, dynamic>> obtenerReportes(int idEmpresa) async {
    final db = await database;

    // =========================
    //RESUMEN 
    // =========================
    final resumenQuery = await db.rawQuery('''
      SELECT 
        (SELECT COUNT(*) FROM fincas WHERE id_empresa = ? AND eliminado = 0) AS total_fincas,
        (SELECT COUNT(*) 
          FROM animales a
          INNER JOIN fincas f ON a.id_finca = f.id_finca
          WHERE f.id_empresa = ? AND a.eliminado = 0 AND f.eliminado = 0) AS total_animales
    ''', [idEmpresa, idEmpresa]);

    // =========================
    //ANIMALES POR FINCA 
    // =========================
    final fincasQuery = await db.rawQuery('''
      SELECT 
        f.nombre,
        COUNT(a.id_animal) AS total_animales,
        ROUND(AVG(a.peso),1) AS peso_promedio
      FROM fincas f
      LEFT JOIN animales a ON a.id_finca = f.id_finca AND a.eliminado = 0
      WHERE f.id_empresa = ? AND f.eliminado = 0
      GROUP BY f.id_finca
    ''', [idEmpresa]);

    // =========================
    //DISTRIBUCIÓN POR TIPO
    // =========================
    final tipoQuery = await db.rawQuery('''
      SELECT a.tipo, COUNT(*) AS total
      FROM animales a
      INNER JOIN fincas f ON a.id_finca = f.id_finca
      WHERE f.id_empresa = ? AND a.eliminado = 0 AND f.eliminado = 0
      GROUP BY a.tipo
    ''', [idEmpresa]);

    // =========================
    //DISTRIBUCIÓN POR SEXO 
    // =========================
    final sexoQuery = await db.rawQuery('''
      SELECT a.tipo, a.sexo, COUNT(*) AS total
      FROM animales a
      INNER JOIN fincas f ON a.id_finca = f.id_finca
      WHERE f.id_empresa = ? AND a.eliminado = 0 AND f.eliminado = 0
      GROUP BY a.tipo, a.sexo
    ''', [idEmpresa]);

    // =========================
    //TOP RAZAS 
    // =========================
    final razaQuery = await db.rawQuery('''
      SELECT a.tipo, a.raza, COUNT(*) AS total
      FROM animales a
      INNER JOIN fincas f ON a.id_finca = f.id_finca
      WHERE f.id_empresa = ? AND a.eliminado = 0 AND f.eliminado = 0
      GROUP BY a.tipo, a.raza
      ORDER BY total DESC
    ''', [idEmpresa]);
    final propositoQuery = await db.rawQuery('''
      SELECT a.proposito, COUNT(*) AS total
      FROM animales a
      INNER JOIN fincas f ON a.id_finca = f.id_finca
      WHERE f.id_empresa = ?
        AND a.eliminado = 0
        AND f.eliminado = 0
      GROUP BY a.proposito
      ORDER BY total DESC
    ''', [idEmpresa]);

    final estadoQuery = await db.rawQuery('''
      SELECT a.estado, COUNT(*) AS total
      FROM animales a
      INNER JOIN fincas f ON a.id_finca = f.id_finca
      WHERE f.id_empresa = ?
        AND a.eliminado = 0
        AND f.eliminado = 0
      GROUP BY a.estado
      ORDER BY total DESC
    ''', [idEmpresa]);
    // =========================
    // 🔹 RESPUESTA
    // =========================
    return {
      "success": true,
      "resumen": resumenQuery.isNotEmpty ? resumenQuery.first : {},
      "fincas": fincasQuery,
      "distribucion": {
         "tipo": tipoQuery,
          "sexo": sexoQuery,
          "raza": razaQuery,
          "proposito": propositoQuery,
          "estado": estadoQuery,
      }
    };
  }

  static Future<Map<String, dynamic>> obtenerCambiosLocales() async {
    final db = await database;

    final fincas = await db.query(
      'fincas',
      where: 'estado_sincronizacion = 0',
    );

    final animales = await db.query(
      'animales',
      where: 'estado_sincronizacion = 0',
    );

    return {
      "fincas": fincas,
      "animales": animales,
      "ultima_sincronizacion": await obtenerUltimaSync(),
    };
  }

  static Future<String> obtenerUltimaSync() async {
    final db = await database;

    final result = await db.query(
      'config',
      where: 'clave = ?',
      whereArgs: ['ultima_sincronizacion'],
    );

    if (result.isNotEmpty) {
      return result.first['valor'] as String;
    }

    // valor por defecto (primera sync)
    return "2000-01-01 00:00:00";
  }

  static Future<void> depurarMostrarTodo() async {
    final db = await database;

    print("---  CONTENIDO DE LA BASE DE DATOS OFFLINE ---");

    // 1. Mostrar Usuarios
    List<Map<String, dynamic>> usuarios = await db.query('usuarios');
    print("\n👤 USUARIOS (${usuarios.length}):");
    for (var u in usuarios) print(u);

     // 1. Mostrar Empresas
    List<Map<String, dynamic>> empresas = await db.query('empresas');
    print("\n🏢 EMPRESAS (${empresas.length}):");
    for (var e in empresas) print(e);

    // 2. Mostrar Fincas
    List<Map<String, dynamic>> fincas = await db.query('fincas');
    print("\n🏡 FINCAS (${fincas.length}):");
    for (var f in fincas) print(f);

    // 3. Mostrar Animales
    List<Map<String, dynamic>> animales = await db.query('animales');
    print("\n🐄 ANIMALES (${animales.length}):");
    for (var a in animales) print(a);

    print("\n-------------------------------------------");
  }
}