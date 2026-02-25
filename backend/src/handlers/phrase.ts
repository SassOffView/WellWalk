import { Request, Response } from 'express';
import { AiProvider, isProviderConfigured } from '../config/env';
import { callAI } from './ai_client';

/**
 * POST /ai/phrase
 *
 * Body:
 *   provider: AiProvider
 *   context: string   (contesto comportamentale — ora, giorni assenza, ecc.)
 *
 * Response:
 *   { phrase: string }
 */
export async function handlePhrase(req: Request, res: Response): Promise<void> {
  const { provider, context } = req.body as {
    provider: AiProvider;
    context: string;
  };

  if (!provider || !context) {
    res.status(400).json({ error: 'Missing provider or context' });
    return;
  }

  if (!isProviderConfigured(provider)) {
    res.status(503).json({ error: `Provider ${provider} not configured on server` });
    return;
  }

  const prompt = buildPhrasePrompt(context);

  try {
    const raw = await callAI(provider, prompt, 60);

    if (!raw) {
      res.status(502).json({ error: 'AI provider returned no response' });
      return;
    }

    const phrase = raw
      .trim()
      .replace(/^["«»""]|["«»""]$/g, '')
      .replace(/```/g, '')
      .trim();

    res.json({ phrase });
  } catch (err) {
    console.error('[phrase] Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
}

function buildPhrasePrompt(context: string): string {
  return `Sei la voce lucida dell'utente — non un coach esterno, ma la sua parte più chiara.
Genera UNA sola frase di apertura per il suo momento di chiarezza mentale.

${context}

REGOLE ASSOLUTE:
- Massimo 12 parole
- Lingua: italiano
- Tono: calmo, introspettivo, come parlare con se stessi in silenzio
- Focus: chiarezza, presenza, organizzazione dei pensieri
- NON usare: esclamazioni, imperativi aggressivi, cliché motivazionali
- NON iniziare con "Tu" diretto

Rispondi SOLO con la frase. Zero altri caratteri.`;
}
