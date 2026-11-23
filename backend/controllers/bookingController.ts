import { Response } from 'express';
import fs from 'fs';
import path from 'path';
import { pool } from '../config/db';
import { getUploadDir } from '../config/paths';
import { AuthRequest } from '../middleware/authMiddleware';

function resolveUploadedUrl(file?: Express.Multer.File): string | null {
  if (!file) return null;
  return file.filename.startsWith('http') ? file.filename : `/uploads/${file.filename}`;
}

function removeUploadedFile(filePath?: string | null): void {
  if (!filePath || filePath.startsWith('http')) return;
  const fullPath = path.join(getUploadDir(), path.basename(filePath));
  if (fs.existsSync(fullPath)) {
    try {
      fs.unlinkSync(fullPath);
    } catch {}
  }
}

function parseTimeToMinutes(timeStr: string): number {
  if (!timeStr) return 0;
  const parts = String(timeStr).trim().split(':');
  const hours = parseInt(parts[0], 10) || 0;
  const minutes = parseInt(parts[1], 10) || 0;
  return hours * 60 + minutes;
}

export async function getAllBookings(req: AuthRequest, res: Response): Promise<void> {
  try {
    let query = `
      SELECT 
        b.id,
        b.user_id,
        u.name AS nama_penyewa,
        u.email AS email_penyewa,
        b.lapangan_id,
        l.nama_lapangan,
        l.jenis_olahraga,
        l.harga_per_jam,
        l.foto_lapangan,
        TO_CHAR(b.tanggal_sewa, 'YYYY-MM-DD') AS tanggal_sewa,
        b.jam_mulai,
        b.durasi_jam,
        b.total_harga,
        b.bukti_bayar,
        b.status_booking,
        b.created_at,
        b.updated_at
      FROM bookings b
      JOIN users u ON b.user_id = u.id
      JOIN lapangan l ON b.lapangan_id = l.id
    `;
    const params: any[] = [];

    // Filter to own bookings if not admin
    if (req.user?.role !== 'admin') {
      query += ' WHERE b.user_id = $1';
      params.push(req.user?.id);
    }

    query += ' ORDER BY b.id DESC';

    const result = await pool.query(query, params);
    res.status(200).json({
      success: true,
      message: 'Berhasil mengambil data pemesanan lapangan',
      data: result.rows,
    });
  } catch (error) {
    console.error('Get bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal mengambil data pemesanan lapangan',
    });
  }
}

