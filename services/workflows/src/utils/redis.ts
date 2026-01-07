/**
 * Redis utility for caching and temporary storage
 */

import { createClient, type RedisClientType } from 'redis';

let redisClient: RedisClientType | null = null;

export function getRedis(): RedisClientType | null {
  if (!redisClient && process.env['REDIS_URL']) {
    redisClient = createClient({
      url: process.env['REDIS_URL'],
    });
    redisClient.connect().catch(console.error);
  }
  return redisClient;
}

export async function closeRedis(): Promise<void> {
  if (redisClient) {
    await redisClient.quit();
    redisClient = null;
  }
}
