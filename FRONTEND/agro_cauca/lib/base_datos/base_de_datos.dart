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

    //TABLA USUARIO
    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY,
        nombre TEXT,
        correo TEXT,
        clave TEXT
      )
    ''');

    // TABLA FINCAS
    await db.execute('''
      CREATE TABLE fincas (
        id_finca INTEGER PRIMARY KEY, 
        nombre TEXT,
        ubicacion TEXT,
        area REAL,
        usuario_id INTEGER,

        total_animales INTEGER DEFAULT 0,

        fecha_creacion TEXT,
        fecha_actualizacion TEXT,

        sync_status INTEGER, -- 0 pendiente, 1 sincronizado
        eliminado INTEGER DEFAULT 0 -- 🔥 para borrado offline
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
        fecha_actualizacion TEXT,
        sync_status INTEGER DEFAULT 0,
        eliminado INTEGER DEFAULT 0,

        FOREIGN KEY (id_finca) REFERENCES fincas (id)
      )
    ''');
  }


  static Future<Map<String, dynamic>?> inicioSesionUsuario(String correo, String clave) async {
    final db = await database;

    final res = await db.query(
      'usuarios',
      where: 'TRIM(correo) = ? AND TRIM(clave) = ?',
      whereArgs: [correo.trim(), clave.trim()],
    );


    if (res.isNotEmpty) {
      return res.first;
    }
    return null;
  }

  static Future<int> ingresarFinca(Map<String, dynamic> finca) async {
    final db = await database;
    
    // Creamos una copia para no modificar el objeto original y asegurar campos offline
    Map<String, dynamic> datosFinca = Map.from(finca);
    datosFinca['sync_status'] = 0; // 0 = Pendiente de subir al servidor
    datosFinca['eliminado'] = 0;
    datosFinca['fecha_creacion'] = DateTime.now().toString();
    datosFinca['fecha_actualizacion'] = DateTime.now().toString();

    return await db.insert(
      'fincas', 
      datosFinca, 
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  // 🔹 Ingresar Animal Offline
  static Future<int> ingresarAnimal(Map<String, dynamic> animal) async {
    final db = await database;

    Map<String, dynamic> datosAnimal = Map.from(animal);
    datosAnimal['sync_status'] = 0; // Pendiente
    datosAnimal['eliminado'] = 0;
    datosAnimal['fecha_creacion'] = DateTime.now().toString();
    datosAnimal['fecha_actualizacion'] = DateTime.now().toString();

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
        'sync_status': 0, // Pendiente de actualizar en la nube
        'fecha_actualizacion': DateTime.now().toString(),
      },
      where: 'id_finca = ?',
      whereArgs: [finca['id_finca']],
    );
  }

  static Future<int> eliminarFincaLogico(int idFinca) async {
    final db = await database;
    return await db.update(
      'fincas',
      {
        'eliminado': 1,
        'sync_status': 0,
        'fecha_actualizacion': DateTime.now().toString(),
      },
      where: 'id_finca = ?',
      whereArgs: [idFinca],
    );
  }

  static Future<int> actualizarAnimal(Map<String, dynamic> animal) async {
    final db = await database;
    return await db.update(
      'animales',
      {
        ...animal,
        'sync_status': 0,
        'fecha_actualizacion': DateTime.now().toString(),
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
        'sync_status': 0,
        'fecha_actualizacion': DateTime.now().toString(),
      },
      where: 'id_animal = ?',
      whereArgs: [idAnimal],
    );
  }

  static Future<List<Map<String, dynamic>>> obtenerFincas(int usuarioId) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.query(
      'fincas',
      where: 'usuario_id = ? AND eliminado = 0',
      whereArgs: [usuarioId],
      orderBy: 'fecha_creacion DESC',
    );

    return result;
  }

  static Future<List<Map<String, dynamic>>> obtenerAnimales(int fincaId) async {
    final db = await database;

    return await db.query(
      'animales',
      where: 'finca_id = ? AND eliminado = 0',
      whereArgs: [fincaId],
    );
  }

  static Future<List<Map<String, dynamic>>> obtenerPendientes(String tabla) async {
    final db = await database;

    return await db.query(
      tabla,
      where: 'sync_status = ?',
      whereArgs: [0],
    );
  }

  static Future<int> marcarSincronizado(String tabla, int id) async {
    final db = await database;

    return await db.update(
      tabla,
      {'sync_status': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Función para limpiar y cargar datos nuevos desde el servidor
  static Future<void> cargarDatosServidor(Map<String, dynamic> data) async {
    final db = await database;

    Batch batch = db.batch();

    if (data['usuario'] != null) {
      var u = data['usuario'];

      batch.insert(
        'usuarios',
        {
          'id': int.parse(u['id_usuario'].toString()),
          'nombre': u['nombre'].toString(),
          'correo': u['correo'].toString(),
          'clave': u['contrasena']?.toString() ?? '',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }


    // 
    if (data['fincas'] != null) {
      for (var f in data['fincas']) {
        batch.insert(
          'fincas',
          {
            'id_finca': int.parse(f['id_finca'].toString()),
            'nombre': f['nombre'].toString(),
            'ubicacion': f['ubicacion'].toString(),
            'area': double.tryParse(f['area'].toString()) ?? 0,
            'usuario_id': int.parse(f['id_usuario'].toString()),
            'total_animales': int.tryParse(f['total_animales']?.toString() ?? "0") ?? 0,

            'fecha_creacion': f['fecha_creacion'].toString(),
            'fecha_actualizacion': f['actualizado_fecha']?.toString() ?? f['fecha_creacion'].toString(),

            'sync_status': 1, // viene del servidor → ya sincronizado
            'eliminado': 0
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    // 🔹 ANIMALES
    if (data['animales'] != null) {
      for (var a in data['animales']) {
        batch.insert(
          'animales',
          {
            'id_animal': int.parse(a['id_animal'].toString()),
            'identificador': a['identificador'].toString(),
            'tipo': a['tipo'].toString(),
            'raza': a['raza'].toString(),
            'edad': int.tryParse(a['edad']?.toString() ?? "0") ?? 0,
            'peso': double.tryParse(a['peso'].toString()) ?? 0,

            'finca_id': int.parse(a['id_finca'].toString()),

            'fecha_creacion': a['fecha_creacion'].toString(),
            'fecha_actualizacion': a['actualizado_fecha']?.toString() ?? a['fecha_creacion'].toString(),

            'sync_status': 1,
            'eliminado': 0
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await batch.commit(noResult: true);
  }

  static Future<void> depurarMostrarTodo() async {
    final db = await database;

    print("---  CONTENIDO DE LA BASE DE DATOS OFFLINE ---");

    // 1. Mostrar Usuarios
    List<Map<String, dynamic>> usuarios = await db.query('usuarios');
    print("\n👤 USUARIOS (${usuarios.length}):");
    for (var u in usuarios) print(u);

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