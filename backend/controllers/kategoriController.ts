import { Request, Response } from 'express';
import { pool } from '../config/db';

export async function getAllKategori(_req: Request, res: Response): Promise<void> {
  try {
    const result = await pool.query(
      'SELECT id_kategori, jenis_olahraga, keterangan, created_at FROM kategori ORDER BY id_kategori ASC'
    );
    res.status(200).json({
      success: true,
      message: 'Berhasil mengambil daftar kategori olahraga',
      data: result.rows,
    });
  } catch (error) {
    console.error('Get kategori error:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal mengambil data kategori olahraga',
    });
  }
}

export async function createKategori(req: Request, res: Response): Promise<void> {
  try {
    const { jenis_olahraga, keterangan } = req.body;
    if (!jenis_olahraga || !String(jenis_olahraga).trim()) {
      res.status(400).json({
        success: false,
        message: 'Jenis olahraga wajib diisi',
      });
      return;
    }

    const result = await pool.query(
      `INSERT INTO kategori (jenis_olahraga, keterangan)
       VALUES ($1, $2)
       RETURNING id_kategori, jenis_olahraga, keterangan, created_at`,
      [String(jenis_olahraga).trim(), keterangan ? String(keterangan).trim() : null]
    );

    res.status(201).json({
      success: true,
      message: 'Kategori olahraga berhasil ditambahkan',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Create kategori error:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal menambahkan kategori olahraga',
    });
  }
}

export async function updateKategori(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const { jenis_olahraga, keterangan } = req.body;

    if (!jenis_olahraga || !String(jenis_olahraga).trim()) {
      res.status(400).json({
        success: false,
        message: 'Jenis olahraga wajib diisi',
      });
      return;
    }

    const result = await pool.query(
      `UPDATE kategori
       SET jenis_olahraga = $1, keterangan = $2, updated_at = CURRENT_TIMESTAMP
       WHERE id_kategori = $3
       RETURNING id_kategori, jenis_olahraga, keterangan, updated_at`,
      [String(jenis_olahraga).trim(), keterangan ? String(keterangan).trim() : null, id]
    );

    if (result.rows.length === 0) {
      res.status(404).json({
        success: false,
        message: 'Kategori olahraga tidak ditemukan',
      });
      return;
    }

    res.status(200).json({
      success: true,
      message: 'Kategori olahraga berhasil diperbarui',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Update kategori error:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal memperbarui kategori olahraga',
    });
  }
}

export async function deleteKategori(req: Request, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const result = await pool.query(
      'DELETE FROM kategori WHERE id_kategori = $1 RETURNING id_kategori, jenis_olahraga',
      [id]
    );

    if (result.rows.length === 0) {
      res.status(404).json({
        success: false,
        message: 'Kategori olahraga tidak ditemukan',
      });
      return;
    }

    res.status(200).json({
      success: true,
      message: 'Kategori olahraga berhasil dihapus',
      data: result.rows[0],
    });
  } catch (error: any) {
    console.error('Delete kategori error:', error);
    if (error?.code === '23503') {
      res.status(409).json({
        success: false,
        message: 'Kategori tidak dapat dihapus karena masih digunakan oleh data lapangan',
      });
      return;
    }
    res.status(500).json({
      success: false,
      message: 'Gagal menghapus kategori olahraga',
    });
  }
}
