// AllocCheck — Calcul des droits CAF
// Basé sur les barèmes publics 2026 (Service-Public.fr)
// DISCLAIMER : Calcul indicatif, peut différer du calcul officiel CAF

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ============================================================
// BARÈMES 2026 (source : Service-Public.fr, revalorisés avril 2026)
// À mettre à jour chaque année
// ============================================================

const SMIC_HORAIRE_BRUT = 11.88; // €/h brut 2026
const SMIC_MENSUEL_NET = 1426.30; // € net 2026

// --- RSA (Revenu de Solidarité Active) ---
// Montants forfaitaires mensuels au 1er avril 2026
const RSA = {
  montant_base: 635.71, // personne seule sans enfant
  majoration_couple: 0.5, // +50% pour couple
  majoration_par_enfant_1_2: 0.3, // +30% par enfant (1er et 2e)
  majoration_par_enfant_3_plus: 0.4, // +40% par enfant (3e et suivants)
  majoration_isolement_base: 0.2857, // parent isolé +28.57%
  majoration_isolement_par_enfant: 0.1428, // +14.28% par enfant suppl.
  forfait_logement_1: 76.28, // personne seule
  forfait_logement_2: 152.57, // 2 personnes
  forfait_logement_3_plus: 188.81, // 3+ personnes
};

// --- APL (Aide Personnalisée au Logement) ---
// Simplification : barèmes zone 1/2/3, loyer plafond
const APL = {
  loyer_plafond: {
    zone_1: { 1: 319.87, 2: 391.54, 3: 431.60, 4: 472.82, supp: 42.96 },
    zone_2: { 1: 278.28, 2: 340.49, 3: 375.97, 4: 411.37, supp: 37.44 },
    zone_3: { 1: 260.40, 2: 318.60, 3: 351.71, 4: 384.82, supp: 35.02 },
  },
  charge_forfaitaire: {
    1: 56.22, 2: 112.44, supp: 31.50,
  },
  participation_personnelle_base: 37.87, // €/mois minimum
  taux_prise_en_charge_base: 0.95, // % du loyer plafonné pris en charge
};

// --- Prime d'activité ---
const PRIME_ACTIVITE = {
  montant_forfaitaire: 622.63, // base personne seule
  bonification_max: 181.19, // bonification individuelle max
  seuil_bonification: 0.5 * SMIC_MENSUEL_NET, // 50% du SMIC net
  plafond_bonification: SMIC_MENSUEL_NET, // 100% du SMIC net
  majoration_couple: 0.5,
  majoration_par_enfant_1_2: 0.3,
  majoration_par_enfant_3_plus: 0.4,
  majoration_isolement: 0.2857,
  taux_prise_en_compte_revenus: 0.38, // 38% des revenus déduits
};

// --- Allocations Familiales ---
const AF = {
  // Montants mensuels par nombre d'enfants à charge (base 2026)
  base_2_enfants: 148.52,
  base_3_enfants: 338.81,
  supplement_par_enfant: 190.29, // au-delà de 3
  majoration_age_14_plus: 74.26, // par enfant de 14+ ans
  // Plafonds de ressources (revenu net catégoriel N-2)
  plafond_base_2_enfants: 74_966,
  plafond_intermediaire_2_enfants: 99_922,
  // Au-delà du plafond intermédiaire : AF divisées par 4
  // Entre base et intermédiaire : AF divisées par 2
};

// --- AAH (Allocation aux Adultes Handicapés) ---
const AAH = {
  montant_max: 1016.05, // personne seule
  plafond_ressources_seul: 12_193.0, // annuel
  plafond_ressources_couple: 22_069.0, // annuel
  majoration_par_enfant: 6_096.0, // annuel
};

// ============================================================
// FONCTIONS DE CALCUL
// ============================================================

interface Situation {
  // Composition du foyer
  situation_familiale: "seul" | "couple";
  nombre_enfants: number;
  ages_enfants?: number[]; // pour AF majoration 14+
  parent_isole?: boolean;

  // Revenus mensuels nets
  revenu_activite_demandeur: number;
  revenu_activite_conjoint: number;
  autres_revenus: number; // pensions, rentes, etc.

  // Logement
  zone_logement: "zone_1" | "zone_2" | "zone_3";
  loyer_mensuel: number;
  statut_logement: "locataire" | "proprietaire" | "heberge";

  // Handicap
  taux_handicap?: number; // 0-100%

  // Ce que l'utilisateur perçoit actuellement
  montant_percu?: {
    rsa?: number;
    apl?: number;
    prime_activite?: number;
    af?: number;
    aah?: number;
  };
}

interface DroitsCalcules {
  rsa: number;
  apl: number;
  prime_activite: number;
  af: number;
  aah: number;
  total: number;
  details: Record<string, string>; // explications par aide
}

