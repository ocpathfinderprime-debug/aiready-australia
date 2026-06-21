import { mkdir, readFile, appendFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { randomUUID } from 'node:crypto';

function safeBucket(bucket) {
  if (!/^[a-z0-9_-]+$/i.test(bucket)) {
    throw new Error('Invalid store bucket');
  }
  return bucket;
}

export class JsonlStore {
  constructor({ dataDir }) {
    this.dataDir = dataDir;
  }

  fileFor(bucket) {
    return join(this.dataDir, `${safeBucket(bucket)}.jsonl`);
  }

  async create(bucket, payload) {
    const now = new Date().toISOString();
    const record = {
      id: randomUUID(),
      status: payload.status || 'new',
      createdAt: now,
      updatedAt: now,
      ...payload,
    };
    const file = this.fileFor(bucket);
    await mkdir(dirname(file), { recursive: true });
    await appendFile(file, `${JSON.stringify(record)}\n`, 'utf8');
    return record;
  }

  async list(bucket) {
    const file = this.fileFor(bucket);
    try {
      const text = await readFile(file, 'utf8');
      return text
        .split('\n')
        .filter(Boolean)
        .map((line) => JSON.parse(line));
    } catch (error) {
      if (error.code === 'ENOENT') return [];
      throw error;
    }
  }

  async findById(bucket, id) {
    const records = await this.list(bucket);
    return records.find((record) => record.id === id) || null;
  }
}
