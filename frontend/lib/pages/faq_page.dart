// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';
import 'package:frontend/widgets/feedback_modal.dart';
import '../models/startup.dart';
import '../services/startup_service.dart';

class FAQPage extends StatefulWidget {
  final List<Question> questions;
  final String startupName;
  final String logoUrl;
  final String startupId;
  final Access access;

  const FAQPage({
    super.key,
    required this.questions,
    required this.startupName,
    required this.logoUrl,
    required this.startupId,
    required this.access,
  });

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  late List<Question> _questions;
  final TextEditingController _questionController = TextEditingController();
  bool _isPrivate = false;
  bool _isLoading = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.questions);
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    final result = await StartupService.getStartupDetails(widget.startupId);
    if (mounted) {
      if (result.success) {
        setState(() {
          _questions = result.data!.questions;
        });
      } else {
        FeedbackModal.show(
          context: context,
          title: 'Erro ao atualizar',
          message: result.message ?? 'Não foi possível carregar as perguntas',
          type: FeedbackType.error,
        );
      }
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _submitQuestion() async {
    final text = _questionController.text.trim();
    if (text.isEmpty) {
      FeedbackModal.show(
        context: context,
        title: 'Campo Vazio',
        message: 'Por favor, digite sua pergunta.',
        type: FeedbackType.info,
      );
      return;
    }

    setState(() => _isLoading = true);
    final visibility = _isPrivate ? 'privada' : 'publica';

    final result = await StartupService.createQuestion(
      startupId: widget.startupId,
      text: text,
      visibility: visibility,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.success) {
        setState(() {
          _questions.insert(0, result.data!);
          _questionController.clear();
          _isPrivate = false;
        });
        Navigator.pop(context); // Fecha o bottom sheet
        FeedbackModal.show(
          context: context,
          title: 'Sucesso!',
          message: 'Sua pergunta foi enviada com sucesso.',
          type: FeedbackType.success,
        );
      } else {
        FeedbackModal.show(
          context: context,
          title: 'Erro ao enviar',
          message: result.message ?? 'Não foi possível enviar sua pergunta',
          type: FeedbackType.error,
        );
      }
    }
  }

  void _showAddQuestionSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Fazer uma pergunta',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _questionController,
                    maxLines: 3,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Digite sua pergunta aqui...',
                      hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (widget.access.isInvestor)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pergunta privada?', style: TextStyle(color: theme.colorScheme.onSurface)),
                        Switch(
                          value: _isPrivate,
                          activeThumbColor: const Color(0xFF00A84E),
                          onChanged: (value) {
                            setModalState(() => _isPrivate = value);
                            setState(() => _isPrivate = value);
                          },
                        ),
                      ],
                    )
                  else
                    Text(
                      'Sua pergunta será pública (apenas investidores podem enviar perguntas privadas).',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A84E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Enviar Pergunta',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonItem() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 15,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 150,
            height: 12,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text('FAQ da Startup',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: theme.colorScheme.onSurface)),
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddQuestionSheet,
          backgroundColor: const Color(0xFF00A84E),
          label: const Text('Fazer Pergunta'),
          icon: const Icon(Icons.add_comment_outlined),
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: const Color(0xFF00A84E),
          child: Column(
            children: [
              // Header com Logo e Nome
              Container(
                padding: const EdgeInsets.all(20),
                color: theme.colorScheme.surface,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.logoUrl,
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.business,
                            size: 60, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.startupName,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20, color: theme.colorScheme.onSurface),
                          ),
                          Text(
                            'Perguntas Frequentes',
                            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
              Expanded(
                child: _isRefreshing
                    ? ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: 5,
                        itemBuilder: (context, index) => _buildSkeletonItem(),
                      )
                    : _questions.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.5,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.question_answer_outlined,
                                          size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
                                      const SizedBox(height: 16),
                                      Text(
                                          'Nenhuma pergunta disponível no momento.',
                                          style: TextStyle(
                                              color: theme.colorScheme.onSurfaceVariant,
                                              fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: _questions.length,
                            itemBuilder: (context, index) {
                              final q = _questions[index];
                              final date = q.createdAt.toDateTime();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 15),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ExpansionTile(
                                  shape: const RoundedRectangleBorder(
                                      side: BorderSide.none),
                                  tilePadding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 8),
                                  title: Row(
                                    children: [
                                      if (q.visibility == 'privada')
                                        const Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Icon(Icons.lock_outline,
                                              color: Colors.amber, size: 20),
                                        ),
                                      Expanded(
                                        child: Text(
                                          q.text,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Enviada em ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                                      style: TextStyle(
                                          fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                  ),
                                  children: [
                                    Divider(height: 1, color: theme.dividerColor.withOpacity(0.1)),
                                    if (q.answers.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Text(
                                          'Esta pergunta ainda não foi respondida pela startup.',
                                          style: TextStyle(
                                              color: theme.colorScheme.onSurfaceVariant,
                                              fontStyle: FontStyle.italic),
                                        ),
                                      )
                                    else
                                      ...q.answers.map((a) {
                                        final ansDate =
                                            a.answeredAt.toDateTime();
                                        return Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Resposta da Startup:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF00A84E),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                a.answer,
                                                style: TextStyle(
                                                    color: theme.colorScheme.onSurface,
                                                    height: 1.5),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Respondida em ${ansDate.day.toString().padLeft(2, '0')}/${ansDate.month.toString().padLeft(2, '0')}/${ansDate.year}',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: theme.colorScheme.onSurfaceVariant),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
