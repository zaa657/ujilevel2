import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

import { getStaticUploadDirs } from './config/paths';
import authRoutes from './routes/authRoutes';
import kategoriRoutes from './routes/kategoriRoutes';
import lapanganRoutes from './routes/lapanganRoutes';
import bookingRoutes from './routes/bookingRoutes';

dotenv.config();

const app = express();
const PORT = Number(process.env.PORT) || 5000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

for (const dir of getStaticUploadDirs()) {
  app.use('/uploads', express.static(dir));
}

app.get('/', (_req: Request, res: Response) => {
  res.status(200).json({
    success: true,
    message: 'SportBook REST API',
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/kategori', kategoriRoutes);
app.use('/api/lapangan', lapanganRoutes);
app.use('/api/bookings', bookingRoutes);

app.use((req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.originalUrl} tidak ditemukan`,
  });
});

app.use((err: Error, _req: Request, res: Response, _next: NextFunction) => {
  console.error('[Error]', err);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
  });
});

if (require.main === module) {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server listening on port ${PORT}`);
  });
}

export default app;
