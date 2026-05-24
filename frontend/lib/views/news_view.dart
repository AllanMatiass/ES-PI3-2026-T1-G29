// Autor: Gemini CLI
import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/models/event.dart';
import 'package:frontend/services/event_service.dart';
import 'package:frontend/widgets/shimmer_placeholder.dart';
import 'package:frontend/widgets/states/empty_state_widget.dart';
import 'package:frontend/widgets/headers/home_header.dart';
import 'package:frontend/services/user_state.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/pages/news/news_detail_page.dart';
import 'package:intl/intl.dart';

class NewsView extends StatefulWidget {
  const NewsView({super.key});

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  final ScrollController _scrollController = ScrollController();
  final List<Event> _events = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _lastEventId;

  @override
  void initState() {
    super.initState();
    _loadMoreEvents();
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
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadMoreEvents(refresh: true),
                    child: _events.isEmpty && _isLoading
                        ? ListView.builder(
                            itemCount: 5,
                            padding: const EdgeInsets.all(16.0),
                            itemBuilder: (context, index) => const ShimmerPlaceholder(
                              height: 120,
                              borderRadius: 16,
                              margin: EdgeInsets.only(bottom: 16),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _events.length + (_hasMore ? 1 : 0),
                            padding: const EdgeInsets.all(16.0),
                            itemBuilder: (context, index) {
                              if (index == _events.length) {
                                if (_events.isEmpty && !_isLoading) {
                                  return const EmptyStateWidget(
                                    icon: Icons.newspaper,
                                    title: 'Nenhuma notícia no momento',
                                    message: 'Fique atento às atualizações do mercado!',
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
                              
                              final event = _events[index];
                              return _NewsCard(
                                event: event,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NewsDetailPage(event: event),
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
        color: isDark ? theme.colorScheme.surfaceVariant.withOpacity(0.15) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
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
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                    if (event.tags.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
