import { encryptSecret, decryptSecret, type EncryptedSecret } from '@homeos/shared/crypto';
import { query, queryOne, execute } from './db.js';
import { WorkspaceService } from './workspace.js';
import type { SecretStatus } from '@homeos/shared';

const MASTER_KEY = process.env['MASTER_ENCRYPTION_KEY'] ?? 'dev-master-key-32-bytes-long!!!';

interface DBSecret {
  id: string;
  workspace_id: string;
  provider: 'openai' | 'anthropic' | 'modal';
  ciphertext: string;
  iv: string;
  auth_tag: string;
  salt: string;
  last_tested_at: string | null;
  test_successful: boolean | null;
  created_at: string;
  updated_at: string;
}

export class SecretsService {
  private workspaceService = new WorkspaceService();

  async setSecret(
    workspaceId: string,
    userId: string,
    provider: 'openai' | 'anthropic' | 'modal',
    apiKey: string
  ): Promise<void> {
    // Check if user is authorized
    const role = await this.workspaceService.getUserRole(workspaceId, userId);
    if (!role || (role !== 'owner' && role !== 'admin')) {
      throw new Error('Not authorized');
    }

    // Encrypt the API key
    const encrypted = await encryptSecret(apiKey, MASTER_KEY);

    // Upsert the secret
    await execute(
      `INSERT INTO homeos.workspace_secrets (workspace_id, provider, ciphertext, iv, auth_tag, salt)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (workspace_id, provider) DO UPDATE SET
         ciphertext = $3,
         iv = $4,
         auth_tag = $5,
         salt = $6,
         last_tested_at = NULL,
         test_successful = NULL,
         updated_at = NOW()`,
      [workspaceId, provider, encrypted.ciphertext, encrypted.iv, encrypted.authTag, encrypted.salt]
    );
  }

  async getStatus(workspaceId: string, userId: string): Promise<SecretStatus[]> {
    // Check if user is a member
    const isMember = await this.workspaceService.isUserMember(workspaceId, userId);
    if (!isMember) {
      throw new Error('Not authorized');
    }

    const providers: Array<'openai' | 'anthropic' | 'modal'> = ['openai', 'anthropic', 'modal'];
    const status: SecretStatus[] = [];

    for (const provider of providers) {
      const secret = await queryOne<DBSecret>(
        `SELECT * FROM homeos.workspace_secrets
         WHERE workspace_id = $1 AND provider = $2`,
        [workspaceId, provider]
      );

      status.push({
        provider,
        configured: secret !== null,
        lastTestedAt: secret?.last_tested_at ?? undefined,
        testSuccessful: secret?.test_successful ?? undefined,
      });
    }

    return status;
  }

  async getDecryptedSecret(
    workspaceId: string,
    provider: 'openai' | 'anthropic' | 'modal'
  ): Promise<string | null> {
    const secret = await queryOne<DBSecret>(
      `SELECT * FROM homeos.workspace_secrets
       WHERE workspace_id = $1 AND provider = $2`,
      [workspaceId, provider]
    );

    if (!secret) {
      return null;
    }

    const encrypted: EncryptedSecret = {
      ciphertext: secret.ciphertext,
      iv: secret.iv,
      authTag: secret.auth_tag,
      salt: secret.salt,
    };

    return decryptSecret(encrypted, MASTER_KEY);
  }

  async testConnection(
    workspaceId: string,
    userId: string,
    provider: 'openai' | 'anthropic' | 'modal'
  ): Promise<{ success: boolean; provider: string; error?: string }> {
    // Check if user is authorized
    const role = await this.workspaceService.getUserRole(workspaceId, userId);
    if (!role || (role !== 'owner' && role !== 'admin')) {
      throw new Error('Not authorized');
    }

    const apiKey = await this.getDecryptedSecret(workspaceId, provider);
    if (!apiKey) {
      return { success: false, provider, error: 'Secret not configured' };
    }

    try {
      // Test the API key with a minimal request
      if (provider === 'openai') {
        const response = await fetch('https://api.openai.com/v1/models', {
          headers: { Authorization: `Bearer ${apiKey}` },
        });
        if (!response.ok) {
          throw new Error(`API returned ${response.status}`);
        }
      } else if (provider === 'anthropic') {
        const response = await fetch('https://api.anthropic.com/v1/messages', {
          method: 'POST',
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            model: 'claude-3-haiku-20240307',
            max_tokens: 1,
            messages: [{ role: 'user', content: 'Hi' }],
          }),
        });
        // 200 or 400 (bad request but valid key) are both acceptable
        if (response.status === 401 || response.status === 403) {
          throw new Error('Invalid API key');
        }
      } else if (provider === 'modal') {
        if (!process.env['MODAL_LLM_URL']) {
          throw new Error('MODAL_LLM_URL not configured');
        }
      }

      // Update test status
      await execute(
        `UPDATE homeos.workspace_secrets
         SET last_tested_at = NOW(), test_successful = true
         WHERE workspace_id = $1 AND provider = $2`,
        [workspaceId, provider]
      );

      return { success: true, provider };
    } catch (error) {
      // Update test status
      await execute(
        `UPDATE homeos.workspace_secrets
         SET last_tested_at = NOW(), test_successful = false
         WHERE workspace_id = $1 AND provider = $2`,
        [workspaceId, provider]
      );

      return {
        success: false,
        provider,
        error: error instanceof Error ? error.message : 'Unknown error',
      };
    }
  }

  async deleteSecret(
    workspaceId: string,
    userId: string,
    provider: 'openai' | 'anthropic' | 'modal'
  ): Promise<void> {
    // Check if user is authorized
    const role = await this.workspaceService.getUserRole(workspaceId, userId);
    if (!role || (role !== 'owner' && role !== 'admin')) {
      throw new Error('Not authorized');
    }

    await execute(
      `DELETE FROM homeos.workspace_secrets
       WHERE workspace_id = $1 AND provider = $2`,
      [workspaceId, provider]
    );
  }
}
