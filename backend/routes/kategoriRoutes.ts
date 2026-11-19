import { Router } from 'express';
import {
  getAllKategori,
  createKategori,
  updateKategori,
  deleteKategori,
} from '../controllers/kategoriController';
import { verifyToken, authorizeRole } from '../middleware/authMiddleware';

const router = Router();

router.get('/', getAllKategori);
router.post('/', verifyToken, authorizeRole('admin'), createKategori);
router.put('/:id', verifyToken, authorizeRole('admin'), updateKategori);
router.delete('/:id', verifyToken, authorizeRole('admin'), deleteKategori);

export default router;
