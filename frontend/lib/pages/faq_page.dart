import 'package:flutter/material.dart';
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
    try {
      final startupData =
          await StartupService.getStartupDetails(widget.startupId);
      setState(() {
        _questions = startupData.questions;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar FAQ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  Future<void> _submitQuestion() async {
    final text = _questionController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, digite sua pergunta.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final visibility = _isPrivate ? 'privada' : 'publica';

      final newQuestion = await StartupService.createQuestion(
        startupId: widget.startupId,
        text: text,
        visibility: visibility,
      );

      setState(() {
        _questions.insert(0, newQuestion);
        _questionController.clear();
        _isPrivate = false;
      });

      if (mounted) {
        Navigator.pop(context); // Fecha o bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pergunta enviada com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar pergunta: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddQuestionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                  const Text(
                    'Fazer uma pergunta',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _questionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Digite sua pergunta aqui...',
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
                        const Text('Pergunta privada?'),
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
                    const Text(
                      'Sua pergunta será pública (apenas investidores podem enviar perguntas privadas).',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 15,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 150,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('FAQ da Startup',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
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
                color: Colors.white,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.logoUrl,
                        height: 60,
                        width: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.business,
                            size: 60, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.startupName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          const Text(
                            'Perguntas Frequentes',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
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
                                          size: 64, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      const Text(
                                          'Nenhuma pergunta disponível no momento.',
                                          style: TextStyle(
                                              color: Colors.grey,
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
                                  color: Colors.white,
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
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Enviada em ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                  children: [
                                    const Divider(height: 1),
                                    if (q.answers.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.all(20.0),
                                        child: Text(
                                          'Esta pergunta ainda não foi respondida pela startup.',
                                          style: TextStyle(
                                              color: Colors.grey,
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
                                                style: const TextStyle(
                                                    color: Colors.black87,
                                                    height: 1.5),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Respondida em ${ansDate.day.toString().padLeft(2, '0')}/${ansDate.month.toString().padLeft(2, '0')}/${ansDate.year}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey),
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