function calculerRSA(s: Situation): { montant: number; detail: string } {
  const nb_personnes = (s.situation_familiale === "couple" ? 2 : 1) + s.nombre_enfants;

  // Montant forfaitaire
  let montant_forfaitaire = RSA.montant_base;
  if (s.situation_familiale === "couple") {
    montant_forfaitaire *= (1 + RSA.majoration_couple);
  }
  for (let i = 0; i < s.nombre_enfants; i++) {
    if (i < 2) {
      montant_forfaitaire += RSA.montant_base * RSA.majoration_par_enfant_1_2;
    } else {
      montant_forfaitaire += RSA.montant_base * RSA.majoration_par_enfant_3_plus;
    }
  }

  // Majoration parent isolé
  if (s.parent_isole && s.situation_familiale === "seul" && s.nombre_enfants > 0) {
    montant_forfaitaire *= (1 + RSA.majoration_isolement_base);
    montant_forfaitaire += RSA.montant_base * RSA.majoration_isolement_par_enfant * (s.nombre_enfants - 1);
  }

  // Forfait logement (déduit si le demandeur est logé gratuitement ou perçoit une aide au logement)
  let forfait_logement = 0;
  if (s.statut_logement === "heberge" || s.loyer_mensuel === 0) {
    if (nb_personnes === 1) forfait_logement = RSA.forfait_logement_1;
    else if (nb_personnes === 2) forfait_logement = RSA.forfait_logement_2;
    else forfait_logement = RSA.forfait_logement_3_plus;
  }

  // Ressources du foyer
  const ressources = s.revenu_activite_demandeur + s.revenu_activite_conjoint + s.autres_revenus;

  // RSA = montant forfaitaire - ressources - forfait logement
  // Les revenus d'activité bénéficient d'un abattement (bonification via prime d'activité)
  const rsa = Math.max(0, montant_forfaitaire - ressources - forfait_logement);

  const detail = rsa > 0
    ? `RSA estimé : ${rsa.toFixed(2)}€/mois. Montant forfaitaire : ${montant_forfaitaire.toFixed(2)}€, ressources : ${ressources.toFixed(2)}€, forfait logement : ${forfait_logement.toFixed(2)}€.`
    : `Pas éligible au RSA : vos ressources (${ressources.toFixed(2)}€) dépassent le montant forfaitaire (${montant_forfaitaire.toFixed(2)}€).`;

  return { montant: Math.round(rsa * 100) / 100, detail };
}

function calculerAPL(s: Situation): { montant: number; detail: string } {
  if (s.statut_logement !== "locataire" || s.loyer_mensuel === 0) {
    return { montant: 0, detail: "APL : non éligible (non locataire ou loyer nul)." };
  }

  const nb_personnes = (s.situation_familiale === "couple" ? 2 : 1) + s.nombre_enfants;
  const zone = s.zone_logement;

  // Loyer plafonné
  const plafonds = APL.loyer_plafond[zone];
  let loyer_plafond: number;
  if (nb_personnes <= 4) {
    loyer_plafond = plafonds[nb_personnes as 1 | 2 | 3 | 4];
  } else {
    loyer_plafond = plafonds[4] + plafonds.supp * (nb_personnes - 4);
  }
  const loyer_retenu = Math.min(s.loyer_mensuel, loyer_plafond);

  // Charge forfaitaire
  let charge = APL.charge_forfaitaire[1];
  if (nb_personnes >= 2) {
    charge = APL.charge_forfaitaire[2] + APL.charge_forfaitaire.supp * Math.max(0, nb_personnes - 2);
  }

  // Ressources mensuelles
  const ressources_mensuelles = s.revenu_activite_demandeur + s.revenu_activite_conjoint + s.autres_revenus;
  const ressources_annuelles = ressources_mensuelles * 12;

  // Calcul simplifié de l'APL
  // APL = loyer retenu + charges - participation personnelle
  // Participation personnelle = P0 + Tp * (R - R0)
  // Simplification : on utilise un taux de participation basé sur les ressources
  const participation_base = APL.participation_personnelle_base;
  const taux_participation = Math.min(0.95, 0.005 + (ressources_annuelles / 100000));
  const participation = participation_base + taux_participation * (loyer_retenu + charge);

  const apl = Math.max(0, (loyer_retenu + charge) * APL.taux_prise_en_charge_base - participation);

  // APL minimale : si < 15€, pas versée
  const apl_final = apl < 15 ? 0 : apl;

  const detail = apl_final > 0
    ? `APL estimée : ${apl_final.toFixed(2)}€/mois. Loyer retenu : ${loyer_retenu.toFixed(2)}€ (plafond ${zone} : ${loyer_plafond.toFixed(2)}€).`
    : `APL non éligible ou montant < 15€ (seuil de non-versement).`;

  return { montant: Math.round(apl_final * 100) / 100, detail };
}

