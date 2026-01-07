import { randomUUID } from 'node:crypto';

export interface Session {
  id: string;
  workspaceId: string;
  userId: string;
  type: 'dm' | 'group';
  createdAt: string;
  lastActivityAt: string;
  metadata: Record<string, unknown>;
}

export class SessionManager {
  private sessions = new Map<string, Session>();
  private sessionsByWorkspace = new Map<string, Set<string>>();

  create(workspaceId: string, userId: string, type: 'dm' | 'group' = 'dm'): Session {
    const session: Session = {
      id: randomUUID(),
      workspaceId,
      userId,
      type,
      createdAt: new Date().toISOString(),
      lastActivityAt: new Date().toISOString(),
      metadata: {},
    };

    this.sessions.set(session.id, session);

    if (!this.sessionsByWorkspace.has(workspaceId)) {
      this.sessionsByWorkspace.set(workspaceId, new Set());
    }
    this.sessionsByWorkspace.get(workspaceId)!.add(session.id);

    return session;
  }

  get(sessionId: string): Session | undefined {
    return this.sessions.get(sessionId);
  }

  update(sessionId: string, updates: Partial<Session>): Session | undefined {
    const session = this.sessions.get(sessionId);
    if (!session) return undefined;

    const updated = {
      ...session,
      ...updates,
      lastActivityAt: new Date().toISOString(),
    };
    this.sessions.set(sessionId, updated);
    return updated;
  }

  listByWorkspace(workspaceId: string): Session[] {
    const sessionIds = this.sessionsByWorkspace.get(workspaceId);
    if (!sessionIds) return [];

    return Array.from(sessionIds)
      .map((id) => this.sessions.get(id))
      .filter((s): s is Session => s !== undefined);
  }

  close(sessionId: string): boolean {
    const session = this.sessions.get(sessionId);
    if (!session) return false;

    this.sessions.delete(sessionId);
    this.sessionsByWorkspace.get(session.workspaceId)?.delete(sessionId);

    return true;
  }

  closeAll(): void {
    this.sessions.clear();
    this.sessionsByWorkspace.clear();
  }

  touch(sessionId: string): void {
    const session = this.sessions.get(sessionId);
    if (session) {
      session.lastActivityAt = new Date().toISOString();
    }
  }
}
