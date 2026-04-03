import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../settings/app_settings.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  Map<String, dynamic>? _utilizador;
  Map<String, dynamic> _metricas = {};
  bool _isLoading = true;
  bool _notificacoesAtivas = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await DatabaseHelper.instance.createUtilizadorIfNeeded();
    final user = await DatabaseHelper.instance.getUtilizador();
    final metricas = await DatabaseHelper.instance.getMetricas();
    setState(() {
      _utilizador = user;
      _metricas = metricas;
      _isLoading = false;
    });
  }

  String _formatarTempo(double segundos) {
    final h = (segundos / 3600).floor();
    final m = ((segundos % 3600) / 60).floor();
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String _getIniciais(String nome) {
    final partes = nome.trim().split(' ');
    if (partes.length >= 2) return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    return nome.isNotEmpty ? nome[0].toUpperCase() : '?';
  }

  void _abrirEdicaoPerfil() {
    if (_utilizador == null) return;

    final nomeCtrl = TextEditingController(text: _utilizador!['nome'] ?? '');
    final pesoCtrl = TextEditingController(
        text: _utilizador!['peso']?.toString() ?? '');
    final alturaCtrl = TextEditingController(
        text: _utilizador!['altura']?.toString() ?? '');
    final contactoCtrl =
        TextEditingController(text: _utilizador!['contacto'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Editar Perfil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campoEdicao(nomeCtrl, 'Nome', Icons.person_outline),
              const SizedBox(height: 12),
              _campoEdicao(pesoCtrl, 'Peso (kg)', Icons.monitor_weight_outlined,
                  isNumber: true),
              const SizedBox(height: 12),
              _campoEdicao(alturaCtrl, 'Altura (cm)', Icons.height,
                  isNumber: true),
              const SizedBox(height: 12),
              _campoEdicao(
                  contactoCtrl, 'Contacto (email/telef.)', Icons.contact_phone_outlined),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final updated = {
                'id_utilizador': _utilizador!['id_utilizador'],
                'nome': nomeCtrl.text.trim(),
                'peso': double.tryParse(pesoCtrl.text),
                'altura': double.tryParse(alturaCtrl.text),
                'contacto': contactoCtrl.text.trim(),
              };
              await DatabaseHelper.instance.updateUtilizador(updated);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Widget _campoEdicao(TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.deepPurpleAccent),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurpleAccent),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  void _confirmarApagarDados() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Apagar todos os dados',
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text(
          'Esta ação irá eliminar permanentemente todas as caminhadas, favoritos e métricas. Tens a certeza?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final db = await DatabaseHelper.instance.database;
              await db.delete('caminhada');
              await db.delete('favorito');
              await db.delete('pontos_rota');
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent));
    }

    final nome = _utilizador?['nome'] ?? 'Explorador';
    final peso = _utilizador?['peso'];
    final altura = _utilizador?['altura'];
    final contacto = _utilizador?['contacto'];

    return Scaffold(
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          // --- App Bar com avatar ---
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF121212),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A1B9A), Color(0xFF121212)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      // Avatar
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurpleAccent.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _getIniciais(nome),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nome,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (contacto != null && contacto.toString().isNotEmpty)
                        Text(
                          contacto,
                          style: const TextStyle(fontSize: 13, color: Colors.white60),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
                tooltip: 'Editar Perfil',
                onPressed: _abrirEdicaoPerfil,
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // --- Dados Físicos ---
                  if (peso != null || altura != null) ...[
                    Row(
                      children: [
                        if (peso != null)
                          _dadoFisico('${peso.toStringAsFixed(1)} kg', 'Peso',
                              Icons.monitor_weight_outlined),
                        if (peso != null && altura != null) const SizedBox(width: 16),
                        if (altura != null)
                          _dadoFisico('${altura.toStringAsFixed(0)} cm', 'Altura',
                              Icons.height),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],

                  // --- Métricas ---
                  const Text(
                    'As tuas estatísticas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.4,
                    children: [
                      _metricaCard(
                        '${(_metricas['total_caminhadas'] as int?) ?? 0}',
                        'Caminhadas',
                        Icons.hiking_rounded,
                        Colors.deepPurpleAccent,
                      ),
                      _metricaCard(
                        '${((_metricas['distancia_total'] as double?) ?? 0.0).toStringAsFixed(1)} km',
                        'Distância',
                        Icons.route_rounded,
                        const Color(0xFF26A69A),
                      ),
                      _metricaCard(
                        _formatarTempo(((_metricas['tempo_total'] as double?) ?? 0.0)),
                        'Tempo Total',
                        Icons.timer_outlined,
                        const Color(0xFFFF9800),
                      ),
                      _metricaCard(
                        '${((_metricas['velocidade_media'] as double?) ?? 0.0).toStringAsFixed(1)} km/h',
                        'Vel. Média',
                        Icons.speed_rounded,
                        const Color(0xFF5C6BC0),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // --- Aparência ---
                  const Text(
                    'Aparência',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Toggle Modo Escuro / Claro
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: AppSettings.themeMode,
                          builder: (_, mode, _) => SwitchListTile(
                            value: mode == ThemeMode.dark,
                            onChanged: (isDark) {
                              AppSettings.themeMode.value =
                                  isDark ? ThemeMode.dark : ThemeMode.light;
                            },
                            activeThumbColor: Theme.of(context).colorScheme.primary,
                            secondary: const Icon(Icons.dark_mode_outlined,
                                color: Colors.white70),
                            title: const Text('Modo Escuro',
                                style: TextStyle(color: Colors.white)),
                            subtitle: const Text('Alterna entre tema claro e escuro',
                                style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ),
                        ),
                        const Divider(color: Colors.white12, height: 0, indent: 18, endIndent: 18),
                        // Seletor de Cor de Destaque
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Cor de destaque',
                                  style: TextStyle(color: Colors.white, fontSize: 15)),
                              const SizedBox(height: 4),
                              const Text('Define a cor principal dos ícones e botões',
                                  style: TextStyle(color: Colors.white54, fontSize: 12)),
                              const SizedBox(height: 14),
                              ValueListenableBuilder<Color>(
                                valueListenable: AppSettings.accentColor,
                                builder: (_, selectedColor, _) {
                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 10,
                                    children: AppSettings.paletas.map((paleta) {
                                      final isSelected = selectedColor == paleta.cor;
                                      return GestureDetector(
                                        onTap: () => AppSettings.accentColor.value = paleta.cor,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: paleta.cor,
                                            shape: BoxShape.circle,
                                            border: isSelected
                                                ? Border.all(color: Colors.white, width: 3)
                                                : null,
                                            boxShadow: isSelected
                                                ? [BoxShadow(
                                                    color: paleta.cor.withOpacity(0.6),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  )]
                                                : null,
                                          ),
                                          child: isSelected
                                              ? const Icon(Icons.check,
                                                  color: Colors.white, size: 20)
                                              : null,
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Configurações ---
                  const Text(
                    'Configurações',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        // Notificações
                        SwitchListTile(
                          value: _notificacoesAtivas,
                          onChanged: (v) => setState(() => _notificacoesAtivas = v),
                          activeThumbColor: Colors.deepPurpleAccent,
                          secondary: const Icon(Icons.notifications_outlined,
                              color: Colors.deepPurpleAccent),
                          title: const Text('Notificações',
                              style: TextStyle(color: Colors.white)),
                          subtitle: const Text('Receber alertas de atividade',
                              style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ),
                        const Divider(color: Colors.white12, height: 0, indent: 18, endIndent: 18),
                        // Versão
                        ListTile(
                          leading: const Icon(Icons.info_outline, color: Colors.white38),
                          title: const Text('Versão da App',
                              style: TextStyle(color: Colors.white)),
                          trailing: const Text('1.0.0',
                              style: TextStyle(color: Colors.white38, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Apagar dados (botão perigoso)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_forever_rounded,
                          color: Colors.redAccent),
                      label: const Text('Apagar todos os dados',
                          style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _confirmarApagarDados,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dadoFisico(String valor, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurpleAccent, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                Text(label,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricaCard(
      String valor, String label, IconData icon, Color cor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cor.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: cor, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(valor,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cor)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }
}
