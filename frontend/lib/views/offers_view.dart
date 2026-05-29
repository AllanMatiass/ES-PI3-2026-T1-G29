// Autor: Allan Giovanni Matias Paes - 25008211
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/models/offer.dart';
import 'package:frontend/services/offer_service.dart';
import 'package:frontend/pages/market/my_offers_page.dart';
import 'package:frontend/pages/market/buy_offer_page.dart';
import 'package:frontend/pages/market/create_offer_page.dart';
import 'package:frontend/widgets/modals/feedback_modal.dart';
import 'package:frontend/widgets/shimmer_placeholder.dart';
import 'package:frontend/widgets/market_filters.dart';
import 'package:frontend/widgets/cards/market_offer_card.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/widgets/placeholders/empty_state_widget.dart';

import '../widgets/headers/home_header.dart';
import '../states/user_state.dart';
import '../models/user.dart';

/// Visão que funciona como a vitrine (Order Book) do mercado secundário de tokens.
/// Exibe todas as ofertas abertas criadas por outros usuários (P2P), permitindo
/// filtragem por startup e preço, além de ser o ponto de entrada para criação de novas ofertas.
class OffersView extends StatefulWidget {
  const OffersView({super.key});

  @override
  State<OffersView> createState() => _OffersViewState();
}

class _OffersViewState extends State<OffersView> {
  // Controle de Paginação
  final ScrollController _scrollController = ScrollController();
  final List<Offer> _offers = []; // Lista em memória das ofertas carregadas
  bool _isLoading = false; 
  bool _hasMore = true; // Indica se há mais páginas no backend
  String? _lastOfferId; // Cursor para a busca da próxima página

  // Filtros Locais
  String _searchStartup = "";
  double? _maxPrice;
  final TextEditingController _priceController = TextEditingController();
  
