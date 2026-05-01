import 'package:flutter/material.dart';
import '../models/startup.dart';

class FAQPage extends StatelessWidget {
  final List<Question> questions;
  final String startupName;
  final String logoUrl;

  const FAQPage({
    super.key,
    required this.questions,
    required this.startupName,
    required this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('FAQ da Startup',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
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
                    logoUrl,
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.business, size: 60, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        startupName,
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
            child: questions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.question_answer_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text('Nenhuma pergunta disponível no momento.',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final q = questions[index];
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
                                  child: Icon(Icons.monetization_on,
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
                              'Enviada em ${q.createdAt.day.toString().padLeft(2, '0')}/${q.createdAt.month.toString().padLeft(2, '0')}/${q.createdAt.year}',
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
                              ...q.answers.map((a) => Padding(
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
                                          'Respondida em ${a.answeredAt.day.toString().padLeft(2, '0')}/${a.answeredAt.month.toString().padLeft(2, '0')}/${a.answeredAt.year}',
                                          style: const TextStyle(
                                              fontSize: 11, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  )),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
