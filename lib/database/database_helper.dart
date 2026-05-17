import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/trilho.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('geotrail.db');
    return _database!;
  }
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 7) {
          try {
            await db.execute('ALTER TABLE trilho ADD COLUMN rota_predefinida TEXT DEFAULT "[]"');
          } catch (e) {
            // Se a coluna já existir, ignora o erro
          }
        }

        if (oldVersion < 6) {
          await db.execute('DROP TABLE IF EXISTS pontos_rota');
          await db.execute('''
            CREATE TABLE pontos_rota (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              id_caminhada INTEGER,
              latitude REAL,
              longitude REAL,
              timestamp TEXT,
              FOREIGN KEY (id_caminhada) REFERENCES caminhada(id_caminhada)
            )
          ''');
        }

        if (oldVersion < 5) {
          await db.delete('trilho');
        }
      },
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
        desnivel REAL,
        imagem BLOB,
        rota_predefinida TEXT DEFAULT "[]"
      );
    ''');

    // A BASE DE DADOS AGORA FICA LIMPA NO ARRANQUE, SEM TRILHOS FALSOS

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

    await db.execute('''
      CREATE TABLE pontos_rota (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_caminhada INTEGER,
        latitude REAL,
        longitude REAL,
        timestamp TEXT,
        FOREIGN KEY (id_caminhada) REFERENCES caminhada(id_caminhada)
      )
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

  // ---------------- ROTAS ----------------

  Future<int> insertPontoRota(Map<String, dynamic> ponto) async {
    final db = await database;
    return await db.insert('pontos_rota', ponto);
  }
  // permite-te reconstruir a rota para desenhar no mapa mais tarde
  Future<List<Map<String, dynamic>>> getRotaByCaminhada(int caminhadaId) async {
  final db = await database;
  return await db.query(
    'pontos_rota',
    where: 'id_caminhada = ?',
    whereArgs: [caminhadaId],
    orderBy: 'timestamp ASC',
  );
}

// ---------------- UTILIZADOR ----------------

  Future<Map<String, dynamic>?> getUtilizador() async {
    final db = await database;
    final result = await db.query('utilizador', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> createUtilizadorIfNeeded() async {
    final db = await database;
    final result = await db.query('utilizador', limit: 1);
    if (result.isEmpty) {
      await db.insert('utilizador', {
        'nome': 'Explorador',
        'peso': null,
        'altura': null,
        'contacto': null,
      });
    }
  }

  Future<void> updateUtilizador(Map<String, dynamic> data) async {
    final db = await database;
    await db.update('utilizador', data, where: 'id_utilizador = ?', whereArgs: [data['id_utilizador']]);
  }

  // ---------------- MÉTRICAS ----------------

  Future<Map<String, dynamic>> getMetricas() async {
    final db = await database;

    final countResult = await db.rawQuery('SELECT COUNT(*) as total FROM caminhada');
    final distResult = await db.rawQuery('SELECT SUM(distancia_total) as total FROM caminhada');
    final tempoResult = await db.rawQuery('SELECT SUM(duracao) as total FROM caminhada');
    final velResult = await db.rawQuery('SELECT AVG(velocidade_media) as media FROM caminhada');

    return {
      'total_caminhadas': countResult.first['total'] ?? 0,
      'distancia_total': (distResult.first['total'] as num?)?.toDouble() ?? 0.0,
      'tempo_total': (tempoResult.first['total'] as num?)?.toDouble() ?? 0.0,
      'velocidade_media': (velResult.first['media'] as num?)?.toDouble() ?? 0.0,
    };
  }

  Future<List<Trilho>> getTrilhos() async {
    final db = await database;
    final result = await db.query('trilho');
    return result.map((e) => Trilho.fromMap(e)).toList();
  }

  Future<void> insertOrUpdateTrilho(Trilho trilho) async {
    final db = await database;
    final result = await db.query('trilho', where: 'id_trilho = ?', whereArgs: [trilho.id]);
    
    if (result.isEmpty) {
      await db.insert('trilho', {
        'id_trilho': trilho.id,
        'nome': trilho.nome,
        'distancia': trilho.distancia,
        'dificuldade': trilho.dificuldade,
        'descricao': trilho.descricao,
        'coordenadas': trilho.coordenadas,
        'desnivel': trilho.desnivel,
        'imagem': trilho.imagem,
        'rota_predefinida': trilho.rotaPredefinida,
      });
    } else {
      await db.update('trilho', {
        'nome': trilho.nome,
        'distancia': trilho.distancia,
        'dificuldade': trilho.dificuldade,
        'descricao': trilho.descricao,
        'coordenadas': trilho.coordenadas,
        'desnivel': trilho.desnivel,
        'imagem': trilho.imagem,
        'rota_predefinida': trilho.rotaPredefinida,
      }, where: 'id_trilho = ?', whereArgs: [trilho.id]);
    }
  }

  Future<int> update(String table, Map<String, dynamic> values,
      {String? where, List<Object?>? whereArgs}) async {
    final db = await database;
    return await db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

}
