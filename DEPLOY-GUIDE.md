# 🚀 GUIDA DEPLOY GITHUB PAGES - PASSO DOPO PASSO

## ✅ PREREQUISITI
- Account GitHub (hai già ✅)
- Browser (Safari/Chrome)
- 10 minuti di tempo

---

## 📱 STEP 1: PREPARA I FILE

Hai già tutti i file pronti in questa cartella:
```
wellwalk-pwa/
├── index.html          ✅ App principale
├── app.js              ✅ Logica JavaScript
├── manifest.json       ✅ PWA config
├── service-worker.js   ✅ Offline support
├── README.md           ✅ Documentazione
├── icon-192.png        ⏳ Da creare (vedi sotto)
└── icon-512.png        ⏳ Da creare (vedi sotto)
```

### Come Creare le Icone (2 opzioni):

**OPZIONE A - Veloce (Placeholder):**
1. Vai su https://via.placeholder.com/192x192/52a6e0/ffffff?text=WW
2. Click destro → Salva immagine come → `icon-192.png`
3. Vai su https://via.placeholder.com/512x512/52a6e0/ffffff?text=WW
4. Click destro → Salva immagine come → `icon-512.png`

**OPZIONE B - Professionale (Consigliato):**
1. Usa Canva/Figma per creare logo 512x512px
2. Esporta come PNG
3. Rinomina: `icon-512.png`
4. Resize a 192x192px → `icon-192.png`

---

## 📦 STEP 2: CREA REPOSITORY GITHUB

1. **Vai su GitHub.com** e fai login

2. **Click su "+" in alto a destra** → "New repository"

3. **Compila il form:**
   - Repository name: `wellwalk` (o qualsiasi nome)
   - Description: "WellWalk Pro - Progressive Web App"
   - ✅ Public
   - ✅ Add README file
   - Click "Create repository"

4. **Hai creato il repo! 🎉**

---

## 📤 STEP 3: UPLOAD FILES

### Metodo A: Via Web (PIÙ FACILE)

1. **Nel repository appena creato, click su "Add file" → "Upload files"**

2. **Trascina TUTTI i file dalla cartella `wellwalk-pwa`:**
   - index.html
   - app.js
   - manifest.json  
   - service-worker.js
   - icon-192.png
   - icon-512.png
   - README.md

3. **Scrivi commit message:** "Initial commit - WellWalk Pro v4.2"

4. **Click "Commit changes"**

5. **Files uploaded! ✅**

### Metodo B: Via Git (se preferisci terminale)

```bash
# Clone del repo
git clone https://github.com/tuousername/wellwalk.git
cd wellwalk

# Copia tutti i file
cp /path/to/wellwalk-pwa/* .

# Commit e push
git add .
git commit -m "Initial commit - WellWalk Pro v4.2"
git push origin main
```

---

## 🌐 STEP 4: ABILITA GITHUB PAGES

1. **Nel repository, vai su "Settings"** (tab in alto)

2. **Nel menu laterale sinistro, click su "Pages"**

3. **Sotto "Source":**
   - Branch: seleziona `main` (o `master`)
   - Folder: seleziona `/ (root)`
   - Click "Save"

4. **ASPETTA 1-2 MINUTI** (GitHub sta deployando...)

5. **Refresh la pagina Settings → Pages**

6. **Vedrai un messaggio verde:**
   ```
   Your site is published at https://tuousername.github.io/wellwalk/
   ```

7. **COPIA QUESTO URL!** 📋

---

## 📱 STEP 5: TESTA SU IPHONE

### Prima Verifica - Desktop
1. **Apri l'URL** nel browser (Chrome/Safari)
2. **Verifica che l'app funzioni**
3. **Testa le varie sezioni**

### Installazione iPhone
1. **Invia l'URL a te stesso** (WhatsApp/Email)
2. **Su iPhone, apri il link con Safari** (IMPORTANTE: deve essere Safari!)
3. **Tap sull'icona Condividi** (quadrato con freccia ↑)
4. **Scorri e tap "Aggiungi a Home"**
5. **Tap "Aggiungi"**
6. **L'icona WellWalk apparirà sulla tua Home! 🎉**

---

## 🧪 STEP 6: BETA TEST

### Condividi con Beta Testers (5-10 persone)

**Link da condividere:**
```
https://tuousername.github.io/wellwalk/
```

