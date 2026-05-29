// Autores:
// Allan Giovanni Matias Paes - 25008211
// Pedro Vinicius Romanato - 25004075
import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/services/startup_service.dart';
import 'package:frontend/models/startup.dart';
import 'package:frontend/widgets/placeholders/error_state_widget.dart';
import 'package:shimmer/shimmer.dart';
import '../../widgets/cards/startup_card.dart';

import '../../widgets/headers/home_header.dart';
import '../../states/user_state.dart';
import '../../models/user.dart';

/// Página que exibe o catálogo de startups disponíveis para investimento,
/// com suporte a busca textual e filtros por estágio.
class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  // Future que armazena a resposta da API para evitar chamadas redundantes no build
  late Future<ApiResponse<List<StartupListItem>>> _startupsFuture;
  
  // Estados de filtro
  String _searchQuery = ""; // Query de busca textual
  StartupStage? _selectedStage; // Filtro por estágio (Todas, Novas, Expansão, etc.)

  @override
  void initState() {
    super.initState();
    _loadStartups(); // Carregamento inicial ao abrir a página
  }

  /// Inicializa ou reinicializa a busca de startups no backend
  void _loadStartups() {
    setState(() {
      _startupsFuture = StartupService.listStartups();
    });
  }

  /// Gerencia a atualização da lista via "pull-to-refresh"
  Future<void> _handleRefresh() async {
    _loadStartups();
    await _startupsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Escuta mudanças no estado do usuário para atualizar o cabeçalho (ex: saldo)
    return ValueListenableBuilder<UserProfile?>(
      valueListenable: UserState.userNotifier,
      builder: (context, userData, _) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Cabeçalho personalizado com informações do usuário
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: AppHeader(
                    title: 'Investir',
                    userData: userData,
                    isDark: isDark,
                  ),
                ),
                
                // Barra de Busca e Filtros Rápidos
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Buscar startups...',
                      hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                
                // Seletor Horizontal de Estágios (Filter Chips)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      _buildFilterChip(null, 'Todas'),
                      const SizedBox(width: 8),
                      _buildFilterChip(StartupStage.nova, 'Novas'),
                      const SizedBox(width: 8),
                      _buildFilterChip(StartupStage.em_operacao, 'Em Operação'),
                      const SizedBox(width: 8),
                      _buildFilterChip(StartupStage.em_expansao, 'Em Expansão'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Lista Principal de Startups com FutureBuilder
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: FutureBuilder<ApiResponse<List<StartupListItem>>>(
                      future: _startupsFuture,
                      builder: (context, snapshot) {
                        // Estado de Carregamento (Skeleton Shimmer)
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildSkeletonLoading();
                        }
                        
                        // Tratamento de Erro de Rede ou Conexão
                        if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error.toString());
                        }
                        
                        if (!snapshot.hasData) {
                          return _buildErrorState('Nenhum dado recebido');
                        }

                        final response = snapshot.data!;

                        if (!response.success) {
                          return _buildErrorState(response.message ?? 'Erro desconhecido');
                        }

                        var startups = response.data!;

                        // Verificação de Lista Vazia Geral
                        if (startups.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: Center(child: Text('Nenhuma startup encontrada.', style: TextStyle(color: theme.colorScheme.onSurface))),
                              ),
                            ],
                          );
                        }

                        // Aplicação de filtros locais (Busca e Estágio)
                        if (_searchQuery.isNotEmpty) {
                          startups = startups
                              .where((s) =>
                                  s.name.toLowerCase().contains(_searchQuery) ||
                                  s.shortDescription.toLowerCase().contains(_searchQuery))
                              .toList();
                        }
                        if (_selectedStage != null) {
                          startups = startups.where((s) => s.stage == _selectedStage).toList();
                        }

                        // Verificação de Lista Vazia após filtragem
                        if (startups.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.6,
                                child: Center(child: Text('Nenhuma startup corresponde aos filtros.', style: TextStyle(color: theme.colorScheme.onSurface))),
                              ),
                            ],
                          );
                        }

                        // Renderização da lista de cards de startups
                        return ListView.builder(
                          itemCount: startups.length,
                          padding: const EdgeInsets.all(16.0),
                          itemBuilder: (context, index) {
                            final startup = startups[index];
                            return StartupCard(startup: startup);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Constrói um chip de filtro que atualiza o estado da listagem
  Widget _buildFilterChip(StartupStage? stage, String label) {
    final theme = Theme.of(context);
    bool isSelected = _selectedStage == stage;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStage = selected ? stage : null;
        });
      },

      selectedColor: AppColors.primary.withOpacity(0.2),

      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),

      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),

      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.transparent,
      ),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  /// Exibe cards de carregamento estilizados (Shimmer) enquanto os dados não chegam
  Widget _buildSkeletonLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.builder(
      itemCount: 3,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
          child: Container(
            height: 250,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      },
    );
  }

  /// Exibe uma interface de erro amigável com botão de re-tentativa
  Widget _buildErrorState(String error) {
    return ErrorStateWidget(onRetry: _loadStartups);
  }
}
