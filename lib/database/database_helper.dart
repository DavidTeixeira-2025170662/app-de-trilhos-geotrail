import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';



class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();
  // garante que a base de dados abre apenas uma vez
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('geotrail.db');
    return _database!;
  }
  // cria o ficheiro da base de dados no telemóvel
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }
  // cria as tabelas da tua app
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE utilizador (
        id_utilizador INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        peso REAL,
        altura REAL,
        contacto TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE trilho (
        id_trilho INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        distancia REAL,
        dificuldade TEXT,
        descricao TEXT,
        coordenadas TEXT,
        desnivel REAL
      );
    ''');

    await db.execute('''
      CREATE TABLE caminhada (
        id_caminhada INTEGER PRIMARY KEY AUTOINCREMENT,
        id_trilho INTEGER NOT NULL,
        id_utilizador INTEGER NOT NULL,
        data TEXT,
        distancia_total REAL,
        velocidade_media REAL,
        rota TEXT,
        desnivel_acumulado REAL,
        duracao REAL,
        FOREIGN KEY (id_trilho) REFERENCES trilho(id_trilho),
        FOREIGN KEY (id_utilizador) REFERENCES utilizador(id_utilizador)
      );
    ''');

    await db.execute('''
      CREATE TABLE favorito (
        id_favorito INTEGER PRIMARY KEY AUTOINCREMENT,
        id_trilho INTEGER NOT NULL,
        id_utilizador INTEGER NOT NULL,
        data_adicionado TEXT,
        FOREIGN KEY (id_trilho) REFERENCES trilho(id_trilho),
        FOREIGN KEY (id_utilizador) REFERENCES utilizador(id_utilizador)
      );
    ''');

    await db.execute('''
      CREATE TABLE estatistica (
        id_estatistica INTEGER PRIMARY KEY AUTOINCREMENT,
        id_utilizador INTEGER NOT NULL,
        periodo TEXT,
        total_distancia REAL,
        total_tempo REAL,
        numero_caminhadas INTEGER,
        FOREIGN KEY (id_utilizador) REFERENCES utilizador(id_utilizador)
      );
    ''');
  }

  // ---------------- FAVORITOS ----------------

  Future<int> insertFavorito(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('favorito', row);
  }

  Future<List<Map<String, dynamic>>> getFavoritos() async {
    final db = await instance.database;
    return await db.query('favorito');
  }

  Future<int> deleteFavorito(int id) async {
    final db = await instance.database;
    return await db.delete('favorito', where: 'id_favorito = ?', whereArgs: [id]);
  }

  // ---------------- CAMINHADAS ----------------

Future<int> insertCaminhada(Map<String, dynamic> row) async {
  final db = await instance.database;
  return await db.insert('caminhada', row);
}

Future<List<Map<String, dynamic>>> getCaminhadas() async {
  final db = await instance.database;
  return await db.query('caminhada');
}


}
