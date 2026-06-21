import { runAiCitationScan } from './jobs/aiCitationScan';

async function main() {
  console.log('AIReady Stage 6 worker started');
  await runAiCitationScan();
}

main().catch(err => { console.error(err); process.exit(1); });
