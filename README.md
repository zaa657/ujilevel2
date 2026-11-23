# SportBook UMKM - Sistem Pemesanan Lapangan Olahraga

Aplikasi pemesanan dan manajemen jadwal lapangan olahraga berbasis **Flutter (Mobile & Web)** dan **Node.js + Express + TypeScript + PostgreSQL (REST API)**.

## Struktur Direktori

- **`backend/`**: Server REST API menggunakan Node.js, Express.js, TypeScript, PostgreSQL (`pg`), autentikasi JWT, dan upload gambar (`multer`).
- **`mobile/`**: Aplikasi klien multi-platform menggunakan Flutter untuk role **Penyewa** dan **Admin UMKM**, dilengkapi fitur deteksi lokasi lapangan terdekat (`geolocator`).

## Fitur Utama

1. **Autentikasi & Otorisasi**: Registrasi penyewa, login multi-role (Admin & Penyewa) menggunakan JSON Web Token (JWT) dan hashing password `bcryptjs`.
2. **Manajemen Kategori & Lapangan (Admin)**: CRUD data kategori cabang olahraga dan CRUD data lapangan beserta unggah foto lapangan.
3. **Pencarian & Lokasi Terdekat (Penyewa)**: Pencarian lapangan berdasarkan nama, filter kategori olahraga, dan pengurutan jarak lapangan terdekat dari lokasi GPS penyewa.
4. **Pemesanan & Verifikasi Pembayaran**: Pemesanan jadwal lapangan dengan validasi anti-bentrok (*double-booking prevention*), unggah foto bukti transfer pembayaran, serta verifikasi status pesanan oleh Admin.
