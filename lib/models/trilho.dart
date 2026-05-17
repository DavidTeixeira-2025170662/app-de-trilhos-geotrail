import 'dart:typed_data';


class Trilho {
  final int id;
  final String nome;
  final double distancia;
  final String dificuldade;
  final String descricao;
  final String coordenadas;
  final double desnivel;
  final Uint8List imagem;
  final String rotaPredefinida;

  Trilho({
    required this.id,
    required this.nome,
    required this.distancia,
    required this.dificuldade,
    required this.descricao,
    required this.coordenadas,
    required this.desnivel,
    required this.imagem,
    this.rotaPredefinida = '[]',
  });

  factory Trilho.fromMap(Map<String, dynamic> map) {
    return Trilho(
      id: map['id_trilho'],
      nome: map['nome'],
      distancia: map['distancia']?.toDouble() ?? 0.0,
      dificuldade: map['dificuldade'] ?? "",
      descricao: map['descricao'] ?? "",
      coordenadas: map['coordenadas'] ?? "",
      desnivel: map['desnivel']?.toDouble() ?? 0.0,
      imagem: map['imagem'] ?? _transparentPng,
      rotaPredefinida: map['rota_predefinida'] ?? '[]',
    );
  }

  static final Uint8List _transparentPng = Uint8List.fromList([
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
    0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0,
    0, 0, 11, 73, 68, 65, 84, 120, 156, 99, 96, 0, 2, 0, 0, 5, 0,
    1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
  ]);
}
