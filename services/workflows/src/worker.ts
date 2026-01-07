import { NativeConnection, Worker } from '@temporalio/worker';
import * as activities from './activities/index.js';

const TEMPORAL_ADDRESS = process.env['TEMPORAL_ADDRESS'] ?? 'localhost:7233';
const TEMPORAL_NAMESPACE = process.env['TEMPORAL_NAMESPACE'] ?? 'default';
const TEMPORAL_API_KEY = process.env['TEMPORAL_API_KEY'];
const TASK_QUEUE = process.env['TASK_QUEUE'] ?? 'homeos-workflows';

async function run() {
  console.log('Starting HomeOS Temporal Worker...');
  console.log(`Connecting to Temporal at ${TEMPORAL_ADDRESS}`);
  console.log(`Using namespace: ${TEMPORAL_NAMESPACE}`);

  // Configure connection options for Temporal Cloud
  const isTemporalCloud = TEMPORAL_ADDRESS.includes('temporal.io');

  const connectionOptions: Parameters<typeof NativeConnection.connect>[0] = {
    address: TEMPORAL_ADDRESS,
  };

  // Add TLS and API key authentication for Temporal Cloud
  if (isTemporalCloud && TEMPORAL_API_KEY) {
    console.log('Configuring Temporal Cloud authentication...');
    connectionOptions.tls = true;
    connectionOptions.apiKey = TEMPORAL_API_KEY;
  }

  const connection = await NativeConnection.connect(connectionOptions);

  const worker = await Worker.create({
    connection,
    namespace: TEMPORAL_NAMESPACE,
    taskQueue: TASK_QUEUE,
    workflowsPath: new URL('./workflows/index.js', import.meta.url).pathname,
    activities,
  });

  console.log(`Worker started on task queue: ${TASK_QUEUE}`);

  // Handle shutdown signals
  const shutdown = async () => {
    console.log('Shutting down worker...');
    await worker.shutdown();
    await connection.close();
    process.exit(0);
  };

  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);

  await worker.run();
}

run().catch((err) => {
  console.error('Worker failed:', err);
  process.exit(1);
});
