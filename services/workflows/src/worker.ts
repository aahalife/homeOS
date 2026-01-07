import { NativeConnection, Worker } from '@temporalio/worker';
import * as activities from './activities/index.js';

const TEMPORAL_ADDRESS = process.env['TEMPORAL_ADDRESS'] ?? 'localhost:7233';
const TASK_QUEUE = process.env['TASK_QUEUE'] ?? 'homeos-workflows';

async function run() {
  console.log('Starting HomeOS Temporal Worker...');
  console.log(`Connecting to Temporal at ${TEMPORAL_ADDRESS}`);

  const connection = await NativeConnection.connect({
    address: TEMPORAL_ADDRESS,
  });

  const worker = await Worker.create({
    connection,
    namespace: 'default',
    taskQueue: TASK_QUEUE,
    workflowsPath: new URL('./workflows/index.ts', import.meta.url).pathname,
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
