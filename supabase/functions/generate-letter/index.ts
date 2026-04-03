// AllocCheck — Génération de courrier de contestation CAF
// Utilise Claude API pour rédiger un courrier personnalisé

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY");

interface LetterRequest {
  letter_type: "reclamation_gracieuse" | "saisine_cra";
  aide_type: string; // rsa, apl, prime_activite, af, aah
  montant_theorique: number;
  montant_percu: number;
  ecart: number;
  situation_resume: string; // résumé de la situation pour contexte
  nom_complet: string;
  adresse: string;
  numero_allocataire?: string;
  caf_departement: string;
}

const SYSTEM_PROMPT = `Tu es un assistant juridique spécialisé en droit de la Sécurité Sociale française.
Tu génères des courriers de contestation à la CAF (Caisse d'Allocations Familiales) pour des allocataires.

RÈGLES STRICTES :
- Tu génères UNIQUEMENT des modèles de courrier. Ce n'est PAS un conseil juridique.
- Chaque courrier doit citer les articles de loi pertinents (Code de la Sécurité Sociale).
- Le ton est formel, respectueux mais ferme.
- Tu ne dois JAMAIS inventer de références légales — utilise uniquement les articles connus.
- Inclus toujours la mention "Ce courrier est un modèle à adapter à votre situation personnelle."

ARTICLES DE RÉFÉRENCE :
- RSA : Articles L262-1 à L262-58 du Code de l'Action Sociale et des Familles (CASF)
- APL : Articles L821-1 à L835-7 du Code de la Construction et de l'Habitation (CCH)
- Prime d'activité : Articles L841-1 à L846-2 du CSS
- Allocations familiales : Articles L521-1 à L521-3 du CSS
- AAH : Articles L821-1 à L821-8 du CSS
- Recours gracieux : Article R142-1 du CSS
- Commission de Recours Amiable : Articles R142-1 à R142-8 du CSS
- Délai de recours : 2 mois à compter de la notification (Article R142-1 CSS)

FORMAT DU COURRIER :
1. En-tête (expéditeur, destinataire, date, objet)
2. Rappel de la situation
3. Motifs de la contestation avec références légales
4. Demande précise (recalcul, versement du différentiel)
5. Pièces jointes à fournir
6. Formule de politesse`;

function getLetterPrompt(req: LetterRequest): string {
  const aideLabels: Record<string, string> = {
    rsa: "Revenu de Solidarité Active (RSA)",
    apl: "Aide Personnalisée au Logement (APL)",
    prime_activite: "Prime d'activité",
    af: "Allocations familiales",
    aah: "Allocation aux Adultes Handicapés (AAH)",
  };

  const aide_label = aideLabels[req.aide_type] || req.aide_type;

  if (req.letter_type === "reclamation_gracieuse") {
    return `Génère un courrier de réclamation gracieuse à la CAF pour contester le montant de ${aide_label}.

INFORMATIONS :
- Nom : ${req.nom_complet}
- Adresse : ${req.adresse}
- CAF du département : ${req.caf_departement}
${req.numero_allocataire ? `- N° allocataire : ${req.numero_allocataire}` : "- N° allocataire : [à compléter]"}
- Aide concernée : ${aide_label}
- Montant perçu actuellement : ${req.montant_percu}€/mois
- Montant estimé correct : ${req.montant_theorique}€/mois
- Écart mensuel : ${req.ecart}€/mois (${(req.ecart * 12).toFixed(2)}€/an)
- Situation : ${req.situation_resume}

OBJET : Réclamation gracieuse — Demande de recalcul de ${aide_label}

Le courrier doit demander un réexamen du dossier et un recalcul du montant de ${aide_label}.`;
  }

  return `Génère un courrier de saisine de la Commission de Recours Amiable (CRA) de la CAF pour contester le montant de ${aide_label}.

INFORMATIONS :
- Nom : ${req.nom_complet}
- Adresse : ${req.adresse}
- CAF du département : ${req.caf_departement}
${req.numero_allocataire ? `- N° allocataire : ${req.numero_allocataire}` : "- N° allocataire : [à compléter]"}
- Aide concernée : ${aide_label}
- Montant perçu actuellement : ${req.montant_percu}€/mois
- Montant estimé correct : ${req.montant_theorique}€/mois
- Écart mensuel : ${req.ecart}€/mois
- Situation : ${req.situation_resume}

OBJET : Saisine de la Commission de Recours Amiable — ${aide_label}

Le courrier doit saisir la CRA conformément aux articles R142-1 à R142-8 du CSS, suite au rejet ou absence de réponse à la réclamation gracieuse.
Mentionner le délai de 2 mois pour saisir le Tribunal des Affaires de Sécurité Sociale en cas de rejet par la CRA.`;
}

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

  if (!ANTHROPIC_API_KEY) {
    return new Response(JSON.stringify({ error: "ANTHROPIC_API_KEY not configured" }), { status: 500 });
  }

  try {
    const body: LetterRequest = await req.json();

    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-20250514",
        max_tokens: 2000,
        temperature: 0.3,
        system: SYSTEM_PROMPT,
        messages: [
          { role: "user", content: getLetterPrompt(body) },
        ],
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Claude API error: ${response.status} — ${error}`);
    }

    const data = await response.json();
    const letterContent = data.content[0].text;

    return new Response(
      JSON.stringify({
        letter: letterContent,
        letter_type: body.letter_type,
        aide_type: body.aide_type,
        disclaimer: "Ce courrier est un modèle à adapter à votre situation. Il ne constitue pas un conseil juridique.",
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
      JSON.stringify({ error: "Erreur de génération", message: (error as Error).message }),
      { status: 500 }
    );
  }
});
