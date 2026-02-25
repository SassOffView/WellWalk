/**
 * Client unificato per le chiamate AI.
 * Tutte le chiamate ai provider avvengono qui, con le chiavi del server.
 */
import { config, AiProvider } from '../config/env';

// ── Gemini ────────────────────────────────────────────────────────────────────

export async function callGemini(
  prompt: string,
  maxTokens = 600,
): Promise<string | null> {
  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/` +
    `${config.gemini.model}:generateContent?key=${config.gemini.apiKey}`;

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.7, maxOutputTokens: maxTokens },
    }),
    signal: AbortSignal.timeout(20_000),
  });

  if (!res.ok) return null;
  const data = (await res.json()) as Record<string, unknown>;
  const candidates = data['candidates'] as Array<Record<string, unknown>> | undefined;
  const content = candidates?.[0]?.['content'] as Record<string, unknown> | undefined;
  const parts = content?.['parts'] as Array<Record<string, unknown>> | undefined;
  return (parts?.[0]?.['text'] as string) ?? null;
}

export async function callGeminiChat(
  messages: Array<{ role: string; content: string }>,
  systemPrompt: string,
  maxTokens = 300,
): Promise<string | null> {
  // Gemini non ha system message nativo — lo anteponiamo al primo messaggio
  const contents = messages.map((m, i) => ({
    role: m.role === 'user' ? 'user' : 'model',
    parts: [{
      text: i === 0 && m.role === 'user'
        ? `ISTRUZIONI:\n${systemPrompt}\n\n---\n\nUTENTE: ${m.content}`
        : m.content,
    }],
  }));

  const url =
    `https://generativelanguage.googleapis.com/v1beta/models/` +
    `${config.gemini.model}:generateContent?key=${config.gemini.apiKey}`;

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents,
      generationConfig: { temperature: 0.7, maxOutputTokens: maxTokens },
    }),
    signal: AbortSignal.timeout(20_000),
  });

  if (!res.ok) return null;
  const data = (await res.json()) as Record<string, unknown>;
  const candidates = data['candidates'] as Array<Record<string, unknown>> | undefined;
  const content = candidates?.[0]?.['content'] as Record<string, unknown> | undefined;
  const parts = content?.['parts'] as Array<Record<string, unknown>> | undefined;
  return (parts?.[0]?.['text'] as string) ?? null;
}

// ── OpenAI ────────────────────────────────────────────────────────────────────

export async function callOpenAI(
  prompt: string,
  maxTokens = 600,
): Promise<string | null> {
  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${config.openai.apiKey}`,
    },
    body: JSON.stringify({
      model: config.openai.model,
      messages: [{ role: 'user', content: prompt }],
      max_tokens: maxTokens,
      temperature: 0.7,
    }),
    signal: AbortSignal.timeout(20_000),
  });

  if (!res.ok) return null;
  const data = (await res.json()) as Record<string, unknown>;
  const choices = data['choices'] as Array<Record<string, unknown>> | undefined;
  const message = choices?.[0]?.['message'] as Record<string, unknown> | undefined;
  return (message?.['content'] as string) ?? null;
}

export async function callOpenAIChat(
  messages: Array<{ role: string; content: string }>,
  systemPrompt: string,
  maxTokens = 300,
): Promise<string | null> {
  const allMessages = [
    { role: 'system', content: systemPrompt },
    ...messages,
  ];

  const res = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${config.openai.apiKey}`,
    },
    body: JSON.stringify({
      model: config.openai.model,
      messages: allMessages,
      max_tokens: maxTokens,
      temperature: 0.7,
    }),
    signal: AbortSignal.timeout(20_000),
  });

  if (!res.ok) return null;
  const data = (await res.json()) as Record<string, unknown>;
  const choices = data['choices'] as Array<Record<string, unknown>> | undefined;
  const message = choices?.[0]?.['message'] as Record<string, unknown> | undefined;
  return (message?.['content'] as string) ?? null;
}

// ── Claude ────────────────────────────────────────────────────────────────────

export async function callClaude(
  prompt: string,
  maxTokens = 600,
): Promise<string | null> {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': config.claude.apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: config.claude.model,
      max_tokens: maxTokens,
      messages: [{ role: 'user', content: prompt }],
    }),
    signal: AbortSignal.timeout(20_000),
  });

  if (!res.ok) return null;
  const data = (await res.json()) as Record<string, unknown>;
  const content = data['content'] as Array<Record<string, unknown>> | undefined;
  return (content?.[0]?.['text'] as string) ?? null;
}

export async function callClaudeChat(
  messages: Array<{ role: string; content: string }>,
  systemPrompt: string,
  maxTokens = 300,
): Promise<string | null> {
  const res = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': config.claude.apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: config.claude.model,
      max_tokens: maxTokens,
      system: systemPrompt,
      messages,
    }),
    signal: AbortSignal.timeout(20_000),
  });

  if (!res.ok) return null;
  const data = (await res.json()) as Record<string, unknown>;
  const content = data['content'] as Array<Record<string, unknown>> | undefined;
  return (content?.[0]?.['text'] as string) ?? null;
}

// ── Router unificato ──────────────────────────────────────────────────────────

export async function callAI(
  provider: AiProvider,
  prompt: string,
  maxTokens = 600,
): Promise<string | null> {
  switch (provider) {
    case 'gemini': return callGemini(prompt, maxTokens);
    case 'openai': return callOpenAI(prompt, maxTokens);
    case 'claude': return callClaude(prompt, maxTokens);
  }
}

export async function callAIChat(
  provider: AiProvider,
  messages: Array<{ role: string; content: string }>,
  systemPrompt: string,
  maxTokens = 300,
): Promise<string | null> {
  switch (provider) {
    case 'gemini': return callGeminiChat(messages, systemPrompt, maxTokens);
    case 'openai': return callOpenAIChat(messages, systemPrompt, maxTokens);
    case 'claude': return callClaudeChat(messages, systemPrompt, maxTokens);
  }
}
