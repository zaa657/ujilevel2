import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../config/db';
import { AuthRequest, UserPayload } from '../middleware/authMiddleware';

const JWT_SECRET = process.env.JWT_SECRET || 'sportbook_ujilevel_secret_key_2026';

function signUserToken(user: UserPayload): string {
  return jwt.sign(
    { id: user.id, name: user.name, email: user.email, role: user.role },
    JWT_SECRET,
    { expiresIn: '24h' }
  );
}

export async function register(req: Request, res: Response): Promise<void> {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      res.status(400).json({
        success: false,
        message: 'Nama, email, dan password wajib diisi',
      });
      return;
    }

    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      res.status(400).json({
        success: false,
        message: 'Format email tidak valid',
      });
      return;
    }

    if (String(password).length < 6) {
      res.status(400).json({
        success: false,
        message: 'Password minimal 6 karakter',
      });
      return;
    }

    const normalizedEmail = String(email).trim().toLowerCase();
    const existing = await pool.query('SELECT id FROM users WHERE email = $1', [normalizedEmail]);
    if (existing.rows.length > 0) {
      res.status(409).json({
        success: false,
        message: 'Email sudah terdaftar',
      });
      return;
    }

    const hashedPassword = await bcrypt.hash(String(password), 10);
    const result = await pool.query(
      `INSERT INTO users (name, email, password, role)
       VALUES ($1, $2, $3, 'penyewa')
       RETURNING id, name, email, role, created_at`,
      [String(name).trim(), normalizedEmail, hashedPassword]
    );

    const user = result.rows[0];
    res.status(201).json({
      success: true,
      message: 'Registrasi akun berhasil',
      data: { token: signUserToken(user), user },
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server saat registrasi',
    });
  }
}

export async function login(req: Request, res: Response): Promise<void> {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      res.status(400).json({
        success: false,
        message: 'Email dan password wajib diisi',
      });
      return;
    }

    const normalizedEmail = String(email).trim().toLowerCase();
    const result = await pool.query(
      'SELECT id, name, email, password, role FROM users WHERE email = $1',
      [normalizedEmail]
    );

    const user = result.rows[0];
    if (!user || !(await bcrypt.compare(String(password), user.password))) {
      res.status(401).json({
        success: false,
        message: 'Email atau password salah',
      });
      return;
    }

    const userPayload: UserPayload = {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
    };

    res.status(200).json({
      success: true,
      message: 'Login berhasil',
      data: {
        token: signUserToken(userPayload),
        user: userPayload,
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server saat login',
    });
  }
}

export async function getProfile(req: AuthRequest, res: Response): Promise<void> {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const result = await pool.query(
      'SELECT id, name, email, role, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ success: false, message: 'User tidak ditemukan' });
      return;
    }

    res.status(200).json({
      success: true,
      message: 'Berhasil mengambil profil pengguna',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Terjadi kesalahan pada server',
    });
  }
}