**Istruzioni per tester:**
```
🌱 WellWalk Pro - Beta Test

Ciao! Grazie per testare la mia app.

INSTALLAZIONE:
1. Apri questo link con Safari su iPhone
2. Tap icona Condividi (↑)
3. Tap "Aggiungi a Home"
4. L'app è installata!

COSA TESTARE:
✅ Creazione profilo e routine
✅ Timer camminata con GPS
✅ Registrazione note vocali
✅ Sistema badge
✅ Dark mode
✅ Meteo (appare in alto)
✅ Quote motivazionali

FEEDBACK:
Compila questo form con bugs/suggerimenti:
[Link Google Form]

Grazie! 🙏
```

### Crea Google Form per Feedback

1. Vai su https://forms.google.com
2. "+" Nuovo form
3. Titolo: "WellWalk Pro - Beta Feedback"
4. Domande:
   - Nome (facoltativo)
   - Cosa ti è piaciuto?
   - Cosa miglioreresti?
   - Bug riscontrati?
   - Valutazione 1-5 stelle
5. Invia link ai tester

---

## 🔧 STEP 7: AGGIORNAMENTI

### Quando vuoi aggiornare l'app:

1. **Modifica i file localmente**
2. **Va su GitHub repository**
3. **Click sul file da aggiornare**
4. **Click icona matita (Edit)**
5. **Modifica il codice**
6. **Scroll down → "Commit changes"**
7. **L'app si aggiorna automaticamente!** (refresh browser)

---

## 🐛 TROUBLESHOOTING

### L'app non si carica
- ✅ Verifica che tutti i file siano caricati
- ✅ Controlla che GitHub Pages sia abilitato
- ✅ Aspetta 2-3 minuti dopo il deploy
- ✅ Prova in modalità incognito

### Le icone non appaiono
- ✅ Verifica che icon-192.png e icon-512.png esistano
- ✅ Controlla che i nomi siano ESATTI (case-sensitive)
- ✅ Ricarica la pagina con Cmd+Shift+R (Mac) o Ctrl+Shift+R (Win)

### Meteo non funziona
- ✅ Abilita geolocalizzazione nel browser
- ✅ Usa API key personale (vedi sotto)

### Voice recording non funziona
- ✅ Usa Chrome o Edge (non Safari su iOS < 14.5)
- ✅ Concedi permesso microfono
- ✅ Usa textarea come fallback

---

## 🔑 API KEYS (IMPORTANTE!)

### OpenWeatherMap API

L'app usa una chiave DEMO limitata. Per produzione:

1. Vai su https://openweathermap.org/api
2. "Get API key" → Sign up (gratis)
3. Copia la tua API key
4. Modifica `app.js` linea 2:
   ```javascript
   // Da:
   const WEATHER_API_KEY='DEMO_KEY';
   // A:
   const WEATHER_API_KEY='TUA_API_KEY_QUI';
   ```
5. Commit e push

**Free tier:** 60 calls/min, 1M calls/mese (più che sufficiente!)

---

## 📊 ANALYTICS (Opzionale)

### Aggiungi Google Analytics:

1. Vai su https://analytics.google.com
2. Crea property "WellWalk Pro"
3. Copia il tracking code
4. Aggiungi in `index.html` prima di `</head>`:
   ```html
   <!-- Google Analytics -->
   <script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXX"></script>
   <script>
     window.dataLayer = window.dataLayer || [];
     function gtag(){dataLayer.push(arguments);}
     gtag('js', new Date());
     gtag('config', 'G-XXXXXXXX');
   </script>
   ```

---

## 🚀 PROSSIMI STEP

### Dopo Beta Test (1-2 settimane):

1. **Raccogli feedback**
2. **Implementa miglioramenti**
3. **Deploy v4.3 con fix**

### Preparati per Native App (2-3 settimane):

1. **React Native setup**
2. **HealthKit integration**
3. **App Store submission**

---

## ❓ DOMANDE FREQUENTI

**Q: Posso usare un dominio custom?**
A: Sì! Settings → Pages → Custom domain

**Q: L'app funziona offline?**
A: Sì, grazie al Service Worker

**Q: Posso monetizzare?**
A: Sì, ma serve app nativa per In-App Purchases

**Q: Quanti utenti supporta?**
A: GitHub Pages: 100GB bandwidth/mese = ~100,000 visite/mese

**Q: È sicuro?**
A: Sì, tutti i dati sono salvati LOCALMENTE sul dispositivo

---

## 📞 SUPPORTO

Hai problemi? 
- Rileggi questa guida
- Controlla i log console (F12 → Console)
- Chiedi aiuto con screenshot dell'errore

---

## 🎉 CONGRATULAZIONI!

Hai deployato la tua PWA! 

**URL della tua app:**
```
https://tuousername.github.io/wellwalk/
```

**Condividi con i tester e raccogli feedback!**

**Il team WellWalk è con te! 🌱💪**