  // UID do usuário atual (Usado para não exibir as próprias ofertas na vitrine de compra)
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadMoreOffers();
    _scrollController.addListener(_onScroll); // Ativa o Infinite Scroll
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// Monitora o scroll para carregar mais itens quando o usuário chegar 
  /// próximo ao final da lista (margem de 200px).
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreOffers();
    }
  }

  /// Busca mais ofertas no servidor, gerenciando o estado de carregamento e o cursor de paginação.
  Future<void> _loadMoreOffers({bool refresh = false}) async {
    // Evita requests simultâneos e bloqueia se já chegou ao fim
    if (_isLoading || (!_hasMore && !refresh)) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        // Zera o estado se for uma recarga manual (Pull-to-refresh)
        _offers.clear();
        _lastOfferId = null;
        _hasMore = true;
      }
    });

    // Busca um lote de 15 ofertas
    final result = await OfferService.getOffers(
      limit: 15,
      startAfter: _lastOfferId,
    );

    if (mounted) {
      if (result.success) {
        final List<Offer> newOffers = result.data?.offers ?? [];
        final String? lastId = result.data?.lastOfferId;

        setState(() {
          _offers.addAll(newOffers);
          _lastOfferId = lastId;
          _isLoading = false;
          // Se o backend retornou menos que o limite, significa que não há mais páginas
          if (newOffers.length < 15 || lastId == null) {
            _hasMore = false;
          }
        });
      } else {
        setState(() => _isLoading = false);
        FeedbackModal.show(
          context: context,
          title: 'Erro ao carregar',
          message: result.message ?? 'Erro ao carregar ofertas',
          type: FeedbackType.error,
        );
      }
    }
  }

  /// Filtra a lista de ofertas carregadas localmente em tempo real.
  /// Evita que o usuário perca tempo mandando requests para a API a cada letra digitada.
  List<Offer> get _filteredOffers {
    return _offers.where((offer) {
      // Regra de Negócio: O usuário não pode "comprar" a própria oferta.
      if (_currentUserId != null && offer.seller.id == _currentUserId) {
        return false;
      }

      final matchesStartup = offer.startupName
          .toLowerCase()
          .contains(_searchStartup.toLowerCase());
      
      // Converte o preço de centavos para reais para comparar com o input numérico do filtro
      final matchesPrice = _maxPrice == null || 
          (offer.tokenPriceCents / 100) <= _maxPrice!;
          
      return matchesStartup && matchesPrice;
    }).toList();
  }

  /// Intercepta o clique em "Comprar" em um card de oferta.
  /// Como uma oferta pode expirar no banco de dados enquanto o usuário apenas 
  /// olhava a lista, fazemos um check forçado (revalidação) antes de abrir a tela de pagamento.
  Future<void> _handleBuyOffer(Offer offer) async {
    // Exibe indicador de carregamento bloqueante para evitar multi-clicks
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    // Valida o status da oferta em tempo real
    final resultCheck = await OfferService.isOfferExpired(offerId: offer.id);

    if (mounted) {
      Navigator.of(context).pop(); // Fecha o indicador de carregamento
    }

    if (resultCheck.success) {
      if (resultCheck.data == true) {
        // A oferta expirou ou foi comprada por outro usuário nesse meio tempo
        if (mounted) {
          FeedbackModal.show(
            context: context,
            title: 'Oferta Expirada',
            message: 'Essa oferta acabou de expirar! Que tal conferir outras oportunidades no catálogo?',
            type: FeedbackType.info,
            onConfirm: () => _loadMoreOffers(refresh: true), // Atualiza a vitrine para remover a oferta "fantasma"
          );
        }
      } else {
        // A oferta está válida, direciona para o fluxo de pagamento
        if (mounted) {
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (context) => BuyOfferPage(offer: offer),
            ),
          );
          // Se a compra foi concluída com sucesso, recarrega o feed
          if (result == true) {
            _loadMoreOffers(refresh: true);
          }
        }
      }
    } else {
      if (mounted) {
        FeedbackModal.show(
          context: context,
          title: 'Erro ao Verificar',
          message: resultCheck.message ?? 'Não foi possível verificar o status da oferta',
          type: FeedbackType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ValueListenableBuilder<UserProfile?>(
      valueListenable: UserState.userNotifier,
      builder: (context, userData, _) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header sincronizado com o saldo do usuário (Estado Global)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: AppHeader(
                    title: 'Balcão',
                    userData: userData,
                    isDark: isDark,
                  ),
                ),
                
                // Filtros de busca (Nome e Preço Máximo)
                MarketFilters(
                  searchStartup: _searchStartup,
                  priceController: _priceController,
                  onSearchChanged: (value) => setState(() => _searchStartup = value),
                  onMaxPriceChanged: (value) {
                    setState(() {
                      String normalizedValue = value.replaceAll(',', '.');
                      _maxPrice = double.tryParse(normalizedValue);
                    });
                  },
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadMoreOffers(refresh: true),
                    child: _offers.isEmpty && _isLoading
                        ? ListView.builder( // Skeleton Loading State
                            itemCount: 5,
                            padding: const EdgeInsets.all(16.0),
                            itemBuilder: (context, index) => const ShimmerPlaceholder(
                              height: 150,
                              borderRadius: 16,
                              margin: EdgeInsets.only(bottom: 16),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            // +1 para o Card de atalho "Minhas Ofertas" no topo
                            itemCount: _filteredOffers.length + (_hasMore ? 1 : 0) + 1,
                            padding: const EdgeInsets.all(16.0),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _buildMyOffersShortcut(); // Injeta o banner gerencial como primeiro item
                              }
                              
                              final actualIndex = index - 1;

                              // Se for o último índice (após a lista e o banner) e não há mais dados, exibe lista vazia ou spinner
                              if (actualIndex == _filteredOffers.length) {
                                if (_filteredOffers.isEmpty && !_isLoading) {
                                  return const EmptyStateWidget(
                                    icon: Icons.local_offer_outlined,
                                    title: 'Nenhuma oferta encontrada',
                                    message: 'Que tal mudar seus filtros de busca?',
                                  );
                                }
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              
                              final offer = _filteredOffers[actualIndex];
                              return MarketOfferCard(
                                offer: offer,
                                onBuyPressed: () => _handleBuyOffer(offer),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          // CTA Principal: Botão flutuante (FAB) para publicar uma nova intenção de venda
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (context) => const CreateOfferPage()),
              );
              // Atualiza o mercado (order book) se o usuário publicou uma oferta com sucesso
              if (result == true) {
                _loadMoreOffers(refresh: true);
              }
            },
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add, color: AppColors.white),
          ),
        );
      },
    );
  }

  /// Banner promocional injetado como o primeiro item da lista, servindo como 
  /// atalho para a área restrita onde o usuário gerencia o que ele está vendendo.
  Widget _buildMyOffersShortcut() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MyOffersView()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_offer_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gerenciar Minhas Ofertas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Veja e edite seus tokens à venda',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
