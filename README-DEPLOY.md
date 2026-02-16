# 🚀 MINDSTEP v5.0 - GUIDA DEPLOY

## ✅ FILES PRONTI

```
mindstep-v5/
├── index.html          ✅ App completa (120KB)
├── manifest.json       ✅ PWA config
├── service-worker.js   ✅ Offline support
├── logo.svg            ✅ Logo SVG
├── wave-icon.svg       ✅ Wave animation
└── icon-192.png        ⏳ Da aggiungere
└── icon-512.png        ⏳ Da aggiungere
```

## 📱 STEP 1: PREPARA ICONE

Hai l'icona MindStep originale. Devi creare 2 versioni:

**Metodo A - Manuale:**
1. Apri l'icona in editor immagini
2. Resize a 192x192px → Salva come `icon-192.png`
3. Resize a 512x512px → Salva come `icon-512.png`
4. Metti i file in questa cartella

**Metodo B - Online:**
1. Vai su https://www.iloveimg.com/resize-image
2. Upload icona MindStep
3. Resize a 192x192 → Download `icon-192.png`
4. Ripeti per 512x512 → Download `icon-512.png`

## 📤 STEP 2: DEPLOY GITHUB

1. Vai su tuo repository GitHub: wellwalk
2. **CANCELLA tutti i file vecchi** (importante!)
3. Click "Add file" → "Upload files"
4. **Trascina TUTTI i file da questa cartella:**
   - index.html
   - manifest.json
   - service-worker.js
   - logo.svg
   - wave-icon.svg
   - icon-192.png
   - icon-512.png
5. Commit message: "MindStep v5.0 - Complete Redesign"
6. Click "Commit changes"
7. **Aspetta 2-3 minuti** per rebuild
8. Apri URL: https://tuousername.github.io/wellwalk/

## 🎉 STEP 3: TEST

### Su PC:
1. Apri URL in Chrome/Edge
2. Testa tutte le funzioni
3. Verifica che tutto funzioni

### Su iPhone:
1. Apri URL con **Safari**
2. Tap Condividi (↑)
3. "Aggiungi a Home"
4. Apri MindStep dalla home
5. Testa GPS, recording, etc.

## 🐛 SE QUALCOSA NON VA

**Cache vecchia?**
- Ctrl+Shift+R (PC) o Cmd+Shift+R (Mac)
- iPhone: Settings → Safari → Clear History and Data

**GPS non funziona?**
- Verifica permessi location in Settings
- HTTPS è richiesto (GitHub Pages ok)

**Recording non funziona?**
- Usa Chrome o Edge su PC
- Safari iOS funziona ma richiede permesso

## ✨ NOVITÀ v5.0

**Rebrand Completo:**
- Nome: MindStep (non più WellWalk)
- Logo: Nuovo design brain wave + path
- Colori: Palette cyan/navy professionale
- Font: Inter (più moderno)

**Architettura Nuova:**
- Menu orizzontale fisso in alto
- 5 tab: Home, Storico, Dati, Traguardi, Altro
- Header con meteo e streak sempre visibili

**Bug Fix (tutti risolti):**
- GPS tracking iPhone corretto
- Recording non sovrascritto
- Routine management stabile
- Export funzionante
- Calendario navigabile
- Popup X visibile
- Dark mode con 3 stati (Light/Auto/Dark)

**Features Nuove:**
- AI Integration (Claude, ChatGPT, Gemini, Copilot)
- Export note con invio diretto ad AI
- Timer circolare professionale
- Sistema notifiche milestone
- Badge scroll automatico
- Meteo real-time (richiede API key)
- Quote dinamiche da API

**Trial 7 giorni implementato:**
- Sistema pronto per versione PRO
- Limiti free/pro definiti

## 🔑 API KEYS (OPZIONALE)

**OpenWeatherMap:**
Se vuoi meteo funzionante:
1. Signup su https://openweathermap.org/api (gratis)
2. Copia API key
3. Apri index.html su GitHub
4. Cerca: `const WEATHER_API_KEY='';`
5. Sostituisci con: `const WEATHER_API_KEY='TUA_KEY';`
6. Commit

## 📞 SUPPORTO

Problemi? Controlla:
1. Tutti i file uploadati
2. Icone PNG esistono
3. Cache pulita
4. Permessi GPS/Mic abilitati

---

**FATTO! MINDSTEP v5.0 È PRONTO! 🎉**
