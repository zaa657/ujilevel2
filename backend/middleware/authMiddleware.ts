import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export interface UserPayload {
  id: number;
  name: string;
  email: string;
  role: 'admin' | 'penyewa';
}

export interface AuthRequest extends Request {
  user?: UserPayload;
}

export function verifyToken(req: AuthRequest, res: Response, next: NextFunction): void {
  const authHeader = req.headers['authorization'];
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({
      success: false,
      message: 'Token otentikasi diperlukan',
    });
    return;
  }

  const token = authHeader.split(' ')[1];
  try {
    const decoded = jwt.verify(
      token,
      process.env.JWT_SECRET || 'sportbook_ujilevel_secret_key_2026'
    ) as UserPayload;
    req.user = decoded;
    next();
  } catch {
    res.status(401).json({
      success: false,
      message: 'Token tidak valid atau kedaluwarsa',
    });
  }
}

export function authorizeRole(...allowedRoles: Array<'admin' | 'penyewa'>) {
  return (req: AuthRequest, res: Response, next: NextFunction): void => {
    if (!req.user || !allowedRoles.includes(req.user.role)) {
      res.status(403).json({
        success: false,
        message: 'Akses ditolak: hak akses tidak mencukupi',
      });
      return;
    }
    next();
  };
}
