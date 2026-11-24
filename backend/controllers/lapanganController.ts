import { Request, Response } from 'express';
import fs from 'fs';
import path from 'path';
import { pool } from '../config/db';
import { getUploadDir } from '../config/paths';

const LAPANGAN_SELECT_SQL = `
  SELECT l.id, l.id_kategori, l.nama_lapangan, l.jenis_olahraga, l.harga_per_jam,
         l.deskripsi, l.foto_lapangan, l.created_at, l.updated_at,
         k.keterangan AS keterangan_kategori
  FROM lapangan l
  LEFT JOIN kategori k ON l.id_kategori = k.id_kategori
`;

function resolveUploadedUrl(file?: Express.Multer.File): string | null {
  if (!file) return null;
  return file.filename.startsWith('http') ? file.filename : `/uploads/${file.filename}`;
}

function removeUploadedFile(filePath?: string | null): void {
  if (!filePath || filePath.startsWith('http')) return;
  const fullPath = path.join(getUploadDir(), path.basename(filePath));
  if (fs.existsSync(fullPath)) {
    try { fs.unlinkSync(fullPath); } catch {}
  }
}

function fail(res: Response, code: number, message: string, file?: Express.Multer.File): void {
  if (file) removeUploadedFile(file.filename);
  res.status(code).json({ success: false, message });
}

export async function getAllLapangan(_req: Request, res: Response): Promise<void> {
  try {
    const result = await pool.query(`${LAPANGAN_SELECT_SQL} ORDER BY l.id DESC`);
    res.status(200).json({
      success: true,
      message: 'Berhasil mengambil daftar lapangan olahraga',
      data: result.rows,
    });
  } catch (error) {
    console.error('Get lapangan error:', error);
    fail(res, 500, 'Gagal mengambil daftar lapangan olahraga');
  }
}

export async function getLapanganById(req: Request, res: Response): Promise<void> {
  try {
    const result = await pool.query(`${LAPANGAN_SELECT_SQL} WHERE l.id = $1`, [req.params.id]);
    if (result.rows.length === 0) return fail(res, 404, 'Data lapangan tidak ditemukan');
    res.status(200).json({
      success: true,
      message: 'Berhasil mengambil detail lapangan',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Get lapangan by id error:', error);
    fail(res, 500, 'Gagal mengambil detail lapangan');
  }
}

export async function createLapangan(req: Request, res: Response): Promise<void> {
  try {
    const { nama_lapangan, jenis_olahraga, harga_per_jam, deskripsi, id_kategori } = req.body;
    let resolvedJenis = jenis_olahraga ? String(jenis_olahraga).trim() : '';
    let resolvedKategoriId: number | null = id_kategori ? Number(id_kategori) : null;

    if (!resolvedJenis && resolvedKategoriId) {
      const katRow = await pool.query('SELECT jenis_olahraga FROM kategori WHERE id_kategori = $1', [resolvedKategoriId]);
      if (katRow.rows[0]) resolvedJenis = katRow.rows[0].jenis_olahraga;
    }

    if (!nama_lapangan || !resolvedJenis || harga_per_jam === undefined || harga_per_jam === '') {
      return fail(res, 400, 'Nama lapangan, jenis olahraga, dan harga per jam wajib diisi', req.file);
    }

    const parsedHarga = Number(harga_per_jam);
    if (isNaN(parsedHarga) || parsedHarga <= 0) {
      return fail(res, 400, 'Harga per jam harus berupa angka valid lebih dari 0', req.file);
    }

    if (!resolvedKategoriId && resolvedJenis) {
      const checkKat = await pool.query(
        'SELECT id_kategori FROM kategori WHERE LOWER(jenis_olahraga) = LOWER($1) LIMIT 1',
        [resolvedJenis]
      );
      if (checkKat.rows[0]) {
        resolvedKategoriId = checkKat.rows[0].id_kategori;
      } else {
        const newKat = await pool.query(
          'INSERT INTO kategori (jenis_olahraga, keterangan) VALUES ($1, $2) RETURNING id_kategori',
          [resolvedJenis, `Kategori ${resolvedJenis}`]
        );
        resolvedKategoriId = newKat.rows[0].id_kategori;
      }
    }

    const result = await pool.query(
      `INSERT INTO lapangan (id_kategori, nama_lapangan, jenis_olahraga, harga_per_jam, deskripsi, foto_lapangan)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [
        resolvedKategoriId,
        String(nama_lapangan).trim(),
        resolvedJenis,
        parsedHarga,
        deskripsi ? String(deskripsi).trim() : '',
        resolveUploadedUrl(req.file),
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Data lapangan berhasil ditambahkan',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Create lapangan error:', error);
    fail(res, 500, 'Gagal menambahkan data lapangan', req.file);
  }
}

export async function updateLapangan(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const { nama_lapangan, jenis_olahraga, harga_per_jam, deskripsi, id_kategori } = req.body;

    const existing = await pool.query('SELECT * FROM lapangan WHERE id = $1', [id]);
    if (existing.rows.length === 0) return fail(res, 404, 'Data lapangan tidak ditemukan', req.file);

    const cur = existing.rows[0];
    const updatedHarga = harga_per_jam !== undefined && harga_per_jam !== '' ? Number(harga_per_jam) : cur.harga_per_jam;
    if (isNaN(updatedHarga) || updatedHarga <= 0) {
      return fail(res, 400, 'Harga per jam harus berupa angka valid lebih dari 0', req.file);
    }

    let updatedFoto = cur.foto_lapangan;
    if (req.file) {
      if (cur.foto_lapangan) removeUploadedFile(cur.foto_lapangan);
      updatedFoto = resolveUploadedUrl(req.file);
    }

    const result = await pool.query(
      `UPDATE lapangan
       SET id_kategori = $1, nama_lapangan = $2, jenis_olahraga = $3,
           harga_per_jam = $4, deskripsi = $5, foto_lapangan = $6, updated_at = CURRENT_TIMESTAMP
       WHERE id = $7 RETURNING *`,
      [
        id_kategori ? Number(id_kategori) : cur.id_kategori,
        nama_lapangan ? String(nama_lapangan).trim() : cur.nama_lapangan,
        jenis_olahraga ? String(jenis_olahraga).trim() : cur.jenis_olahraga,
        updatedHarga,
        deskripsi !== undefined ? String(deskripsi).trim() : cur.deskripsi,
        updatedFoto,
        id,
      ]
    );

    res.status(200).json({
      success: true,
      message: 'Data lapangan berhasil diperbarui',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Update lapangan error:', error);
    fail(res, 500, 'Gagal memperbarui data lapangan', req.file);
  }
}

export async function deleteLapangan(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const existing = await pool.query('SELECT * FROM lapangan WHERE id = $1', [id]);
    if (existing.rows.length === 0) return fail(res, 404, 'Data lapangan tidak ditemukan');

    const lapanganToDelete = existing.rows[0];
    await pool.query('DELETE FROM lapangan WHERE id = $1', [id]);
    if (lapanganToDelete.foto_lapangan) removeUploadedFile(lapanganToDelete.foto_lapangan);

    res.status(200).json({
      success: true,
      message: 'Data lapangan berhasil dihapus',
      data: lapanganToDelete,
    });
  } catch (error: any) {
    console.error('Delete lapangan error:', error);
    if (error?.code === '23503') {
      return fail(res, 409, 'Lapangan tidak dapat dihapus karena masih memiliki riwayat pemesanan');
    }
    fail(res, 500, 'Gagal menghapus data lapangan');
  }
}
