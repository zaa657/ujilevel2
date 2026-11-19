import { Request, Response } from 'express';
import fs from 'fs';
import path from 'path';
import { pool } from '../config/db';
import { getUploadDir } from '../config/paths';

function removeUploadedFile(filePath?: string | null): void {
  if (!filePath) return;
  const fileName = path.basename(filePath);
  const fullPath = path.join(getUploadDir(), fileName);
  if (fs.existsSync(fullPath)) {
    try {
      fs.unlinkSync(fullPath);
    } catch (err: any) {
      console.error('Failed to remove file:', err.message);
    }
  }
}

export async function getAllLapangan(_req: Request, res: Response): Promise<void> {
  try {
    const result = await pool.query(`
      SELECT 
        l.id,
        l.id_kategori,
        l.nama_lapangan,
        l.jenis_olahraga,
        l.harga_per_jam,
        l.deskripsi,
        l.foto_lapangan,
        l.latitude,
        l.longitude,
        l.alamat,
        l.created_at,
        l.updated_at,
        k.keterangan AS keterangan_kategori
      FROM lapangan l
      LEFT JOIN kategori k ON l.id_kategori = k.id_kategori
      ORDER BY l.id DESC
    `);

    res.status(200).json({
      success: true,
      message: 'Berhasil mengambil daftar lapangan olahraga',
      data: result.rows,
    });
  } catch (error) {
    console.error('Get lapangan error:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal mengambil daftar lapangan olahraga',
    });
  }
}

export async function getLapanganById(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `SELECT 
        l.id,
        l.id_kategori,
        l.nama_lapangan,
        l.jenis_olahraga,
        l.harga_per_jam,
        l.deskripsi,
        l.foto_lapangan,
        l.latitude,
        l.longitude,
        l.alamat,
        l.created_at,
        l.updated_at,
        k.keterangan AS keterangan_kategori
      FROM lapangan l
      LEFT JOIN kategori k ON l.id_kategori = k.id_kategori
      WHERE l.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      res.status(404).json({
        success: false,
        message: 'Data lapangan tidak ditemukan',
      });
      return;
    }

    res.status(200).json({
      success: true,
      message: 'Berhasil mengambil detail lapangan',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Get lapangan by id error:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal mengambil detail lapangan',
    });
  }
}

export async function createLapangan(req: Request, res: Response): Promise<void> {
  try {
    const { nama_lapangan, jenis_olahraga, harga_per_jam, deskripsi, id_kategori } = req.body;

    let resolvedJenis = jenis_olahraga ? String(jenis_olahraga).trim() : '';
    let resolvedKategoriId: number | null = id_kategori ? Number(id_kategori) : null;

    if (!resolvedJenis && resolvedKategoriId) {
      const katRow = await pool.query('SELECT jenis_olahraga FROM kategori WHERE id_kategori = $1', [resolvedKategoriId]);
      if (katRow.rows.length > 0) {
        resolvedJenis = katRow.rows[0].jenis_olahraga;
      }
    }

    if (!nama_lapangan || !resolvedJenis || harga_per_jam === undefined || harga_per_jam === '') {
      if (req.file) removeUploadedFile(req.file.filename);
      res.status(400).json({
        success: false,
        message: 'Nama lapangan, jenis olahraga, dan harga per jam wajib diisi',
      });
      return;
    }

    const parsedHarga = Number(harga_per_jam);
    if (isNaN(parsedHarga) || parsedHarga <= 0) {
      if (req.file) removeUploadedFile(req.file.filename);
      res.status(400).json({
        success: false,
        message: 'Harga per jam harus berupa angka valid lebih dari 0',
      });
      return;
    }

    if (!resolvedKategoriId && resolvedJenis) {
      const checkKat = await pool.query(
        'SELECT id_kategori FROM kategori WHERE LOWER(jenis_olahraga) = LOWER($1) LIMIT 1',
        [resolvedJenis]
      );
      if (checkKat.rows.length > 0) {
        resolvedKategoriId = checkKat.rows[0].id_kategori;
      } else {
        const newKat = await pool.query(
          'INSERT INTO kategori (jenis_olahraga, keterangan) VALUES ($1, $2) RETURNING id_kategori',
          [resolvedJenis, `Kategori ${resolvedJenis}`]
        );
        resolvedKategoriId = newKat.rows[0].id_kategori;
      }
    }

    const fotoPath = req.file ? `/uploads/${req.file.filename}` : null;

    const result = await pool.query(
      `INSERT INTO lapangan (id_kategori, nama_lapangan, jenis_olahraga, harga_per_jam, deskripsi, foto_lapangan)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        resolvedKategoriId,
        String(nama_lapangan).trim(),
        resolvedJenis,
        parsedHarga,
        deskripsi ? String(deskripsi).trim() : '',
        fotoPath,
      ]
    );

    res.status(201).json({
      success: true,
      message: 'Data lapangan berhasil ditambahkan',
      data: result.rows[0],
    });
  } catch (error) {
    if (req.file) removeUploadedFile(req.file.filename);
    console.error('Create lapangan error:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal menambahkan data lapangan',
    });
  }
}

