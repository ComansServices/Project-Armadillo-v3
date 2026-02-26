const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:3000';
const OUTPUT_DIR = './screenshots';

// Ensure output directory exists
if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

const pages = [
  { name: '01-overview', path: '/', desc: 'Command Centre - Scan activity overview with status counts and quick actions' },
  { name: '02-vulnerabilities', path: '/vulns', desc: 'Vulnerability Management - Exploitability filtering, remediation tracking, blast radius' },
  { name: '03-assets', path: '/assets?badges=true', desc: 'Asset Inventory - Change badges (new/updated), IP/hostname search, risk heatmap' },
  { name: '04-network', path: '/network', desc: 'Network Topology - Visual topology, attack path simulation, exposure scoring' },
  { name: '05-imports', path: '/imports', desc: 'Import Pipeline - XML ingestion, quality analytics, CSV exports' },
  { name: '06-schedules', path: '/schedules', desc: 'Scheduled Scans - Cron management, conflict detection, pause/resume' },
  { name: '07-reports', path: '/reports', desc: 'Reporting - PDF exports, archive, scheduled delivery' },
];

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport: { width: 1440, height: 900 }
  });
  const page = await context.newPage();

  console.log('Taking Armadillo screenshots...\n');

  for (const { name, path: pagePath, desc } of pages) {
    try {
      console.log(`📸 ${name}: ${desc}`);
      await page.goto(`${BASE_URL}${pagePath}`, { waitUntil: 'networkidle' });
      await page.waitForTimeout(1000); // Let things settle
      
      const screenshotPath = path.join(OUTPUT_DIR, `${name}.png`);
      await page.screenshot({ 
        path: screenshotPath,
        fullPage: true 
      });
      console.log(`   ✅ Saved to ${screenshotPath}`);
    } catch (err) {
      console.log(`   ❌ Error: ${err.message}`);
    }
  }

  await browser.close();
  console.log('\n✨ Done! Screenshots saved to:', OUTPUT_DIR);
})();
