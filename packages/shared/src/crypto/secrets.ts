import { createCipheriv, createDecipheriv, randomBytes, scrypt } from 'node:crypto';
import { promisify } from 'node:util';

const scryptAsync = promisify(scrypt);

const ALGORITHM = 'aes-256-gcm';
const KEY_LENGTH = 32;
const IV_LENGTH = 16;
const AUTH_TAG_LENGTH = 16;
const SALT_LENGTH = 32;

export interface EncryptedSecret {
  ciphertext: string;
  iv: string;
  authTag: string;
  salt: string;
}

export async function encryptSecret(
  plaintext: string,
  masterKey: string
): Promise<EncryptedSecret> {
  const salt = randomBytes(SALT_LENGTH);
  const key = (await scryptAsync(masterKey, salt, KEY_LENGTH)) as Buffer;
  const iv = randomBytes(IV_LENGTH);

  const cipher = createCipheriv(ALGORITHM, key, iv);
  let ciphertext = cipher.update(plaintext, 'utf8', 'hex');
  ciphertext += cipher.final('hex');

  const authTag = cipher.getAuthTag();

  return {
    ciphertext,
    iv: iv.toString('hex'),
    authTag: authTag.toString('hex'),
    salt: salt.toString('hex'),
  };
}

export async function decryptSecret(
  encrypted: EncryptedSecret,
  masterKey: string
): Promise<string> {
  const salt = Buffer.from(encrypted.salt, 'hex');
  const key = (await scryptAsync(masterKey, salt, KEY_LENGTH)) as Buffer;
  const iv = Buffer.from(encrypted.iv, 'hex');
  const authTag = Buffer.from(encrypted.authTag, 'hex');

  const decipher = createDecipheriv(ALGORITHM, key, iv);
  decipher.setAuthTag(authTag);

  let plaintext = decipher.update(encrypted.ciphertext, 'hex', 'utf8');
  plaintext += decipher.final('utf8');

  return plaintext;
}
