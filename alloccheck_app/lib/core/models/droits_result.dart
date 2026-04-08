/// Résultat du calcul des droits CAF
class DroitsResult {
  final double rsa;
  final double apl;
  final double primeActivite;
  final double af;
  final double aah;
  final double cmg;
  final double paje;
  final double cf;
  final double prepare;
  final double ars;
  final double mva;
  final double asf;
  final double total;
  final Map<String, String> details;

  const DroitsResult({
    required this.rsa,
    required this.apl,
    required this.primeActivite,
    required this.af,
    required this.aah,
    this.cmg = 0,
    this.paje = 0,
    this.cf = 0,
    this.prepare = 0,
    this.ars = 0,
    this.mva = 0,
    this.asf = 0,
    required this.total,
    required this.details,
  });

  factory DroitsResult.fromJson(Map<String, dynamic> json) {
    return DroitsResult(
      rsa: (json['rsa'] as num?)?.toDouble() ?? 0,
      apl: (json['apl'] as num?)?.toDouble() ?? 0,
      primeActivite: (json['prime_activite'] as num?)?.toDouble() ?? 0,
      af: (json['af'] as num?)?.toDouble() ?? 0,
      aah: (json['aah'] as num?)?.toDouble() ?? 0,
      ars: (json['ars'] as num?)?.toDouble() ?? 0,
      mva: (json['mva'] as num?)?.toDouble() ?? 0,
      asf: (json['asf'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      details: (json['details'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          {},
    );
  }
}

/// Résultat de la comparaison droits théoriques vs perçu
class EcartResult {
  final Map<String, double> ecarts;
  final double ecartTotal;
  final List<String> aidesNonReclamees;

  const EcartResult({
    required this.ecarts,
    required this.ecartTotal,
    required this.aidesNonReclamees,
  });

  factory EcartResult.fromJson(Map<String, dynamic> json) {
    return EcartResult(
      ecarts: (json['ecarts'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      ecartTotal: (json['ecart_total'] as num?)?.toDouble() ?? 0,
      aidesNonReclamees: (json['aides_non_reclamees'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  bool get hasEcart => ecartTotal > 0;
  bool get hasAidesNonReclamees => aidesNonReclamees.isNotEmpty;
}

/// Aide méconnue suggérée selon le profil
class AideSuggestion {
  final String titre;
  final String description;
  final String source; // organisme à contacter

  const AideSuggestion({
    required this.titre,
    required this.description,
    required this.source,
  });
}

/// Réponse complète du calcul
class CalculResponse {
  final DroitsResult droits;
  final EcartResult? ecart;
  final String disclaimer;
  final List<AideSuggestion> suggestions;

  const CalculResponse({
    required this.droits,
    this.ecart,
    required this.disclaimer,
    this.suggestions = const [],
  });

  factory CalculResponse.fromJson(Map<String, dynamic> json) {
    return CalculResponse(
      droits: DroitsResult.fromJson(json['droits'] as Map<String, dynamic>),
      ecart: json['ecart'] != null
          ? EcartResult.fromJson(json['ecart'] as Map<String, dynamic>)
          : null,
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}
