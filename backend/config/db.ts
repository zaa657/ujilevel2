import { Pool, PoolConfig } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const rawUrl = process.env.DATABASE_URL?.trim();
const isRemote = Boolean(process.env.DB_HOST && !['localhost', '127.0.0.1'].includes(process.env.DB_HOST));

const poolConfig: PoolConfig = rawUrl
  ? {
      connectionString: rawUrl.replace(/([?&])sslmode=[^&]+(&|$)/i, (_, p, s) => (s === '&' ? p : '')),
      ssl: { rejectUnauthorized: false },
    }
  : {
      host: process.env.DB_HOST || 'localhost',
      port: Number(process.env.DB_PORT) || 5432,
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'ujilevel',
      ...(isRemote || process.env.DB_SSL === 'true' ? { ssl: { rejectUnauthorized: false } } : {}),
    };

export const pool = new Pool(poolConfig);
