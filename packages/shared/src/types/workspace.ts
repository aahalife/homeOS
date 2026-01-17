export interface Workspace {
  id: string;
  name: string;
  ownerId: string;
  createdAt: string;
  updatedAt: string;
}

export interface WorkspaceMember {
  id: string;
  workspaceId: string;
  userId: string;
  role: 'owner' | 'admin' | 'member';
  joinedAt: string;
}

export interface User {
  id: string;
  appleId: string;
  email?: string;
  name?: string;
  avatarUrl?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Device {
  id: string;
  userId: string;
  workspaceId: string;
  name: string;
  platform: 'ios' | 'macos' | 'web';
  apnsToken?: string;
  lastSeenAt: string;
  createdAt: string;
}

export interface SecretStatus {
  provider: 'openai' | 'anthropic' | 'modal';
  configured: boolean;
  lastTestedAt?: string;
  testSuccessful?: boolean;
}

export interface RuntimeConnectionInfo {
  baseUrl: string;
  wsUrl: string;
  token: string;
}
