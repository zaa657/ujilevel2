import path from 'path';
import fs from 'fs';
import os from 'os';

export function getBundledUploadDir(): string {
  const cwd = process.cwd();
  const potentialPaths = [
    path.resolve(__dirname, '..', 'uploads'),
    path.resolve(__dirname, '..', '..', 'uploads'),
    path.resolve(cwd, 'uploads'),
    path.resolve(cwd, 'backend', 'uploads'),
    path.resolve(cwd, '..', 'uploads'),
  ];

  for (const candidate of potentialPaths) {
    if (candidate.includes('dist\\uploads') || candidate.includes('dist/uploads')) {
      continue;
    }
    if (fs.existsSync(candidate)) {
      return candidate;
    }
    const parentDir = path.resolve(candidate, '..');
    if (fs.existsSync(path.join(parentDir, 'package.json'))) {
      return candidate;
    }
  }

  return path.resolve(cwd, 'uploads');
}

export function getUploadDir(): string {
  if (process.env.VERCEL) {
    const tmpUploadDir = path.join(os.tmpdir(), 'uploads');
    if (!fs.existsSync(tmpUploadDir)) {
      fs.mkdirSync(tmpUploadDir, { recursive: true });
    }
    return tmpUploadDir;
  }

  const targetDir = getBundledUploadDir();
  try {
    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
    }
    return targetDir;
  } catch {
    const tmpFallback = path.join(os.tmpdir(), 'uploads');
    if (!fs.existsSync(tmpFallback)) {
      fs.mkdirSync(tmpFallback, { recursive: true });
    }
    return tmpFallback;
  }
}

export function getStaticUploadDirs(): string[] {
  const dirs = new Set<string>();
  dirs.add(getUploadDir());
  const bundled = getBundledUploadDir();
  if (fs.existsSync(bundled)) {
    dirs.add(bundled);
  }
  return Array.from(dirs);
}
