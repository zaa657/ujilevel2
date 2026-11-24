import { Response } from 'express';
import fs from 'fs';
import path from 'path';
import { pool } from '../config/db';
import { getUploadDir } from '../config/paths';
import { AuthRequest } from '../middleware/authMiddleware';

const BOOKING_SELECT_SQL = `
  SELECT b.id, b.user_id, u.name AS nama_penyewa, u.email AS email_penyewa,
         b.lapangan_id, l.nama_lapangan, l.jenis_olahraga, l.harga_per_jam, l.foto_lapangan,
         TO_CHAR(b.tanggal_sewa, 'YYYY-MM-DD') AS tanggal_sewa, b.jam_mulai, b.durasi_jam,
         b.total_harga, b.bukti_bayar, b.status_booking, b.created_at, b.updated_at
  FROM bookings b
  JOIN users u ON b.user_id = u.id
  JOIN lapangan l ON b.lapangan_id = l.id
`;

const VALID_STATUSES = ['pending', 'confirmed', 'cancelled', 'completed', 'Pending', 'Disetujui', 'Ditolak', 'Selesai'];

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

function parseTimeToMinutes(timeStr: string): number {
  if (!timeStr) return 0;
  const [h, m] = String(timeStr).trim().split(':');
  return (parseInt(h, 10) || 0) * 60 + (parseInt(m, 10) || 0);
}

async function fetchBookingWithDetails(id: number | string) {
  const res = await pool.query(`${BOOKING_SELECT_SQL} WHERE b.id = $1`, [id]);
  return res.rows[0] || null;
}

async function hasScheduleOverlap(
  lapanganId: number | string,
  tanggalSewa: string,
  jamMulai: string,
  durasiJam: number,
  excludeBookingId?: number | string
): Promise<boolean> {
  const newStart = parseTimeToMinutes(jamMulai);
  const newEnd = newStart + durasiJam * 60;
  const params: any[] = [lapanganId, tanggalSewa];
  let query = `
    SELECT jam_mulai, durasi_jam FROM bookings
    WHERE lapangan_id = $1 AND tanggal_sewa = $2 AND LOWER(status_booking) NOT IN ('ditolak', 'cancelled')
  `;
  if (excludeBookingId !== undefined) {
    query += ' AND id != $3';
    params.push(excludeBookingId);
  }
  const existing = await pool.query(query, params);
  return existing.rows.some((b) => {
    const existStart = parseTimeToMinutes(b.jam_mulai);
    const existEnd = existStart + Number(b.durasi_jam) * 60;
    return newStart < existEnd && existStart < newEnd;
  });
}

export async function getAllBookings(req: AuthRequest, res: Response): Promise<void> {
  try {
    const isAdmin = req.user?.role === 'admin';
    const query = isAdmin
      ? `${BOOKING_SELECT_SQL} ORDER BY b.id DESC`
      : `${BOOKING_SELECT_SQL} WHERE b.user_id = $1 ORDER BY b.id DESC`;
    const result = await pool.query(query, isAdmin ? [] : [req.user?.id]);
    res.status(200).json({
      success: true,
      message: 'Berhasil mengambil data pemesanan lapangan',
      data: result.rows,
    });
  } catch (error) {
    console.error('Get bookings error:', error);
    fail(res, 500, 'Gagal mengambil data pemesanan lapangan');
  }
}

export async function getBookingById(req: AuthRequest, res: Response): Promise<void> {
  try {
    const booking = await fetchBookingWithDetails(req.params.id);
    if (!booking) return fail(res, 404, 'Data pemesanan tidak ditemukan');
    if (req.user?.role !== 'admin' && booking.user_id !== req.user?.id) {
      return fail(res, 403, 'Anda tidak memiliki akses untuk melihat pesanan ini');
    }
    res.status(200).json({
      success: true,
      message: 'Berhasil mengambil detail pemesanan',
      data: booking,
    });
  } catch (error) {
    console.error('Get booking by id error:', error);
    fail(res, 500, 'Gagal mengambil detail pemesanan');
  }
}

export async function createBooking(req: AuthRequest, res: Response): Promise<void> {
  try {
    const lapanganId = req.body.lapangan_id || req.body.field_id || req.body.id_lapangan;
    const { tanggal_sewa, jam_mulai, durasi_jam } = req.body;

    if (!lapanganId || !tanggal_sewa || !jam_mulai || !durasi_jam) {
      return fail(res, 400, 'Lapangan, tanggal sewa, jam mulai, dan durasi wajib diisi', req.file);
    }

    const parsedDurasi = Number(durasi_jam);
    if (isNaN(parsedDurasi) || parsedDurasi <= 0) {
      return fail(res, 400, 'Durasi sewa minimal 1 jam', req.file);
    }

    const lapanganResult = await pool.query('SELECT * FROM lapangan WHERE id = $1', [lapanganId]);
    if (lapanganResult.rows.length === 0) {
      return fail(res, 404, 'Lapangan yang dipilih tidak ditemukan', req.file);
    }

    if (await hasScheduleOverlap(lapanganId, tanggal_sewa, jam_mulai, parsedDurasi)) {
      return fail(res, 409, 'Jadwal lapangan bertabrakan dengan pesanan yang sudah ada pada rentang jam tersebut', req.file);
    }

    const totalHarga = parsedDurasi * Number(lapanganResult.rows[0].harga_per_jam);
    const insertResult = await pool.query(
      `INSERT INTO bookings (user_id, lapangan_id, tanggal_sewa, jam_mulai, durasi_jam, total_harga, bukti_bayar, status_booking)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'pending') RETURNING id`,
      [req.user?.id, lapanganId, tanggal_sewa, String(jam_mulai).trim(), parsedDurasi, totalHarga, resolveUploadedUrl(req.file)]
    );

    res.status(201).json({
      success: true,
      message: 'Pesanan jadwal lapangan berhasil dibuat dan menunggu verifikasi Admin',
      data: await fetchBookingWithDetails(insertResult.rows[0].id),
    });
  } catch (error) {
    console.error('Create booking error:', error);
    fail(res, 500, 'Gagal membuat pesanan lapangan', req.file);
  }
}

