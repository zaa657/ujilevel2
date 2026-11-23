import { Router } from 'express';
import {
  getAllLapangan,
  getLapanganById,
  createLapangan,
  updateLapangan,
  deleteLapangan,
} from '../controllers/lapanganController';
import { verifyToken, authorizeRole } from '../middleware/authMiddleware';
import { handleSingleUpload } from '../middleware/uploadMiddleware';

const router = Router();

router.get('/', getAllLapangan);
router.get('/:id', getLapanganById);

router.post(
  '/',
  verifyToken,
  authorizeRole('admin'),
  handleSingleUpload('foto_lapangan'),
  createLapangan
);

router.put(
  '/:id',
  verifyToken,
  authorizeRole('admin'),
  handleSingleUpload('foto_lapangan'),
  updateLapangan
);

router.delete('/:id', verifyToken, authorizeRole('admin'), deleteLapangan);

export default router;
