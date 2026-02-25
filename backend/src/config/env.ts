import * as dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT ?? '3000', 10),
  nodeEnv: process.env.NODE_ENV ?? 'development',
  appSecret: process.env.APP_SECRET ?? '',

  // AI providers
  gemini: {
    apiKey: process.env.GEMINI_API_KEY ?? '',
    model: process.env.GEMINI_MODEL ?? 'gemini-1.5-flash',
  },
  openai: {
    apiKey: process.env.OPENAI_API_KEY ?? '',
    model: process.env.OPENAI_MODEL ?? 'gpt-4o-mini',
  },
  claude: {
    apiKey: process.env.CLAUDE_API_KEY ?? '',
    model: process.env.CLAUDE_MODEL ?? 'claude-haiku-4-5-20251001',
  },

  // Rate limiting
  rateLimit: {
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS ?? '60000', 10),
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS ?? '30', 10),
  },
} as const;

/** Provider supportati */
export type AiProvider = 'gemini' | 'openai' | 'claude';

/** Verifica che il provider abbia una chiave configurata */
export function isProviderConfigured(provider: AiProvider): boolean {
  switch (provider) {
    case 'gemini':  return config.gemini.apiKey.length > 0;
    case 'openai':  return config.openai.apiKey.length > 0;
    case 'claude':  return config.claude.apiKey.length > 0;
  }
}
