import { Request, Response, NextFunction } from 'express';
import { config } from '../config/env';

/**
 * Middleware di autenticazione leggero.
 * L'app Flutter invia il segreto nell'header X-App-Secret.
 * In produzione considera di aggiungere Firebase Auth JWT verification.
 */
export function requireAppSecret(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  // In development senza segreto configurato, bypassa il controllo
  if (!config.appSecret || config.nodeEnv === 'development') {
    next();
    return;
  }

  const secret = req.headers['x-app-secret'] as string | undefined;

  if (!secret || secret !== config.appSecret) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  next();
}