function calculerPrimeActivite(s: Situation): { montant: number; detail: string } {
  const revenus_activite = s.revenu_activite_demandeur + s.revenu_activite_conjoint;

  // Condition : au moins un revenu d'activité > 0
  if (revenus_activite === 0) {
    return { montant: 0, detail: "Prime d'activité : non éligible (aucun revenu d'activité)." };
  }

  // Montant forfaitaire majoré
  let montant_forfaitaire = PRIME_ACTIVITE.montant_forfaitaire;
  if (s.situation_familiale === "couple") {
    montant_forfaitaire *= (1 + PRIME_ACTIVITE.majoration_couple);
  }
  for (let i = 0; i < s.nombre_enfants; i++) {
    if (i < 2) {
      montant_forfaitaire += PRIME_ACTIVITE.montant_forfaitaire * PRIME_ACTIVITE.majoration_par_enfant_1_2;
    } else {
      montant_forfaitaire += PRIME_ACTIVITE.montant_forfaitaire * PRIME_ACTIVITE.majoration_par_enfant_3_plus;
    }
  }

  // Bonification individuelle
  let bonification = 0;
  for (const revenu of [s.revenu_activite_demandeur, s.revenu_activite_conjoint]) {
    if (revenu >= PRIME_ACTIVITE.seuil_bonification) {
      const taux = Math.min(1, (revenu - PRIME_ACTIVITE.seuil_bonification) / (PRIME_ACTIVITE.plafond_bonification - PRIME_ACTIVITE.seuil_bonification));
      bonification += taux * PRIME_ACTIVITE.bonification_max;
    }
  }

  // Ressources prises en compte
  const ressources = s.revenu_activite_demandeur + s.revenu_activite_conjoint + s.autres_revenus;
  const revenus_pris_en_compte = ressources * PRIME_ACTIVITE.taux_prise_en_compte_revenus;

  // Prime = forfaitaire + 61% revenus activité + bonification - ressources prises en compte
  const prime = montant_forfaitaire + 0.61 * revenus_activite + bonification - ressources - revenus_pris_en_compte;
  const prime_final = Math.max(0, prime);

  const detail = prime_final > 0
    ? `Prime d'activité estimée : ${prime_final.toFixed(2)}€/mois. Forfaitaire : ${montant_forfaitaire.toFixed(2)}€, bonification : ${bonification.toFixed(2)}€.`
    : `Prime d'activité : non éligible (ressources trop élevées pour la composition du foyer).`;

  return { montant: Math.round(prime_final * 100) / 100, detail };
}

function calculerAF(s: Situation): { montant: number; detail: string } {
  if (s.nombre_enfants < 2) {
    return { montant: 0, detail: "Allocations familiales : minimum 2 enfants à charge requis." };
  }

  const ressources_annuelles = (s.revenu_activite_demandeur + s.revenu_activite_conjoint + s.autres_revenus) * 12;

  // Montant de base
  let montant = 0;
  if (s.nombre_enfants === 2) {
    montant = AF.base_2_enfants;
  } else if (s.nombre_enfants === 3) {
    montant = AF.base_3_enfants;
  } else {
    montant = AF.base_3_enfants + AF.supplement_par_enfant * (s.nombre_enfants - 3);
  }

  // Majoration âge 14+
  let nb_14_plus = 0;
  if (s.ages_enfants) {
    nb_14_plus = s.ages_enfants.filter(age => age >= 14).length;
    // Pas de majoration pour l'aîné d'une famille de 2 enfants
    if (s.nombre_enfants === 2 && nb_14_plus > 0) nb_14_plus = Math.max(0, nb_14_plus - 1);
  }
  montant += nb_14_plus * AF.majoration_age_14_plus;

  // Modulation selon ressources (plafonds pour 2 enfants, +6 105€ par enfant suppl.)
  const plafond_base = AF.plafond_base_2_enfants + 6105 * Math.max(0, s.nombre_enfants - 2);
  const plafond_inter = AF.plafond_intermediaire_2_enfants + 6105 * Math.max(0, s.nombre_enfants - 2);

  if (ressources_annuelles > plafond_inter) {
    montant /= 4; // tranche haute
  } else if (ressources_annuelles > plafond_base) {
    montant /= 2; // tranche intermédiaire
  }

  const detail = montant > 0
    ? `Allocations familiales estimées : ${montant.toFixed(2)}€/mois pour ${s.nombre_enfants} enfants.`
    : `Allocations familiales : non éligible.`;

  return { montant: Math.round(montant * 100) / 100, detail };
}

