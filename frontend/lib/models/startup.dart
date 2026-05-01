// Autor: Allan Giovanni Matias Paes
import 'package:flutter/material.dart';

import  './firebase.dart';

enum StartupStage {
  nova,
  em_operacao,
  em_expansao;

  static StartupStage fromString(String value) {
    switch (value) {
      case 'nova':
        return StartupStage.nova;
      case 'em_operacao':
        return StartupStage.em_operacao;
      case 'em_expansao':
        return StartupStage.em_expansao;
      default:
        throw ArgumentError('Invalid StartupStage: $value');
    }
  }

  String toDisplayString() {
    switch (this) {
      case StartupStage.nova:
        return 'Nova';
      case StartupStage.em_operacao:
        return 'Em Operação';
      case StartupStage.em_expansao:
        return 'Em Expansão';
    }
  }
}

class StartupListItem {
  final String id;
  final String name;
  final StartupStage stage;
  final String shortDescription;
  final int capitalRaisedCents;
  final int totalTokensIssued;
  final int currentTokenPriceCents;
  final double? priceVariation;
  final String priceVariationTrend;
  final String? coverImageUrl;
  final List<String> tags;

  StartupListItem({
    required this.id,
    required this.name,
    required this.stage,
    required this.shortDescription,
    required this.capitalRaisedCents,
    required this.totalTokensIssued,
    required this.currentTokenPriceCents,
    required this.priceVariation,
    required this.priceVariationTrend,
    this.coverImageUrl,
    required this.tags,
  });

  factory StartupListItem.fromJson(String id, Map<String, dynamic> json) {
    return StartupListItem(
      id: id,
      name: json['name'] as String,
      stage: StartupStage.fromString(json['stage'] as String),
      shortDescription: json['shortDescription'] as String,
      capitalRaisedCents: json['capitalRaisedCents'] as int,
      totalTokensIssued: json['totalTokensIssued'] as int,
      currentTokenPriceCents: json['currentTokenPriceCents'] as int,
      priceVariation: json['variation']['percentage'] ?.toDouble(),
      priceVariationTrend: json['variation']['trend'],
      coverImageUrl: json['coverImageUrl'] as String?,
      tags: List<String>.from(json['tags'] as List),
    );
  }

}

class Founder {
  final String name;
  final String role;
  final int equityPercent;
  final String bio;

  Founder({
    required this.name,
    required this.role,
    required this.equityPercent,
    required this.bio,
  });

  factory Founder.fromJson(Map<String, dynamic> json) {
    return Founder(
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      equityPercent: json['equityPercent'] ?? 0,
      bio: json['bio'] ?? '',
    );
  }
}

class PriceHistoryItem {
  final String timestamp;
  final double price;
  final double? variation;
  final double? variationPercent;

  PriceHistoryItem({
    required this.timestamp,
    required this.price,
    this.variation,
    this.variationPercent,
  });

  factory PriceHistoryItem.fromJson(Map<String, dynamic> json) {
    return PriceHistoryItem(
      timestamp: json['timestamp'],
      price: (json['price'] as num).toDouble(),
      variation: (json['variation'] as num?)?.toDouble(),
      variationPercent: (json['variationPercent'] as num?)?.toDouble(),
    );
  }
}

class PriceSummary {
  final double currentPrice;
  final double highestPrice;
  final double lowestPrice;
  final double averagePrice;

  PriceSummary({
    required this.currentPrice,
    required this.highestPrice,
    required this.lowestPrice,
    required this.averagePrice,
  });

  factory PriceSummary.fromJson(Map<String, dynamic> json) {
    return PriceSummary(
      currentPrice: (json['currentPrice'] as num).toDouble(),
      highestPrice: (json['highestPrice'] as num).toDouble(),
      lowestPrice: (json['lowestPrice'] as num).toDouble(),
      averagePrice: (json['averagePrice'] as num).toDouble(),
    );
  }
}

class PriceMeta {
  final int count;
  final String currency;
  final String interval;

  PriceMeta({
    required this.count,
    required this.currency,
    required this.interval,
  });

  factory PriceMeta.fromJson(Map<String, dynamic> json) {
    return PriceMeta(
      count: json['count'],
      currency: json['currency'],
      interval: json['interval'],
    );
  }
}

class ExternalMember {
  final String name;
  final String role;
  final String organization;

  ExternalMember({
    required this.name,
    required this.role,
    required this.organization,
  });

  factory ExternalMember.fromJson(Map<String, dynamic> json) {
    return ExternalMember(
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      organization: json['organization'] ?? '',
    );
  }
}

class Answer {
  final String answer;
  final DateTime answeredAt;

  Answer({
    required this.answer,
    required this.answeredAt,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      answer: json['answer'] ?? '',
      answeredAt: DateTime.parse(json['answeredAt']),
    );
  }
}

class Question {
  final String id;
  final String startupId;
  final String authorId;
  final String authorEmail;
  final String visibility;
  final String text;
  final List<Answer> answers;
  final DateTime createdAt;

