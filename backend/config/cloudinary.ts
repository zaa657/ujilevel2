import { v2 as cloudinary } from 'cloudinary';
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { getUploadDir } from './paths';

dotenv.config();

if (
  process.env.CLOUDINARY_CLOUD_NAME &&
  process.env.CLOUDINARY_API_KEY &&
  process.env.CLOUDINARY_API_SECRET
) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME.trim(),
    api_key: process.env.CLOUDINARY_API_KEY.trim(),
    api_secret: process.env.CLOUDINARY_API_SECRET.trim(),
    secure: true,
  });
}

export function isCloudinaryConfigured(): boolean {
  return Boolean(
    process.env.CLOUDINARY_URL ||
      (process.env.CLOUDINARY_CLOUD_NAME &&
        process.env.CLOUDINARY_API_KEY &&
        process.env.CLOUDINARY_API_SECRET)
  );
}

export function removeLocalFile(filePathOrName?: string | null): void {
  if (!filePathOrName) return;
  const candidate = fs.existsSync(filePathOrName)
    ? filePathOrName
    : path.join(getUploadDir(), path.basename(filePathOrName));

  if (fs.existsSync(candidate)) {
    try {
      fs.unlinkSync(candidate);
    } catch (err: any) {
      console.error('Failed to remove local file:', err.message);
    }
  }
}

export async function uploadImageFile(
  file: Express.Multer.File,
  subfolder: 'lapangan' | 'bukti_bayar'
): Promise<string> {
  if (isCloudinaryConfigured()) {
    try {
      const uploadResult = await cloudinary.uploader.upload(file.path, {
        folder: `sportbook/${subfolder}`,
        resource_type: 'image',
      });
      removeLocalFile(file.path);
      return uploadResult.secure_url;
    } catch (error) {
      removeLocalFile(file.path);
      throw error;
    }
  }

  return `/uploads/${file.filename}`;
}

export async function removeStoredImage(fileUrlOrPath?: string | null): Promise<void> {
  if (!fileUrlOrPath) return;

  if (fileUrlOrPath.includes('res.cloudinary.com') && isCloudinaryConfigured()) {
    try {
      const match = fileUrlOrPath.match(/\/upload\/(?:v\d+\/)?(.+)\.[a-zA-Z0-9]+$/);
      if (match && match[1]) {
        await cloudinary.uploader.destroy(match[1]);
      }
    } catch (err: any) {
      console.error('Failed to delete image from Cloudinary:', err.message);
    }
    return;
  }

  removeLocalFile(fileUrlOrPath);
}

export default cloudinary;
