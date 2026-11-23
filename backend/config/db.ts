import { Pool, PoolConfig } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const rawDatabaseUrl = process.env.DATABASE_URL?.trim();
const isRemoteHost =
  Boolean(process.env.DB_HOST) &&
  process.env.DB_HOST !== 'localhost' &&
  process.env.DB_HOST !== '127.0.0.1';

const poolConfig: PoolConfig = rawDatabaseUrl
  ? {
      connectionString: rawDatabaseUrl.replace(
        /([?&])sslmode=[^&]+(&|$)/i,
        (_, prefix, suffix) => (suffix === '&' ? prefix : '')
      ),
      ssl: {
        rejectUnauthorized: false,
      },
    }
  : {
      host: process.env.DB_HOST || 'localhost',
      port: Number(process.env.DB_PORT) || 5432,
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'ujilevel',
      ...(isRemoteHost || process.env.DB_SSL === 'true'
          ? { ssl: { rejectUnauthorized: false } }
          : {}),
    };

export const pool = new Pool(poolConfig);

export async function initDatabase(): Promise<void> {
  try {
    const client = await pool.connect();
    console.log(`Database connected: ${process.env.DB_NAME || 'ujilevel'}`);

    // Pastikan seluruh tabel dasar selalu ada di database PostgreSQL
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        email VARCHAR(100) NOT NULL UNIQUE,
        password VARCHAR(255) NOT NULL,
        role VARCHAR(20) NOT NULL DEFAULT 'penyewa',
        created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS kategori (
        id_kategori SERIAL PRIMARY KEY,
        jenis_olahraga VARCHAR(50) NOT NULL UNIQUE,
        keterangan TEXT,
        created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS lapangan (
        id SERIAL PRIMARY KEY,
        id_kategori INT REFERENCES kategori(id_kategori) ON DELETE SET NULL,
        nama_lapangan VARCHAR(100) NOT NULL,
        jenis_olahraga VARCHAR(50) NOT NULL,
        harga_per_jam DECIMAL(12, 2) NOT NULL,
        deskripsi TEXT,
        foto_lapangan VARCHAR(255),
        latitude DOUBLE PRECISION,
        longitude DOUBLE PRECISION,
        alamat TEXT,
        created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );

      ALTER TABLE lapangan ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
      ALTER TABLE lapangan ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
      ALTER TABLE lapangan ADD COLUMN IF NOT EXISTS alamat TEXT;

      CREATE TABLE IF NOT EXISTS bookings (
        id SERIAL PRIMARY KEY,
        user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        lapangan_id INT NOT NULL REFERENCES lapangan(id) ON DELETE CASCADE,
        tanggal_sewa DATE NOT NULL,
        jam_mulai VARCHAR(10) NOT NULL,
        durasi_jam INT NOT NULL,
        total_harga DECIMAL(12, 2) NOT NULL,
        bukti_bayar VARCHAR(255),
        status_booking VARCHAR(20) NOT NULL DEFAULT 'pending',
        created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    client.release();
  } catch (error: any) {
    console.error('Database connection / init failed:', error.message);
  }
}
