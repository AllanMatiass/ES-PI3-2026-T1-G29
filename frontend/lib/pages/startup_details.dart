//Autor: Pedro Vinicius Romanato & Allan Giovanni Matias Paes

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/startup.dart';

import '../services/startup_service.dart';


class StartupDetailsPage extends StatefulWidget {
  final String startupId;

  const StartupDetailsPage({super.key, required this.startupId});

  @override
  State<StartupDetailsPage> createState() => _StartupDetailsPageState();
}

class _StartupDetailsPageState extends State<StartupDetailsPage> {
  late Future<StartupData> startupDetails;

  @override
  void initState() {
    super.initState();
    setState(() {
      startupDetails = fetchStartupDetails(widget.startupId);
    });
  }
  Future<StartupData> fetchStartupDetails(String id) async {
    return await StartupService.getStartupDetails(id);
  }

  String gerarIniciais(String nome) {
    List<String> partes = nome.trim().split(" ");
    if (partes.length >= 2) {
      return (partes[0][0] + partes[1][0]).toUpperCase();
    }
    return partes[0].isNotEmpty ? partes[0][0].toUpperCase() : "?";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StartupData>(
      future: startupDetails,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('Erro: ${snapshot.error}')));
        }

        final data = snapshot.data!;

        final double progressoBarra = data.totalTokens > 0
            ? (data.circulatingTokens / data.totalTokens).clamp(0.0, 1.0)
            : 0.0;

        final double percentualVendido = progressoBarra * 100;

        Color corRisco = const Color.fromARGB(255, 255, 102, 0);
        if (data.riskLabel.toLowerCase().contains("baixo")) corRisco = Colors.green;
        if (data.riskLabel.toLowerCase().contains("alto")) corRisco = Colors.red;

        return Scaffold(
          appBar: FixedHeader(
            nome: data.name,
            segmento: data.segment,
            logoPath: data.logoUrl,
            resumo: data.shortDescription,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card de Retorno
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: data.expectedReturn >= 0
                          ? const Color(0xFF25A830)
                          : Colors.redAccent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Retorno esperado',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                        Row(
                          children: [
                            Icon(
                                data.expectedReturn >= 0
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                color: Colors.white,
                                size: 30),
                            const SizedBox(width: 8),
                            Text('${data.expectedReturn}x',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 30)),
                          ],
                        ),
                        const Text('ao ano',
                            style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Risco e Prazo
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Risco',
                                  style: TextStyle(
                                      color: Color.fromARGB(179, 77, 75, 75),
                                      fontSize: 14)),
                              Text(
                                data.riskLabel.replaceAll("Risco ", ""),
                                style: TextStyle(
                                    color: corRisco,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Prazo',
                                  style: TextStyle(
                                      color: Color.fromARGB(179, 77, 75, 75),
                                      fontSize: 14)),
                              Text(
                                data.horizon.split(" ").first,
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tokens em circulação',
                            style: TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progressoBarra,
                          backgroundColor: Colors.grey[200],
                          color: const Color(0xFF00A84E),
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${data.totalTokens} emitidos',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              '${percentualVendido.toStringAsFixed(1)}% vendidos',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  CardSobreStartup(descricao: data.longDescription),
                  const SizedBox(height: 15),

                  // Tags
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15)),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: data.tags.map((tag) => _buildTag(tag)).toList(),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Sócios
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sócios',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(height: 15),
                        ...data.founders.map((founder) => Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: _buildSocioRow(
                                gerarIniciais(founder.name),
                                founder.name,
                                founder.role,
                                "${founder.equityPercent}%",
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A84E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('Investir agora',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class FixedHeader extends StatelessWidget implements PreferredSizeWidget {
  final String nome;
  final String segmento;
  final String logoPath;
  final String resumo;

  const FixedHeader(
      {super.key,
      required this.nome,
      required this.segmento,
      required this.logoPath,
      required this.resumo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 20,
          right: 20,
          bottom: 15),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  logoPath,
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.business, size: 50, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nome,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        segmento,
                        style: const TextStyle(
                          color: Color(0xFF00A84E),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(resumo,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(170);
}

class CardSobreStartup extends StatefulWidget {
  final String descricao;
  const CardSobreStartup({super.key, required this.descricao});

  @override
  State<CardSobreStartup> createState() => _CardSobreStartupState();
}

class _CardSobreStartupState extends State<CardSobreStartup> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration:
          BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sobre a startup',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final span = TextSpan(
                text: widget.descricao,
                style: const TextStyle(color: Colors.black54, height: 1.5),
              );
              final tp = TextPainter(
                text: span,
                maxLines: 3,
                textAlign: TextAlign.left,
                textDirection: TextDirection.ltr,
              );
              tp.layout(maxWidth: constraints.maxWidth);
              final needsExpansion = tp.didExceedMaxLines;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.descricao,
                    maxLines: isExpanded ? null : 3,
                    overflow:
                        isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54, height: 1.5),
                  ),
                  if (needsExpansion)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: InkWell(
                        onTap: () => setState(() => isExpanded = !isExpanded),
                        child: Row(
                          children: [
                            Text(isExpanded ? 'Ver menos' : 'Ver mais',
                                style: const TextStyle(
                                    color: Color(0xFF00A84E),
                                    fontWeight: FontWeight.bold)),
                            Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: const Color(0xFF00A84E)),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

Widget _buildSocioRow(
    String iniciais, String nome, String cargo, String porcentagem) {
  return Row(
    children: [
      CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFE8F5E9),
        child: Text(iniciais,
            style: const TextStyle(
                color: Color(0xFF00A84E), fontWeight: FontWeight.bold)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nome,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(cargo,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
      Text(porcentagem,
          style: const TextStyle(
              color: Color(0xFF00A84E),
              fontWeight: FontWeight.bold,
              fontSize: 16)),
    ],
  );
}