export async function updateBooking(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const { tanggal_sewa, jam_mulai, durasi_jam, status_booking } = req.body;

    const existing = await pool.query(
      'SELECT b.*, l.harga_per_jam FROM bookings b JOIN lapangan l ON b.lapangan_id = l.id WHERE b.id = $1',
      [id]
    );
    if (existing.rows.length === 0) return fail(res, 404, 'Data pemesanan tidak ditemukan', req.file);

    const cur = existing.rows[0];
    if (req.user?.role !== 'admin' && cur.user_id !== req.user?.id) {
      return fail(res, 403, 'Anda tidak memiliki akses untuk mengubah pesanan ini', req.file);
    }

    const updatedTanggal = tanggal_sewa || cur.tanggal_sewa;
    const updatedJam = jam_mulai ? String(jam_mulai).trim() : cur.jam_mulai;
    const updatedDurasi = durasi_jam !== undefined && durasi_jam !== '' ? Number(durasi_jam) : cur.durasi_jam;

    if (isNaN(updatedDurasi) || updatedDurasi <= 0) {
      return fail(res, 400, 'Durasi jam harus berupa angka valid lebih dari 0', req.file);
    }

    if (await hasScheduleOverlap(cur.lapangan_id, updatedTanggal, updatedJam, updatedDurasi, id)) {
      return fail(res, 409, 'Jadwal pemesanan bertabrakan dengan pesanan lain pada rentang jam tersebut', req.file);
    }

    let updatedStatus = cur.status_booking;
    if (req.user?.role === 'admin' && status_booking) {
      if (!VALID_STATUSES.includes(status_booking)) {
        return fail(res, 400, 'Status booking harus bernilai: pending, confirmed, cancelled, atau completed', req.file);
      }
      updatedStatus = status_booking;
    }

    let updatedBukti = cur.bukti_bayar;
    if (req.file) {
      if (cur.bukti_bayar) removeUploadedFile(cur.bukti_bayar);
      updatedBukti = resolveUploadedUrl(req.file);
    }

    await pool.query(
      `UPDATE bookings
       SET tanggal_sewa = $1, jam_mulai = $2, durasi_jam = $3, total_harga = $4,
           bukti_bayar = $5, status_booking = $6, updated_at = CURRENT_TIMESTAMP
       WHERE id = $7`,
      [updatedTanggal, updatedJam, updatedDurasi, updatedDurasi * Number(cur.harga_per_jam), updatedBukti, updatedStatus, id]
    );

    res.status(200).json({
      success: true,
      message: 'Data pemesanan berhasil diperbarui',
      data: await fetchBookingWithDetails(id),
    });
  } catch (error) {
    console.error('Update booking error:', error);
    fail(res, 500, 'Gagal memperbarui data pemesanan', req.file);
  }
}

export async function updateBookingStatus(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const status_booking = req.body.status_booking || req.body.status;

    if (!status_booking || !VALID_STATUSES.includes(status_booking)) {
      return fail(res, 400, 'Status booking harus bernilai: pending, confirmed, cancelled, atau completed');
    }

    const result = await pool.query(
      'UPDATE bookings SET status_booking = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING id',
      [status_booking, id]
    );
    if (result.rows.length === 0) return fail(res, 404, 'Data pemesanan tidak ditemukan');

    res.status(200).json({
      success: true,
      message: `Status pemesanan berhasil diubah menjadi ${status_booking}`,
      data: await fetchBookingWithDetails(id),
    });
  } catch (error) {
    console.error('Update booking status error:', error);
    fail(res, 500, 'Gagal memverifikasi status pemesanan');
  }
}

export async function deleteBooking(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const existing = await pool.query('SELECT * FROM bookings WHERE id = $1', [id]);
    if (existing.rows.length === 0) return fail(res, 404, 'Data pemesanan tidak ditemukan');

    const bookingToDelete = existing.rows[0];
    if (req.user?.role !== 'admin' && bookingToDelete.user_id !== req.user?.id) {
      return fail(res, 403, 'Anda tidak memiliki akses untuk menghapus pesanan ini');
    }

    await pool.query('DELETE FROM bookings WHERE id = $1', [id]);
    if (bookingToDelete.bukti_bayar) removeUploadedFile(bookingToDelete.bukti_bayar);

    res.status(200).json({
      success: true,
      message: 'Data pemesanan berhasil dihapus',
      data: bookingToDelete,
    });
  } catch (error) {
    console.error('Delete booking error:', error);
    fail(res, 500, 'Gagal menghapus data pemesanan');
  }
}
