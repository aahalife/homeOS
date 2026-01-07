import { query, queryOne, execute } from './db.js';
import type { Device } from '@homeos/shared';

interface DBDevice {
  id: string;
  user_id: string;
  workspace_id: string;
  name: string;
  platform: 'ios' | 'macos' | 'web';
  apns_token: string | null;
  last_seen_at: string;
  created_at: string;
}

interface RegisterDeviceInput {
  userId: string;
  workspaceId: string;
  name: string;
  platform: 'ios' | 'macos' | 'web';
  apnsToken?: string;
}

function toDevice(row: DBDevice): Device {
  return {
    id: row.id,
    userId: row.user_id,
    workspaceId: row.workspace_id,
    name: row.name,
    platform: row.platform,
    apnsToken: row.apns_token ?? undefined,
    lastSeenAt: row.last_seen_at,
    createdAt: row.created_at,
  };
}

export class DeviceService {
  async register(input: RegisterDeviceInput): Promise<Device> {
    const device = await queryOne<DBDevice>(
      `INSERT INTO homeos.devices (user_id, workspace_id, name, platform, apns_token)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [input.userId, input.workspaceId, input.name, input.platform, input.apnsToken]
    );

    if (!device) {
      throw new Error('Failed to register device');
    }

    return toDevice(device);
  }

  async listForUser(userId: string, workspaceId?: string): Promise<Device[]> {
    let sql = `SELECT * FROM homeos.devices WHERE user_id = $1`;
    const params: unknown[] = [userId];

    if (workspaceId) {
      sql += ` AND workspace_id = $2`;
      params.push(workspaceId);
    }

    sql += ` ORDER BY last_seen_at DESC`;

    const rows = await query<DBDevice>(sql, params);
    return rows.map(toDevice);
  }

  async findById(deviceId: string): Promise<Device | null> {
    const row = await queryOne<DBDevice>(
      `SELECT * FROM homeos.devices WHERE id = $1`,
      [deviceId]
    );
    return row ? toDevice(row) : null;
  }

  async updateToken(deviceId: string, userId: string, apnsToken: string): Promise<boolean> {
    const result = await execute(
      `UPDATE homeos.devices
       SET apns_token = $3, last_seen_at = NOW()
       WHERE id = $1 AND user_id = $2`,
      [deviceId, userId, apnsToken]
    );
    return result > 0;
  }

  async updateLastSeen(deviceId: string): Promise<void> {
    await execute(
      `UPDATE homeos.devices SET last_seen_at = NOW() WHERE id = $1`,
      [deviceId]
    );
  }

  async unregister(deviceId: string, userId: string): Promise<boolean> {
    const result = await execute(
      `DELETE FROM homeos.devices WHERE id = $1 AND user_id = $2`,
      [deviceId, userId]
    );
    return result > 0;
  }

  async listForWorkspace(workspaceId: string): Promise<Device[]> {
    const rows = await query<DBDevice>(
      `SELECT * FROM homeos.devices WHERE workspace_id = $1 ORDER BY last_seen_at DESC`,
      [workspaceId]
    );
    return rows.map(toDevice);
  }
}
