import 'package:flutter/material.dart';

/// Configurações globais da app, acessíveis a partir de qualquer ecrã.
class AppSettings {
  AppSettings._();

  /// Modo de tema: escuro ou claro
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.dark);

  /// Cor de destaque (accent color)
  static final accentColor = ValueNotifier<Color>(Colors.deepPurpleAccent);

  /// Paletas disponíveis para o utilizador escolher
  static const List<({Color cor, String nome})> paletas = [
    (cor: Colors.deepPurpleAccent, nome: 'Roxo'),
    (cor: Color(0xFF26A69A),       nome: 'Teal'),
    (cor: Color(0xFFFF9800),       nome: 'Laranja'),
    (cor: Color(0xFF5C6BC0),       nome: 'Azul'),
    (cor: Color(0xFFE53935),       nome: 'Vermelho'),
    (cor: Color(0xFF43A047),       nome: 'Verde'),
  ];
}