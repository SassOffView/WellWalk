import { Request, Response } from 'express';
import { AiProvider, isProviderConfigured } from '../config/env';
import { callAIChat } from './ai_client';

const COACH_SYSTEM_PROMPT = `Sei un Coach di Chiarezza Strategica.
Il tuo obiettivo non è dare soluzioni, ma aiutare l'utente a pensare meglio, vedere con più lucidità e identificare il prossimo passo concreto.

TONO E PERSONALITÀ:
- Calmo, lucido, presente
- Intelligente ma non accademico
- Empatico ma non terapeutico
- Incoraggiante ma non euforico
- Mai giudicante, mai paternalistico, mai motivazionale generico

METODO:
1. Breve validazione (max 1 frase) — riconosci lo stato senza amplificarlo
2. Domanda socratica mirata — UNA domanda che chiarisce, restringe il focus
3. Micro-orientamento all'azione (facoltativo) — "Qual è il primo passo minimo?"

STILE:
- 3-6 righe massimo
- Linguaggio semplice, frasi brevi
- Una sola domanda principale per risposta
- Niente elenchi puntati, niente emoji, niente spiegazioni teoriche

CONTESTO: L'utente sta camminando o registrando pensieri. Le risposte devono essere leggere, immediate, favorire riflessione in movimento.`;

/**
 * POST /ai/coach
 *
 * Body:
 *   provider: AiProvider
 *   messages: Array<{ role: 'user'|'assistant', content: string }>
 *
 * Response:
 *   { reply: string }
 */
export async function handleCoach(req: Request, res: Response): Promise<void> {
  const { provider, messages } = req.body as {
    provider: AiProvider;
    messages: Array<{ role: string; content: string }>;
  };

  if (!provider || !messages || !Array.isArray(messages)) {
    res.status(400).json({ error: 'Missing provider or messages' });
    return;
  }

  if (!isProviderConfigured(provider)) {
    res.status(503).json({ error: `Provider ${provider} not configured on server` });
    return;
  }

  try {
    const reply = await callAIChat(provider, messages, COACH_SYSTEM_PROMPT, 300);

    if (!reply) {
      res.status(502).json({ error: 'AI provider returned no response' });
      return;
    }

    res.json({ reply: reply.trim() });
  } catch (err) {
    console.error('[coach] Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
}
