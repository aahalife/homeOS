import appleSignIn from 'apple-signin-auth';
import { query, queryOne, execute } from './db.js';
import type { User } from '@homeos/shared';

interface AppleUserInfo {
  email?: string;
  name?: {
    firstName?: string;
    lastName?: string;
  };
}

interface DBUser {
  id: string;
  apple_id: string;
  email: string | null;
  name: string | null;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
}

function toUser(row: DBUser): User {
  return {
    id: row.id,
    appleId: row.apple_id,
    email: row.email ?? undefined,
    name: row.name ?? undefined,
    avatarUrl: row.avatar_url ?? undefined,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export class UserService {
  async authenticateWithApple(
    identityToken: string,
    _authorizationCode: string,
    userInfo?: AppleUserInfo
  ): Promise<{ user: User; isNewUser: boolean }> {
    // Verify the Apple identity token
    const appleUser = await appleSignIn.verifyIdToken(identityToken, {
      audience: process.env['APPLE_CLIENT_ID'] ?? 'com.homeos.app',
      ignoreExpiration: process.env['NODE_ENV'] === 'development',
    });

    const appleId = appleUser.sub;
    const email = appleUser.email ?? userInfo?.email;
    const name = userInfo?.name
      ? [userInfo.name.firstName, userInfo.name.lastName].filter(Boolean).join(' ')
      : undefined;

    // Try to find existing user
    let user = await this.findByAppleId(appleId);

    if (user) {
      // Update email/name if provided and not set
      if ((email && !user.email) || (name && !user.name)) {
        await execute(
          `UPDATE homeos.users SET
            email = COALESCE($2, email),
            name = COALESCE($3, name),
            updated_at = NOW()
          WHERE apple_id = $1`,
          [appleId, email, name]
        );
        user = (await this.findByAppleId(appleId))!;
      }
      return { user, isNewUser: false };
    }

    // Create new user
    const result = await queryOne<DBUser>(
      `INSERT INTO homeos.users (apple_id, email, name)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [appleId, email, name]
    );

    if (!result) {
      throw new Error('Failed to create user');
    }

    return { user: toUser(result), isNewUser: true };
  }

  async findById(id: string): Promise<User | null> {
    const row = await queryOne<DBUser>(
      `SELECT * FROM homeos.users WHERE id = $1`,
      [id]
    );
    return row ? toUser(row) : null;
  }

  async findByAppleId(appleId: string): Promise<User | null> {
    const row = await queryOne<DBUser>(
      `SELECT * FROM homeos.users WHERE apple_id = $1`,
      [appleId]
    );
    return row ? toUser(row) : null;
  }

  async findByEmail(email: string): Promise<User | null> {
    const row = await queryOne<DBUser>(
      `SELECT * FROM homeos.users WHERE email = $1`,
      [email]
    );
    return row ? toUser(row) : null;
  }

  /**
   * Find or create a dev user for passcode authentication.
   * This is only used in development mode.
   */
  async findOrCreateDevUser(deviceId: string): Promise<{ user: User; isNewUser: boolean }> {
    const devAppleId = `dev-user-${deviceId}`;
    const devEmail = `dev-${deviceId}@homeos.local`;
    const devName = 'Dev User';

    // Try to find existing dev user
    let user = await this.findByAppleId(devAppleId);

    if (user) {
      return { user, isNewUser: false };
    }

    // Create new dev user
    const result = await queryOne<DBUser>(
      `INSERT INTO homeos.users (apple_id, email, name)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [devAppleId, devEmail, devName]
    );

    if (!result) {
      throw new Error('Failed to create dev user');
    }

    return { user: toUser(result), isNewUser: true };
  }
}
