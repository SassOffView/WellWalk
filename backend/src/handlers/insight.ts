import { Request, Response } from 'express';
import { AiProvider, isProviderConfigured } from '../config/env';
import { callAI } from './ai_client';

/**
 * POST /ai/insight
 *
 * Body:
 *   provider: AiProvider
 *   userContext: string  (contesto costruito dal client)
 *
 * Response:
 *   insight, suggestion, brainstormPrompt, motivationalMessage,
 *   routineTip?, walkTip?, generatedBy
 */
export async function handleInsight(req: Request, res: Response): Promise<void> {
  const { provider, userContext } = req.body as {
    provider: AiProvider;
    userContext: string;
  };

  if (!provider || !userContext) {
    res.status(400).json({ error: 'Missing provider or userContext' });
    return;
  }

  if (!isProviderConfigured(provider)) {
    res.status(503).json({ error: `Provider ${provider} not configured on server` });
    return;
  }

  const prompt = buildInsightPrompt(userContext);

  try {
    const raw = await callAI(provider, prompt, 700);
    if (!raw) {
      res.status(502).json({ error: 'AI provider returned no response' });
      return;
    }

    const parsed = parseInsightResponse(raw, provider);
    res.json(parsed);
  } catch (err) {
    console.error('[insight] Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
}

function buildInsightPrompt(userContext: string): string {
  return `Sei un coach di benessere personale. Analizza i seguenti dati di attività dell'utente e fornisci supporto personalizzato.

${userContext}

Rispondi ESCLUSIVAMENTE con un JSON valido (nessun testo prima o dopo) in questo formato:
{
  "insight": "Analisi breve del comportamento (1-2 frasi, caldo e personale)",
  "suggestion": "Suggerimento pratico e specifico per migliorare (1 frase)",
  "brainstorm_prompt": "Domanda stimolante per la riflessione di oggi (1 frase)",
  "motivational_message": "Messaggio motivazionale brevissimo per la notifica push (max 10 parole)",
  "routine_tip": "Suggerimento specifico per le routine (1 frase, può essere null)",
  "walk_tip": "Suggerimento specifico per la camminata (1 frase, può essere null)"
}

Tono: caldo, empatico, motivante. Lingua: italiano.`;
}

function parseInsightResponse(raw: string, provider: string): Record<string, unknown> {
  let cleaned = raw.trim().replace(/^```json?\n?/, '').replace(/```$/, '');

  try {
    const parsed = JSON.parse(cleaned) as Record<string, unknown>;
    return {
      insight: parsed['insight'] ?? '',
      suggestion: parsed['suggestion'] ?? '',
      brainstormPrompt: parsed['brainstorm_prompt'] ?? '',
      motivationalMessage: parsed['motivational_message'] ?? '',
      routineTip: parsed['routine_tip'] ?? null,
      walkTip: parsed['walk_tip'] ?? null,
      generatedBy: provider,
    };
  } catch {
    // Se il JSON fallisce, restituisce il testo grezzo come insight
    return {
      insight: cleaned.length > 200 ? cleaned.substring(0, 200) + '...' : cleaned,
      suggestion: 'Continua con costanza ogni giorno.',
      brainstormPrompt: 'Cosa ti ha fatto sorridere oggi?',
      motivationalMessage: 'Un passo alla volta. Stai crescendo.',
      routineTip: null,
      walkTip: null,
      generatedBy: provider,
    };
  }
}
