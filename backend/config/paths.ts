import path from 'path';
import fs from 'fs';

/**
 * Mengembalikan path absolut direktori 'uploads' yang valid secara konsisten,
 * baik saat dijalankan dari TypeScript (tsx/ts-node), JavaScript (dist),
 * maupun saat process.cwd() berada di root project atau direktori dist.
 */
export function getUploadDir(): string {
  // Cek jika process.cwd() adalah direktori backend
  const cwd = process.cwd();
  const potentialPaths = [
    path.resolve(__dirname, '..', 'uploads'),
    path.resolve(__dirname, '..', '..', 'uploads'),
    path.resolve(cwd, 'uploads'),
    path.resolve(cwd, 'backend', 'uploads'),
    path.resolve(cwd, '..', 'uploads'),
  ];

  for (const candidate of potentialPaths) {
    // Cari direktori yang berada di folder backend yang sesungguhnya (bukan di dalam dist)
    if (candidate.includes('dist\\uploads') || candidate.includes('dist/uploads')) {
      continue;
    }
    const parentDir = path.resolve(candidate, '..');
    if (fs.existsSync(path.join(parentDir, 'package.json'))) {
      if (!fs.existsSync(candidate)) {
        fs.mkdirSync(candidate, { recursive: true });
      }
      return candidate;
    }
  }

  // Fallback: pastikan selalu ada folder uploads yang dibuat
  const fallback = path.resolve(cwd, 'uploads');
  if (!fs.existsSync(fallback)) {
    fs.mkdirSync(fallback, { recursive: true });
  }
  return fallback;
}
