import { Request, Response, NextFunction } from 'express';
import multer, { FileFilterCallback } from 'multer';
import { v2 as cloudinary } from 'cloudinary';
import path from 'path';
import fs from 'fs';
import dotenv from 'dotenv';
import { getUploadDir } from '../config/paths';

dotenv.config();

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, getUploadDir());
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
    uploader(req, res, async (err: any) => {
      if (err instanceof multer.MulterError) {
        const message =
          err.code === 'LIMIT_FILE_SIZE'
            ? 'Ukuran file melebihi batas maksimal 2 MB'
            : `Gagal upload file: ${err.message}`;
        res.status(400).json({ success: false, message });
        return;
      } else if (err) {
        res.status(400).json({ success: false, message: err.message });
        return;
      }

      if (
        req.file &&
        (process.env.CLOUDINARY_URL ||
          (process.env.CLOUDINARY_CLOUD_NAME &&
            process.env.CLOUDINARY_API_KEY &&
            process.env.CLOUDINARY_API_SECRET))
      ) {
        try {
          const result = await cloudinary.uploader.upload(req.file.path, {
            folder: `sportbook/${fieldName}`,
          });
          if (fs.existsSync(req.file.path)) {
            fs.unlinkSync(req.file.path);
          }
          req.file.filename = result.secure_url;
        } catch (cloudErr: any) {
          res.status(500).json({
            success: false,
            message: `Gagal upload ke Cloudinary: ${cloudErr.message}`,
          });
          return;
        }
      }

      next();
    });
  };
}
