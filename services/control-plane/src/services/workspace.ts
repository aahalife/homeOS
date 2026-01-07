import { query, queryOne, execute } from './db.js';
import type { Workspace, WorkspaceMember } from '@homeos/shared';

interface DBWorkspace {
  id: string;
  name: string;
  owner_id: string;
  created_at: string;
  updated_at: string;
}

interface DBWorkspaceMember {
  id: string;
  workspace_id: string;
  user_id: string;
  role: 'owner' | 'admin' | 'member';
  joined_at: string;
}

interface WorkspaceWithRole {
  id: string;
  name: string;
  role: string;
  createdAt: string;
}

interface WorkspaceDetails extends Workspace {
  members: Array<{ userId: string; role: string; name?: string }>;
}

export class WorkspaceService {
  async create(name: string, ownerId: string): Promise<Workspace> {
    const workspace = await queryOne<DBWorkspace>(
      `INSERT INTO homeos.workspaces (name, owner_id)
       VALUES ($1, $2)
       RETURNING *`,
      [name, ownerId]
    );

    if (!workspace) {
      throw new Error('Failed to create workspace');
    }

    // Add owner as a member with 'owner' role
    await execute(
      `INSERT INTO homeos.workspace_members (workspace_id, user_id, role)
       VALUES ($1, $2, 'owner')`,
      [workspace.id, ownerId]
    );

    return {
      id: workspace.id,
      name: workspace.name,
      ownerId: workspace.owner_id,
      createdAt: workspace.created_at,
      updatedAt: workspace.updated_at,
    };
  }

  async listForUser(userId: string): Promise<WorkspaceWithRole[]> {
    const rows = await query<DBWorkspace & { role: string }>(
      `SELECT w.*, wm.role
       FROM homeos.workspaces w
       JOIN homeos.workspace_members wm ON w.id = wm.workspace_id
       WHERE wm.user_id = $1
       ORDER BY w.created_at DESC`,
      [userId]
    );

    return rows.map((row) => ({
      id: row.id,
      name: row.name,
      role: row.role,
      createdAt: row.created_at,
    }));
  }

  async findById(workspaceId: string, userId: string): Promise<WorkspaceDetails | null> {
    // Check if user is a member
    const member = await queryOne<DBWorkspaceMember>(
      `SELECT * FROM homeos.workspace_members
       WHERE workspace_id = $1 AND user_id = $2`,
      [workspaceId, userId]
    );

    if (!member) {
      return null;
    }

    const workspace = await queryOne<DBWorkspace>(
      `SELECT * FROM homeos.workspaces WHERE id = $1`,
      [workspaceId]
    );

    if (!workspace) {
      return null;
    }

    const members = await query<{ user_id: string; role: string; name: string | null }>(
      `SELECT wm.user_id, wm.role, u.name
       FROM homeos.workspace_members wm
       JOIN homeos.users u ON wm.user_id = u.id
       WHERE wm.workspace_id = $1`,
      [workspaceId]
    );

    return {
      id: workspace.id,
      name: workspace.name,
      ownerId: workspace.owner_id,
      createdAt: workspace.created_at,
      updatedAt: workspace.updated_at,
      members: members.map((m) => ({
        userId: m.user_id,
        role: m.role,
        name: m.name ?? undefined,
      })),
    };
  }

  async addMember(
    workspaceId: string,
    requestingUserId: string,
    email: string,
    role: 'admin' | 'member'
  ): Promise<void> {
    // Check if requesting user is owner or admin
    const requestingMember = await queryOne<DBWorkspaceMember>(
      `SELECT * FROM homeos.workspace_members
       WHERE workspace_id = $1 AND user_id = $2`,
      [workspaceId, requestingUserId]
    );

    if (!requestingMember || (requestingMember.role !== 'owner' && requestingMember.role !== 'admin')) {
      throw new Error('Not authorized');
    }

    // Find user by email
    const user = await queryOne<{ id: string }>(
      `SELECT id FROM homeos.users WHERE email = $1`,
      [email]
    );

    if (!user) {
      throw new Error('User not found');
    }

    // Add member (upsert)
    await execute(
      `INSERT INTO homeos.workspace_members (workspace_id, user_id, role)
       VALUES ($1, $2, $3)
       ON CONFLICT (workspace_id, user_id) DO UPDATE SET role = $3`,
      [workspaceId, user.id, role]
    );
  }

  async isUserMember(workspaceId: string, userId: string): Promise<boolean> {
    const member = await queryOne<DBWorkspaceMember>(
      `SELECT * FROM homeos.workspace_members
       WHERE workspace_id = $1 AND user_id = $2`,
      [workspaceId, userId]
    );
    return member !== null;
  }

  async getUserRole(workspaceId: string, userId: string): Promise<string | null> {
    const member = await queryOne<DBWorkspaceMember>(
      `SELECT * FROM homeos.workspace_members
       WHERE workspace_id = $1 AND user_id = $2`,
      [workspaceId, userId]
    );
    return member?.role ?? null;
  }
}
