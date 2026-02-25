/// Configurazione del backend AI proxy.
///
/// Dopo il deploy del backend (vedi /backend/README.md):
/// 1. Imposta [backendUrl] con l'URL del tuo server
/// 2. Imposta [appSecret] con il valore di APP_SECRET nel .env del backend
///
/// Finché [backendUrl] è vuoto, l'app usa le chiamate dirette ai provider AI
/// (solo per sviluppo — richiede chiave API salvata nelle impostazioni).
class AppConfig {
  AppConfig._();

  // ── Backend proxy ─────────────────────────────────────────────────────────
  // Inserisci l'URL del backend dopo il deploy (senza slash finale).
  // Esempio: 'https://mindstep-api.railway.app'
  static const String backendUrl = '';

  // Segreto condiviso con il backend (valore di APP_SECRET nel .env del server).
  // Deve corrispondere esattamente. Tenere fuori dal version control in produzione.
  static const String appSecret = '';

  /// True se il backend è configurato e può essere usato
  static bool get isBackendConfigured =>
      backendUrl.isNotEmpty && appSecret.isNotEmpty;

  // ── Timeout ───────────────────────────────────────────────────────────────
  static const Duration aiTimeout = Duration(seconds: 20);
  static const Duration weatherTimeout = Duration(seconds: 8);
}
