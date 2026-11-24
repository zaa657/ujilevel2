import { Router } from 'express';
import {
  getAllBookings,
  getBookingById,
  createBooking,
  updateBooking,
  updateBookingStatus,
  deleteBooking,
} from '../controllers/bookingController';
import { verifyToken, authorizeRole } from '../middleware/authMiddleware';
import { handleSingleUpload } from '../middleware/uploadMiddleware';

const router = Router();

router.get('/', verifyToken, getAllBookings);
router.get('/:id', verifyToken, getBookingById);

router.post(
  '/',
  verifyToken,
  authorizeRole('penyewa'),
  handleSingleUpload('bukti_bayar'),
  createBooking
);

router.put(
  '/:id',
  verifyToken,
  authorizeRole('penyewa', 'admin'),
  handleSingleUpload('bukti_bayar'),
  updateBooking
);

router.patch('/:id/status', verifyToken, authorizeRole('admin'), updateBookingStatus);
router.delete('/:id', verifyToken, authorizeRole('penyewa', 'admin'), deleteBooking);

export default router;
