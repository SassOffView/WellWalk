import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';

import { config } from './config/env';
import { requireAppSecret } from './middleware/auth';
import { handleInsight } from './handlers/insight';
import { handleCoach } from './handlers/coach';
import { handlePhrase } from './handlers/phrase';

const app = express();

// ── Middleware globali ────────────────────────────────────────────────────────
app.use(helmet());
app.use(cors({
  origin: ['capacitor://localhost', 'ionic://localhost', 'http://localhost'],
  methods: ['POST', 'GET', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'X-App-Secret'],
}));
app.use(express.json({ limit: '50kb' }));

// Rate limit globale
app.use(rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.max,
  message: { error: 'Too many requests, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
}));

// ── Healthcheck ───────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({
    status: 'ok',
    version: '1.0.0',
    env: config.nodeEnv,
    providers: {
      gemini: config.gemini.apiKey.length > 0,
      openai: config.openai.apiKey.length > 0,
      claude: config.claude.apiKey.length > 0,
    },
  });
});

// ── Route AI (protette da app secret) ────────────────────────────────────────
const aiRouter = express.Router();
aiRouter.use(requireAppSecret);

aiRouter.post('/insight', handleInsight);
aiRouter.post('/coach',   handleCoach);
aiRouter.post('/phrase',  handlePhrase);

app.use('/ai', aiRouter);

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

// ── Start ─────────────────────────────────────────────────────────────────────
app.listen(config.port, () => {
  console.log(`✅ MindStep backend running on port ${config.port} [${config.nodeEnv}]`);
  console.log(`   Providers: gemini=${config.gemini.apiKey.length > 0} openai=${config.openai.apiKey.length > 0} claude=${config.claude.apiKey.length > 0}`);
});

export default app;
