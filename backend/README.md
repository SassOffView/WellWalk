# MindStep Backend — AI Proxy

Server Node.js/Express che gestisce tutte le chiamate AI lato server.
L'app Flutter non contiene mai API key — tutte le richieste passano da qui.

## Struttura

```
src/
├── index.ts              Entry point + Express app
├── config/env.ts         Lettura variabili .env
├── middleware/auth.ts    Verifica X-App-Secret header
└── handlers/
    ├── ai_client.ts      Client unificato Gemini/OpenAI/Claude
    ├── insight.ts        POST /ai/insight
    ├── coach.ts          POST /ai/coach
    └── phrase.ts         POST /ai/phrase
```

## Setup locale

```bash
cd backend
npm install
cp .env.example .env
# Edita .env con le tue API key
npm run dev
```

## Endpoints

### `GET /health`
Verifica stato del server e provider configurati.

### `POST /ai/insight`
Genera insight giornaliero basato sul contesto utente.
```json
// Request
{ "provider": "gemini|openai|claude", "userContext": "..." }
// Response
{ "insight": "...", "suggestion": "...", "brainstormPrompt": "...",
  "motivationalMessage": "...", "routineTip": null, "walkTip": null, "generatedBy": "gemini" }
```

### `POST /ai/coach`
Sessione di coaching conversazionale.
```json
// Request
{ "provider": "claude", "messages": [{"role": "user", "content": "..."}] }
// Response
{ "reply": "..." }
```

### `POST /ai/phrase`
Frase motivazionale breve (max 12 parole).
```json
// Request
{ "provider": "claude", "context": "..." }
// Response
{ "phrase": "..." }
```

## Autenticazione

Tutti gli endpoint `/ai/*` richiedono l'header:
```
X-App-Secret: <valore di APP_SECRET nel .env>
```

## Deploy

### Railway (consigliato)
1. Crea progetto su railway.app
2. Connetti la cartella `backend/`
3. Aggiungi le variabili d'ambiente dal `.env.example`
4. Railway fa il build e deploy automaticamente

### Render
1. New Web Service → connect repo → Root Directory: `backend`
2. Build Command: `npm install && npm run build`
3. Start Command: `npm start`
4. Environment Variables: aggiungi dal `.env.example`

### Fly.io
```bash
cd backend
fly launch
fly secrets set GEMINI_API_KEY=... OPENAI_API_KEY=... CLAUDE_API_KEY=... APP_SECRET=...
fly deploy
```

## Configurazione nell'app Flutter

Dopo il deploy, imposta l'URL in:
```dart
// lib/core/config/app_config.dart
static const backendUrl = 'https://tuo-backend.railway.app';
static const appSecret = 'il-tuo-app-secret';
```
