import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import { extname, join, normalize, resolve, sep } from 'node:path';

const mimeTypes = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.jsonld': 'application/ld+json; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8',
  '.xml': 'application/xml; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.ico': 'image/x-icon',
};

function isSafePath(root, filePath) {
  const resolvedRoot = resolve(root);
  const resolvedFile = resolve(filePath);
  return resolvedFile === resolvedRoot || resolvedFile.startsWith(resolvedRoot + sep);
}

function candidatePath(staticDir, pathname) {
  const cleanPath = decodeURIComponent(pathname.split('?')[0]);
  const normalized = normalize(cleanPath).replace(/^(\.\.(\/|\\|$))+/, '');
  const relative = normalized === '/' ? 'index.html' : normalized.replace(/^\/+/, '');
  return join(staticDir, relative.endsWith('/') ? `${relative}index.html` : relative);
}

export async function serveStaticFile({ requestUrl, response, staticDir }) {
  const url = new URL(requestUrl, 'http://localhost');
  const initialPath = candidatePath(staticDir, url.pathname);
  if (!isSafePath(staticDir, initialPath)) return false;

  let filePath = initialPath;
  let info;

  try {
    info = await stat(filePath);
    if (info.isDirectory()) {
      filePath = join(filePath, 'index.html');
      info = await stat(filePath);
    }
  } catch {
    return false;
  }

  if (!info.isFile()) return false;

  const contentType = mimeTypes[extname(filePath).toLowerCase()] || 'application/octet-stream';
  response.writeHead(200, {
    'content-type': contentType,
    'cache-control': 'public, max-age=0, must-revalidate',
  });
  createReadStream(filePath).pipe(response);
  return true;
}