export async function getBookingById(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `SELECT 
        b.id,
        b.user_id,
        u.name AS nama_penyewa,
        u.email AS email_penyewa,
        b.lapangan_id,
        l.nama_lapangan,
        l.jenis_olahraga,
        l.harga_per_jam,
        l.foto_lapangan,
        TO_CHAR(b.tanggal_sewa, 'YYYY-MM-DD') AS tanggal_sewa,
        b.jam_mulai,
        b.durasi_jam,
        b.total_harga,
        b.bukti_bayar,
        b.status_booking,
        b.created_at,
        b.updated_at
      FROM bookings b
      JOIN users u ON b.user_id = u.id
      JOIN lapangan l ON b.lapangan_id = l.id
      WHERE b.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      res.status(404).json({
        success: false,
        message: 'Data pemesanan tidak ditemukan',
      });
      return;
    }

    const booking = result.rows[0];
    if (req.user?.role !== 'admin' && booking.user_id !== req.user?.id) {
      res.status(403).json({
        success: false,
        message: 'Anda tidak memiliki akses untuk melihat pesanan ini',
      });
      return;
    }

    res.status(200).json({
      success: true,
      message: 'Berhasil mengambil detail pemesanan',
      data: booking,
    });
  } catch (error) {
    console.error('Get booking by id error:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal mengambil detail pemesanan',
    });
  }
}

export async function createBooking(req: AuthRequest, res: Response): Promise<void> {
  try {
    const lapanganId = req.body.lapangan_id || req.body.field_id || req.body.id_lapangan;
    const { tanggal_sewa, jam_mulai, durasi_jam } = req.body;

    if (!lapanganId || !tanggal_sewa || !jam_mulai || !durasi_jam) {
      if (req.file) removeUploadedFile(req.file.filename);
      res.status(400).json({
        success: false,
        message: 'Lapangan, tanggal sewa, jam mulai, dan durasi wajib diisi',
      });
      return;
    }

    const parsedDurasi = Number(durasi_jam);
    if (isNaN(parsedDurasi) || parsedDurasi <= 0) {
      if (req.file) removeUploadedFile(req.file.filename);
      res.status(400).json({
        success: false,
        message: 'Durasi sewa minimal 1 jam',
      });
      return;
    }

    const lapanganResult = await pool.query('SELECT * FROM lapangan WHERE id = $1', [lapanganId]);
    if (lapanganResult.rows.length === 0) {
      if (req.file) removeUploadedFile(req.file.filename);
      res.status(404).json({
        success: false,
        message: 'Lapangan yang dipilih tidak ditemukan',
      });
      return;
    }

    const lapangan = lapanganResult.rows[0];

    // Prevent double booking on overlapping slot
    const newStart = parseTimeToMinutes(jam_mulai);
    const newEnd = newStart + parsedDurasi * 60;

    const existingBookings = await pool.query(
      `SELECT id, jam_mulai, durasi_jam FROM bookings
       WHERE lapangan_id = $1
         AND tanggal_sewa = $2
         AND LOWER(status_booking) NOT IN ('ditolak', 'cancelled')`,
      [lapanganId, tanggal_sewa]
    );

    const hasOverlap = existingBookings.rows.some((b) => {
      const existStart = parseTimeToMinutes(b.jam_mulai);
      const existEnd = existStart + Number(b.durasi_jam) * 60;
      return newStart < existEnd && existStart < newEnd;
    });

    if (hasOverlap) {
      if (req.file) removeUploadedFile(req.file.filename);
      res.status(409).json({
        success: false,
        message: 'Jadwal lapangan bertabrakan dengan pesanan yang sudah ada pada rentang jam tersebut',
      });
      return;
    }

    const totalHarga = parsedDurasi * Number(lapangan.harga_per_jam);
    const buktiBayarPath = resolveUploadedUrl(req.file);

    const insertResult = await pool.query(
      `INSERT INTO bookings (user_id, lapangan_id, tanggal_sewa, jam_mulai, durasi_jam, total_harga, bukti_bayar, status_booking)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending')
       RETURNING id`,
      [
        req.user?.id,
        lapanganId,
        tanggal_sewa,
        String(jam_mulai).trim(),
        parsedDurasi,
        totalHarga,
        buktiBayarPath,
      ]
    );

    const newBookingId = insertResult.rows[0].id;
    const fetchCreated = await pool.query(
      `SELECT 
        b.id,
        b.user_id,
        u.name AS nama_penyewa,
        u.email AS email_penyewa,
        b.lapangan_id,
        l.nama_lapangan,
        l.jenis_olahraga,
        l.harga_per_jam,
        l.foto_lapangan,
        TO_CHAR(b.tanggal_sewa, 'YYYY-MM-DD') AS tanggal_sewa,
        b.jam_mulai,
        b.durasi_jam,
        b.total_harga,
        b.bukti_bayar,
        b.status_booking,
        b.created_at,
        b.updated_at
      FROM bookings b
      JOIN users u ON b.user_id = u.id
      JOIN lapangan l ON b.lapangan_id = l.id
      WHERE b.id = $1`,
      [newBookingId]
    );

    res.status(201).json({
      success: true,
      message: 'Pesanan jadwal lapangan berhasil dibuat dan menunggu verifikasi Admin',
      data: fetchCreated.rows[0],
    });
  } catch (error) {
    if (req.file) removeUploadedFile(req.file.filename);
    console.error('Create booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal membuat pesanan lapangan',
    });
  }
}

export async function updateBooking(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const { tanggal_sewa, jam_mulai, durasi_jam, status_booking } = req.body;

    const existing = await pool.query(
      `SELECT b.*, l.harga_per_jam
       FROM bookings b
       JOIN lapangan l ON b.lapangan_id = l.id
       WHERE b.id = $1`,
      [id]
    );

    if (existing.rows.length === 0) {
      if (req.file) removeUploadedFile(req.file.filename);
      res.status(404).json({
        success: false,
        message: 'Data pemesanan tidak ditemukan',
      });
      return;
    }

    const currentBooking = existing.rows[0];

    if (req.user?.role !== 'admin' && currentBooking.user_id !== req.user?.id) {
      if (req.file) removeUploadedFile(req.file.filename);
      res.status(403).json({
        success: false,
        message: 'Anda tidak memiliki akses untuk mengubah pesanan ini',
      });
      return;
    }

    const updatedTanggal = tanggal_sewa || currentBooking.tanggal_sewa;
    const updatedJam = jam_mulai ? String(jam_mulai).trim() : currentBooking.jam_mulai;
    const updatedDurasi =
      durasi_jam !== undefined && durasi_jam !== ''
        ? Number(durasi_jam)
        : currentBooking.durasi_jam;

    if (isNaN(updatedDurasi) || updatedDurasi <= 0) {
      if (req.file) removeUploadedFile(req.file.filename);
      res.status(400).json({
        success: false,
        message: 'Durasi jam harus berupa angka valid lebih dari 0',
      });
      return;
    }

    // Prevent overlap conflict when updating slot
    const newStart = parseTimeToMinutes(updatedJam);
    const newEnd = newStart + updatedDurasi * 60;

    const existingBookings = await pool.query(
      `SELECT id, jam_mulai, durasi_jam FROM bookings
       WHERE lapangan_id = $1
         AND tanggal_sewa = $2
         AND id != $3
         AND LOWER(status_booking) NOT IN ('ditolak', 'cancelled')`,
      [currentBooking.lapangan_id, updatedTanggal, id]
    );

    const hasOverlap = existingBookings.rows.some((b) => {
      const existStart = parseTimeToMinutes(b.jam_mulai);
      const existEnd = existStart + Number(b.durasi_jam) * 60;
      return newStart < existEnd && existStart < newEnd;
    });

    if (hasOverlap) {
      if (req.file) removeUploadedFile(req.file.filename);
      res.status(409).json({
        success: false,
        message: 'Jadwal pemesanan bertabrakan dengan pesanan lain pada rentang jam tersebut',
      });
      return;
    }

    const updatedTotalHarga = updatedDurasi * Number(currentBooking.harga_per_jam);

    let updatedStatus = currentBooking.status_booking;
    if (req.user?.role === 'admin' && status_booking) {
      const validStatus = [
        'pending',
        'confirmed',
        'cancelled',
        'completed',
        'Pending',
        'Disetujui',
        'Ditolak',
        'Selesai',
      ];
      if (!validStatus.includes(status_booking)) {
        if (req.file) removeUploadedFile(req.file.filename);
        res.status(400).json({
          success: false,
          message:
            'Status booking harus bernilai: pending, confirmed, cancelled, atau completed',
        });
        return;
      }
      updatedStatus = status_booking;
    }

    let updatedBukti = currentBooking.bukti_bayar;
    if (req.file) {
      if (currentBooking.bukti_bayar) {
        removeUploadedFile(currentBooking.bukti_bayar);
      }
      updatedBukti = resolveUploadedUrl(req.file);
    }

    await pool.query(
      `UPDATE bookings
       SET tanggal_sewa = $1,
           jam_mulai = $2,
           durasi_jam = $3,
           total_harga = $4,
           bukti_bayar = $5,
           status_booking = $6,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $7`,
      [
        updatedTanggal,
        updatedJam,
        updatedDurasi,
        updatedTotalHarga,
        updatedBukti,
        updatedStatus,
        id,
      ]
    );

    const fetchUpdated = await pool.query(
      `SELECT 
        b.id,
        b.user_id,
        u.name AS nama_penyewa,
        u.email AS email_penyewa,
        b.lapangan_id,
        l.nama_lapangan,
        l.jenis_olahraga,
        l.harga_per_jam,
        l.foto_lapangan,
        TO_CHAR(b.tanggal_sewa, 'YYYY-MM-DD') AS tanggal_sewa,
        b.jam_mulai,
        b.durasi_jam,
        b.total_harga,
        b.bukti_bayar,
        b.status_booking,
        b.created_at,
        b.updated_at
      FROM bookings b
      JOIN users u ON b.user_id = u.id
      JOIN lapangan l ON b.lapangan_id = l.id
      WHERE b.id = $1`,
      [id]
    );

    res.status(200).json({
      success: true,
      message: 'Data pemesanan berhasil diperbarui',
      data: fetchUpdated.rows[0],
    });
  } catch (error) {
    if (req.file) removeUploadedFile(req.file.filename);
    console.error('Update booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal memperbarui data pemesanan',
    });
  }
}

export async function updateBookingStatus(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const status_booking = req.body.status_booking || req.body.status;

    const validStatus = [
      'pending',
      'confirmed',
      'cancelled',
      'completed',
      'Pending',
      'Disetujui',
      'Ditolak',
      'Selesai',
    ];
    if (!status_booking || !validStatus.includes(status_booking)) {
      res.status(400).json({
        success: false,
        message:
          'Status booking harus bernilai: pending, confirmed, cancelled, atau completed',
      });
      return;
    }

    const result = await pool.query(
      `UPDATE bookings
       SET status_booking = $1, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING id`,
      [status_booking, id]
    );

    if (result.rows.length === 0) {
      res.status(404).json({
        success: false,
        message: 'Data pemesanan tidak ditemukan',
      });
      return;
    }

    const fetchUpdated = await pool.query(
      `SELECT 
        b.id,
        b.user_id,
        u.name AS nama_penyewa,
        u.email AS email_penyewa,
        b.lapangan_id,
        l.nama_lapangan,
        l.jenis_olahraga,
        l.harga_per_jam,
        l.foto_lapangan,
        TO_CHAR(b.tanggal_sewa, 'YYYY-MM-DD') AS tanggal_sewa,
        b.jam_mulai,
        b.durasi_jam,
        b.total_harga,
        b.bukti_bayar,
        b.status_booking,
        b.created_at,
        b.updated_at
      FROM bookings b
      JOIN users u ON b.user_id = u.id
      JOIN lapangan l ON b.lapangan_id = l.id
      WHERE b.id = $1`,
      [id]
    );

    res.status(200).json({
      success: true,
      message: `Status pemesanan berhasil diubah menjadi ${status_booking}`,
      data: fetchUpdated.rows[0],
    });
  } catch (error) {
    console.error('Update booking status error:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal memverifikasi status pemesanan',
    });
  }
}

export async function deleteBooking(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const existing = await pool.query('SELECT * FROM bookings WHERE id = $1', [id]);

    if (existing.rows.length === 0) {
      res.status(404).json({
        success: false,
        message: 'Data pemesanan tidak ditemukan',
      });
      return;
    }

    const bookingToDelete = existing.rows[0];
    if (req.user?.role !== 'admin' && bookingToDelete.user_id !== req.user?.id) {
      res.status(403).json({
        success: false,
        message: 'Anda tidak memiliki akses untuk menghapus pesanan ini',
      });
      return;
    }

    await pool.query('DELETE FROM bookings WHERE id = $1', [id]);

    if (bookingToDelete.bukti_bayar) {
      removeUploadedFile(bookingToDelete.bukti_bayar);
    }

    res.status(200).json({
      success: true,
      message: 'Data pemesanan berhasil dihapus',
      data: bookingToDelete,
    });
  } catch (error) {
    console.error('Delete booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Gagal menghapus data pemesanan',
    });
  }
}