  Question({
    required this.id,
    required this.text,
    required this.answers,
    required this.createdAt,
    required this.startupId,
    required this.authorEmail,
    required this.authorId,
    required this.visibility
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['text'],
      startupId: json['startupId'],
      authorEmail: json['authorEmail'],
      authorId: json['authorId'],
      visibility: json['visibility'],
      answers: (json['answers'] as List? ?? [])
          .map((e) => Answer.fromJson(e))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class Access {
  final bool isInvestor;
  final bool canTradeTokens;
  final bool canSendPrivateQuestions;

  Access({
    required this.isInvestor,
    required this.canTradeTokens,
    required this.canSendPrivateQuestions,
  });

  factory Access.fromJson(Map<String, dynamic> json) {
    return Access(
      isInvestor: json['isInvestor'] ?? false,
      canTradeTokens: json['canTradeTokens'] ?? false,
      canSendPrivateQuestions: json['canSendPrivateQuestions'] ?? false,
    );
  }
}



//Autor: Pedro Vinicius Romanato & Allan Giovanni Matias Paes

class StartupData {
  // 🔹 básicos
  final String id;
  final String name;
  final String segment;
  final String logoUrl;
  final String shortDescription;
  final String longDescription;

  // 🔹 métricas
  final double expectedReturn;
  final String riskLabel;
  final String horizon;
  final int valuation;

  // 🔹 tokens
  final int totalTokens;
  final int circulatingTokens;
  final int currentTokenPriceCents;

  // 🔹 startup
  final List<String> demoVideos;
  final StartupStage stage;
  final List<ExternalMember> externalMembers;
  final int capitalRaisedCents;
  final String executiveSummary;
  final int lastValuationCents;
  final FirestoreTimestamp createdAt;
  final FirestoreTimestamp updatedAt;

  // 🔹 relações
  final List<Founder> founders;
  final List<String> tags;

  // 🔹 mercado
  final List<PriceHistoryItem> history;
  final PriceSummary summary;
  final PriceMeta meta;

  // 🔹 interação
  final List<Question> questions;
  final Access access;

  StartupData({
    required this.id,
    required this.name,
    required this.segment,
    required this.logoUrl,
    required this.shortDescription,
    required this.longDescription,
    required this.expectedReturn,
    required this.riskLabel,
    required this.horizon,
    required this.valuation,
    required this.totalTokens,
    required this.circulatingTokens,
    required this.currentTokenPriceCents,
    required this.demoVideos,
    required this.stage,
    required this.externalMembers,
    required this.capitalRaisedCents,
    required this.executiveSummary,
    required this.lastValuationCents,
    required this.createdAt,
    required this.updatedAt,
    required this.founders,
    required this.tags,
    required this.history,
    required this.summary,
    required this.meta,
    required this.questions,
    required this.access,
  });

  factory StartupData.fromJson(Map<String, dynamic> json) {
    final data = json['result']['data'];
    final details = data['details'];
    final startup = details['startup'];
    final priceHistory = data['priceHistory'];

    return StartupData(
      id: data['id'],
      name: startup['name'] ?? '',
      segment: (startup['tags'] as List?)?.isNotEmpty == true
          ? startup['tags'][0]
          : 'Startup',
      logoUrl: startup['coverImageUrl'] ?? '',
      shortDescription: startup['shortDescription'] ?? '',
      longDescription: startup['description'] ?? '',

      // métricas
      expectedReturn: (details['expectedReturn']['expected'] as num).toDouble(),
      riskLabel: details['risk']['label'] ?? '',
      horizon: details['horizon'] ?? '',
      valuation: details['valuation'] ?? 0,

      // tokens
      totalTokens: startup['totalTokensIssued'] ?? 0,
      circulatingTokens: startup['circulatingTokens'] ?? 0,
      currentTokenPriceCents: startup['currentTokenPriceCents'] ?? 0,

      // startup
      demoVideos: List<String>.from(startup['demoVideos'] ?? []),
      stage: StartupStage.fromString(startup['stage']),
      externalMembers: (startup['externalMembers'] as List? ?? [])
          .map((e) => ExternalMember.fromJson(e))
          .toList(),
      capitalRaisedCents: startup['capitalRaisedCents'] ?? 0,
      executiveSummary: startup['executiveSummary'] ?? '',
      lastValuationCents: startup['lastValuationCents'] ?? 0,
      createdAt: FirestoreTimestamp.fromJson(startup['createdAt']),
      updatedAt: FirestoreTimestamp.fromJson(startup['updatedAt']),

      // relações
      founders: (startup['founders'] as List? ?? [])
          .map((e) => Founder.fromJson(e))
          .toList(),
      tags: List<String>.from(startup['tags'] ?? []),

      // mercado
      history: (priceHistory['history'] as List? ?? [])
          .map((e) => PriceHistoryItem.fromJson(e))
          .toList(),
      summary: PriceSummary.fromJson(priceHistory['summary']),
      meta: PriceMeta.fromJson(priceHistory['meta']),

      // interação
      questions: (data['questions'] as List? ?? [])
          .map((e) => Question.fromJson(e))
          .toList(),
      access: Access.fromJson(data['access']),
    );
  }
}