function calculerAAH(s: Situation): { montant: number; detail: string } {
  if (!s.taux_handicap || s.taux_handicap < 80) {
    // En dessous de 80%, conditions supplémentaires (restriction substantielle d'accès à l'emploi)
    if (!s.taux_handicap || s.taux_handicap < 50) {
      return { montant: 0, detail: "AAH : taux d'incapacité < 50%, non éligible." };
    }
    // Entre 50% et 79% : éligible sous conditions
  }

  const ressources_annuelles = (s.revenu_activite_demandeur + s.revenu_activite_conjoint + s.autres_revenus) * 12;
  let plafond = s.situation_familiale === "couple" ? AAH.plafond_ressources_couple : AAH.plafond_ressources_seul;
  plafond += s.nombre_enfants * AAH.majoration_par_enfant;

  if (ressources_annuelles > plafond) {
    return { montant: 0, detail: `AAH : ressources annuelles (${ressources_annuelles.toFixed(0)}€) > plafond (${plafond.toFixed(0)}€).` };
  }

  // AAH = montant max - ressources mensuelles (simplifié)
  const aah = Math.max(0, AAH.montant_max - (ressources_annuelles / 12));

  const detail = aah > 0
    ? `AAH estimée : ${aah.toFixed(2)}€/mois (taux handicap ${s.taux_handicap}%).`
    : `AAH : non éligible au vu de vos ressources.`;

  return { montant: Math.round(aah * 100) / 100, detail };
}

function calculerTousDroits(situation: Situation): DroitsCalcules {
  const rsa = calculerRSA(situation);
  const apl = calculerAPL(situation);
  const prime = calculerPrimeActivite(situation);
  const af = calculerAF(situation);
  const aah = calculerAAH(situation);

  return {
    rsa: rsa.montant,
    apl: apl.montant,
    prime_activite: prime.montant,
    af: af.montant,
    aah: aah.montant,
    total: rsa.montant + apl.montant + prime.montant + af.montant + aah.montant,
    details: {
      rsa: rsa.detail,
      apl: apl.detail,
      prime_activite: prime.detail,
      af: af.detail,
      aah: aah.detail,
    },
  };
}

function calculerEcart(droits: DroitsCalcules, percu: Record<string, number>): {
  ecarts: Record<string, number>;
  ecart_total: number;
  aides_non_reclamees: string[];
} {
  const ecarts: Record<string, number> = {};
  let ecart_total = 0;
  const aides_non_reclamees: string[] = [];

  const aides = ["rsa", "apl", "prime_activite", "af", "aah"] as const;

  for (const aide of aides) {
    const theorique = droits[aide] || 0;
    const recu = percu[aide] || 0;
    const diff = theorique - recu;
    ecarts[aide] = Math.round(diff * 100) / 100;

    if (diff > 0) {
      ecart_total += diff;
      if (recu === 0 && theorique > 0) {
        aides_non_reclamees.push(aide);
      }
    }
  }

  return {
    ecarts,
    ecart_total: Math.round(ecart_total * 100) / 100,
    aides_non_reclamees,
  };
}

// ============================================================
// HANDLER
// ============================================================

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
      },
    });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
  }

  try {
    const body = await req.json();
    const situation: Situation = body.situation;

    if (!situation) {
      return new Response(JSON.stringify({ error: "Missing 'situation' in request body" }), { status: 400 });
    }

    // Calculer les droits
    const droits = calculerTousDroits(situation);

    // Calculer l'écart si montant_percu fourni
    let ecart = null;
    if (situation.montant_percu) {
      ecart = calculerEcart(droits, situation.montant_percu);
    }

    // Sauvegarder en DB si authentifié
    const authHeader = req.headers.get("Authorization");
    if (authHeader) {
      try {
        const supabase = createClient(
          Deno.env.get("SUPABASE_URL")!,
          Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
        );

        const token = authHeader.replace("Bearer ", "");
        const { data: { user } } = await supabase.auth.getUser(token);

        if (user) {
          await supabase.from("simulations").insert({
            user_id: user.id,
            situation: situation,
            droits_theoriques: droits,
            montant_percu: situation.montant_percu || {},
            ecart: ecart?.ecarts || {},
            ecart_total: ecart?.ecart_total || 0,
          });
        }
      } catch {
        // Silently fail DB save — calcul is still returned
      }
    }

    return new Response(
      JSON.stringify({
        droits,
        ecart,
        disclaimer: "Calcul indicatif basé sur les barèmes publics 2026. Peut différer du calcul officiel de la CAF.",
      }),
      {
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: "Erreur de calcul", message: (error as Error).message }),
      { status: 500 }
    );
  }
});