export async function updateLapangan(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const { nama_lapangan, jenis_olahraga, harga_per_jam, deskripsi, id_kategori } = req.body;

    const existing = await pool.query('SELECT * FROM lapangan WHERE id = $1', [id]);
    if (existing.rows.length === 0) {
      if (req.file) removeUploadedFile(req.file.filename);
      res.status(404).json({
        success: false,
        message: 'Data lapangan tidak ditemukan',
      });
      return;
    }

    const currentLapangan = existing.rows[0];

    const updatedNama = nama_lapangan
      ? String(nama_lapangan).trim()
      : currentLapangan.nama_lapangan;
    const updatedJenis = jenis_olahraga
      ? String(jenis_olahraga).trim()
      : currentLapangan.jenis_olahraga;
    const updatedHarga =
      harga_per_jam !== undefined && harga_per_jam !== ''
        ? Number(harga_per_jam)
        : currentLapangan.harga_per_jam;
    const updatedDeskripsi =
      deskripsi !== undefined ? String(deskripsi).trim() : currentLapangan.deskripsi;

    if (isNaN(updatedHarga) || updatedHarga <= 0) {
      if (req.file) removeUploadedFile(req.file.filename);
      res.status(400).json({
        success: false,
        message: 'Harga per jam harus berupa angka valid lebih dari 0',
      });
      return;
    }

    let updatedFoto = currentLapangan.foto_lapangan;
    if (req.file) {
      if (currentLapangan.foto_lapangan) {
        removeUploadedFile(currentLapangan.foto_lapangan);
      }
      updatedFoto = `/uploads/${req.file.filename}`;
    }

    const updatedKategoriId = id_kategori
      ? Number(id_kategori)
      : currentLapangan.id_kategori;

    const result = await pool.query(
      `UPDATE lapangan
       SET id_kategori = $1,
           nama_lapangan = $2,
           jenis_olahraga = $3,
           harga_per_jam = $4,
           deskripsi = $5,
           foto_lapangan = $6,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $7
       RETURNING *`,
      [
        updatedKategoriId,
        updatedNama,
        updatedJenis,
        updatedHarga,
        updatedDeskripsi,
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
    if (req.file) removeUploadedFile(req.file.filename);
    console.error('Update lapangan error:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal memperbarui data lapangan',
    });
  }
}

export async function deleteLapangan(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const existing = await pool.query('SELECT * FROM lapangan WHERE id = $1', [id]);

    if (existing.rows.length === 0) {
      res.status(404).json({
        success: false,
        message: 'Data lapangan tidak ditemukan',
      });
      return;
    }

    const lapanganToDelete = existing.rows[0];
    await pool.query('DELETE FROM lapangan WHERE id = $1', [id]);

    if (lapanganToDelete.foto_lapangan) {
      removeUploadedFile(lapanganToDelete.foto_lapangan);
    }

    res.status(200).json({
      success: true,
      message: 'Data lapangan berhasil dihapus',
      data: lapanganToDelete,
    });
  } catch (error: any) {
    console.error('Delete lapangan error:', error);
    if (error?.code === '23503') {
      res.status(409).json({
        success: false,
        message: 'Lapangan tidak dapat dihapus karena masih memiliki riwayat pemesanan',
      });
      return;
    }
    res.status(500).json({
      success: false,
      message: 'Gagal menghapus data lapangan',
    });
  }
}
