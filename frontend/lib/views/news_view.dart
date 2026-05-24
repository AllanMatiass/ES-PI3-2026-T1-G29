// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/services/event_service.dart';
import 'package:frontend/services/startup_service.dart';
import 'package:frontend/models/startup.dart';
import 'package:frontend/widgets/shimmer_placeholder.dart';
import 'package:frontend/widgets/placeholders/empty_state_widget.dart';
import 'package:frontend/widgets/headers/home_header.dart';
import 'package:frontend/states/user_state.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/pages/news/news_detail_page.dart';
import 'package:frontend/widgets/tiles/sentiment_badge.dart';
import 'package:intl/intl.dart';

class NewsView extends StatefulWidget {
  final String? initialStartupId;
  const NewsView({super.key, this.initialStartupId});

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  final ScrollController _scrollController = ScrollController();
  final List<Event> _events = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _lastEventId;

  // Filtros
  String _searchTitle = "";
  String? _selectedStartupId;
  List<StartupListItem> _startups = [];

  @override
  void initState() {
    super.initState();
    _selectedStartupId = widget.initialStartupId;
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreEvents();
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadMoreEvents(refresh: true), _loadStartups()]);
  }

  Future<void> _loadStartups() async {
    final result = await StartupService.listStartups();
    if (result.success && mounted) {
      setState(() {
        _startups = result.data ?? [];
      });
    }
  }

  Future<void> _loadMoreEvents({bool refresh = false}) async {
    if (_isLoading || (!_hasMore && !refresh)) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        if (refresh) {
          _events.clear();
          _lastEventId = null;
          _hasMore = true;
        }
      });
    }

    final result = await EventService.listEvents(
      limit: 10,
      lastEventId: _lastEventId,
    );

    if (mounted) {
      if (result.success) {
        final List<Event> newEvents = result.data!.events;
        final String? lastId = result.data!.lastEventId;

        setState(() {
          _events.addAll(newEvents);
          _lastEventId = lastId;
          _isLoading = false;
          if (newEvents.length < 10 || lastId == null) {
            _hasMore = false;
          }
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Event> get _filteredEvents {
    return _events.where((event) {
      final matchesTitle = event.title.toLowerCase().contains(
        _searchTitle.toLowerCase(),
      );
      final matchesStartup =
          _selectedStartupId == null || event.startupId == _selectedStartupId;
      return matchesTitle && matchesStartup;
    }).toList();
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: AppHeader(
                    title: 'Notícias',
                    userData: userData,
                    isDark: isDark,
                  ),
                ),
                _buildFilters(theme, isDark),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadMoreEvents(refresh: true),
                    child: _events.isEmpty && _isLoading
                        ? ListView.builder(
                            itemCount: 5,
                            padding: const EdgeInsets.all(16.0),
                            itemBuilder: (context, index) =>
                                const ShimmerPlaceholder(
                                  height: 120,
                                  borderRadius: 16,
                                  margin: EdgeInsets.only(bottom: 16),
                                ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount:
                                _filteredEvents.length + (_hasMore ? 1 : 0),
                            padding: const EdgeInsets.all(16.0),
                            itemBuilder: (context, index) {
                              if (index == _filteredEvents.length) {
                                if (_filteredEvents.isEmpty && !_isLoading) {
                                  return const EmptyStateWidget(
                                    icon: Icons.newspaper,
                                    title: 'Nenhuma notícia no momento',
                                    message: 'Tente ajustar seus filtros!',
                                  );
                                }
                                return _hasMore
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    : const SizedBox(height: 80);
                              }

                              final event = _filteredEvents[index];
                              return _NewsCard(
                                event: event,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          NewsDetailPage(event: event),
                                    ),
                                  );
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

  Widget _buildFilters(ThemeData theme, bool isDark) {
    String selectedStartupName = 'Todas as Startups';

    if (_selectedStartupId != null) {
      if (_startups.isEmpty) {
        selectedStartupName = 'Carregando...';
      } else {
        final startup = _startups.cast<StartupListItem?>().firstWhere(
          (s) => s?.id == _selectedStartupId,
          orElse: () => null,
        );
        selectedStartupName = startup?.name ?? 'Startup Selecionada';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchTitle = value),
            decoration: InputDecoration(
              hintText: 'Buscar por título...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey[200],
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showStartupFilterModal(context, theme, isDark),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 20,
                    color: _selectedStartupId != null
                        ? AppColors.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedStartupName,
                      style: TextStyle(
                        color: _selectedStartupId != null
                            ? AppColors.primary
                            : theme.colorScheme.onSurface,
                        fontWeight: _selectedStartupId != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStartupFilterModal(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filtrar por Startup',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.business_center_outlined),
                      title: const Text('Todas as Startups'),
                      trailing: _selectedStartupId == null
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () {
                        setState(() => _selectedStartupId = null);
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(height: 1),
                    ..._startups.map(
                      (startup) => ListTile(
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(
                            Icons.business,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(startup.name),
                        trailing: _selectedStartupId == startup.id
                            ? const Icon(Icons.check, color: AppColors.primary)
                            : null,
                        onTap: () {
                          setState(() => _selectedStartupId = startup.id);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _NewsCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(event.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceVariant.withOpacity(0.15)
            : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.1))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: isDark ? 4 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        SentimentBadge(
                          sentiment: event.sentiment,
                          compact: true,
                        ),
                        if (event.tags.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event.tags.first.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  event.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Ler mais',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
