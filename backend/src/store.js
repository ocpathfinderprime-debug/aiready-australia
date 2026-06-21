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

export class NetlifyBlobStore {
  constructor({ getStore, storeName = 'aiready-records', siteID = '', token = '' }) {
    this.getStore = getStore;
    this.storeName = storeName;
    this.siteID = siteID;
    this.token = token;
  }

  store() {
    if (this.siteID && this.token) {
      return this.getStore({ name: this.storeName, siteID: this.siteID, token: this.token });
    }

    return this.getStore(this.storeName);
  }

  keyFor(bucket, id) {
    return `${safeBucket(bucket)}/${id}.json`;
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

    await this.store().setJSON(this.keyFor(bucket, record.id), record, {
      metadata: {
        bucket: safeBucket(bucket),
        status: record.status,
        createdAt: now,
      },
      onlyIfNew: true,
    });

    return record;
  }

  async list(bucket) {
    const safe = safeBucket(bucket);
    const store = this.store();
    const result = await store.list({ prefix: `${safe}/` });
    const records = await Promise.all(
      result.blobs.map((blob) => store.get(blob.key, { type: 'json' })),
    );
    return records.filter(Boolean);
  }

  async findById(bucket, id) {
    return this.store().get(this.keyFor(bucket, id), { type: 'json' });
  }
}
