import { Request, Response, NextFunction } from 'express';
import multer, { FileFilterCallback } from 'multer';
import path from 'path';
import fs from 'fs';
import { getUploadDir } from '../config/paths';

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    const dir = getUploadDir();
    cb(null, dir);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e6)}`;
    cb(null, `${file.fieldname}-${uniqueSuffix}${ext}`);
  },
});

const fileFilter = (_req: Request, file: Express.Multer.File, cb: FileFilterCallback) => {
  const allowedExts = ['.jpg', '.jpeg', '.png'];
  const ext = path.extname(file.originalname).toLowerCase();

  if (file.mimetype.startsWith('image/') && allowedExts.includes(ext)) {
    cb(null, true);
  } else {
    cb(new Error('Format file harus berupa gambar (JPG, JPEG, atau PNG)'));
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: {
    fileSize: 2 * 1024 * 1024,
  },
});

export function handleSingleUpload(fieldName: string) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const uploader = upload.single(fieldName);
    uploader(req, res, (err: any) => {
      if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
          res.status(400).json({
            success: false,
            message: 'Ukuran file melebihi batas maksimal 2 MB',
          });
          return;
        }
        res.status(400).json({
          success: false,
          message: `Gagal upload file: ${err.message}`,
        });
        return;
      } else if (err) {
        res.status(400).json({
          success: false,
          message: err.message,
        });
        return;
      }
      next();
    });
  };
}
