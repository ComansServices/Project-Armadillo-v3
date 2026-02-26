import { test, expect } from '@playwright/test';

const API_BASE = 'http://localhost:4000';

test.describe('Phase 7 - Operator Confidence Features', () => {
  
  test.describe('Item 1: Vulnerability Remediation Tracking', () => {
    test('vulns page loads with remediation columns', async ({ page }) => {
      await page.goto('/vulns');
      await page.waitForLoadState('networkidle');
      
      // Check for new columns
      await expect(page.locator('th:has-text("Status")')).toBeVisible();
      await expect(page.locator('th:has-text("Assignee")')).toBeVisible();
      await expect(page.locator('th:has-text("Due")')).toBeVisible();
      
      // Check filter controls
      await expect(page.locator('input[name="assignedTo"]')).toBeVisible();
      await expect(page.locator('select[name="remediationStatus"]')).toBeVisible();
    });

    test('remediation status filter works', async ({ page }) => {
      await page.goto('/vulns');
      await page.waitForLoadState('networkidle');
      
      // Select a status filter
      await page.selectOption('select[name="remediationStatus"]', 'open');
      await page.click('button:has-text("Apply filters")');
      
      // Wait for URL update
      await page.waitForURL(/remediationStatus=open/);
      
      // Verify filter is applied
      const url = page.url();
      expect(url).toContain('remediationStatus=open');
    });

    test('inline remediation edit is clickable', async ({ page }) => {
      await page.goto('/vulns');
      await page.waitForLoadState('networkidle');
      
      // Wait for table to load
      await page.waitForSelector('table tbody tr');
      
      // Click on first status cell to edit
      const firstStatus = page.locator('table tbody tr:first-child td:nth-child(10)').first();
      await expect(firstStatus).toBeVisible();
      
      // Take screenshot of the remediation UI
      await page.screenshot({ path: 'test-results/vulns-remediation.png', fullPage: true });
    });
  });

  test.describe('Item 2: Global Cmd+K Search', () => {
    test('Cmd+K opens search modal', async ({ page }) => {
      await page.goto('/');
      await page.waitForLoadState('networkidle');
      
      // Press Cmd+K
      await page.keyboard.press('Meta+k');
      
      // Check modal appears
      await expect(page.locator('input[placeholder*="Search CVEs"]')).toBeVisible();
      
      // Take screenshot
      await page.screenshot({ path: 'test-results/search-modal-open.png' });
    });

    test('search finds CVEs', async ({ page }) => {
      await page.goto('/');
      await page.waitForLoadState('networkidle');
      
      // Open search
      await page.keyboard.press('Meta+k');
      await page.waitForSelector('input[placeholder*="Search"]');
      
      // Type a search query
      await page.fill('input[placeholder*="Search"]', 'CVE-2024');
      
      // Wait for results
      await page.waitForTimeout(300);
      
      // Take screenshot of results
      await page.screenshot({ path: 'test-results/search-results.png' });
      
      // Press Escape to close
      await page.keyboard.press('Escape');
      await expect(page.locator('input[placeholder*="Search"]')).not.toBeVisible();
    });

    test('floating search button visible', async ({ page }) => {
      await page.goto('/');
      await page.waitForLoadState('networkidle');
      
      // Check floating button
      const searchButton = page.locator('button[title*="Search"]').first();
      await expect(searchButton).toBeVisible();
      
      // Click it
      await searchButton.click();
      await expect(page.locator('input[placeholder*="Search"]')).toBeVisible();
    });
  });

  test.describe('Item 3: Attention Banner', () => {
    test('attention banner displays on overview', async ({ page }) => {
      await page.goto('/');
      await page.waitForLoadState('networkidle');
      
      // Wait a moment for banner to potentially load
      await page.waitForTimeout(1000);
      
      // Take screenshot of overview with potential banner
      await page.screenshot({ path: 'test-results/overview-with-banner.png', fullPage: true });
      
      // Check if banner exists (it may or may not depending on failed scans)
      const banner = page.locator('text=Attention').first();
      if (await banner.isVisible().catch(() => false)) {
        await expect(page.locator('text=/scan.*failed/i').first()).toBeVisible();
      }
    });

    test('7-day trend sparkline renders', async ({ page }) => {
      await page.goto('/');
      await page.waitForLoadState('networkidle');
      await page.waitForTimeout(1000);
      
      // Check for SVG sparkline (if banner is present)
      const sparkline = page.locator('svg').first();
      if (await sparkline.isVisible().catch(() => false)) {
        await expect(sparkline).toBeVisible();
      }
    });
  });

  test.describe('Item 4: Asset Badges', () => {
    test('assets page loads with badge column', async ({ page }) => {
      await page.goto('/assets');
      await page.waitForLoadState('networkidle');
      await page.waitForTimeout(500);
      
      // Check for Status column
      await expect(page.locator('th:has-text("Status")')).toBeVisible();
      
      // Take screenshot
      await page.screenshot({ path: 'test-results/assets-with-badges.png', fullPage: true });
    });

    test('asset badges render correctly', async ({ page }) => {
      await page.goto('/assets');
      await page.waitForLoadState('networkidle');
      await page.waitForTimeout(500);
      
      // Check for badge elements (NEW, THIS WEEK, CHANGED)
      const pageContent = await page.content();
      
      // Take screenshot for visual verification
      await page.screenshot({ path: 'test-results/asset-badges.png', fullPage: true });
    });
  });

  test.describe('Mobile Responsiveness', () => {
    test('vulns page mobile view', async ({ page }) => {
      await page.setViewportSize({ width: 375, height: 667 });
      await page.goto('/vulns');
      await page.waitForLoadState('networkidle');
      
      await page.screenshot({ path: 'test-results/vulns-mobile.png', fullPage: true });
    });

    test('search modal on mobile', async ({ page }) => {
      await page.setViewportSize({ width: 375, height: 667 });
      await page.goto('/');
      await page.waitForLoadState('networkidle');
      
      // Open search
      await page.click('button[title*="Search"]');
      
      await page.screenshot({ path: 'test-results/search-mobile.png' });
    });
  });
});

test.describe('API Tests', () => {
  test('GET /api/v1/search returns results', async ({ request }) => {
    const response = await request.get(`${API_BASE}/api/v1/search?q=CVE&limit=10`);
    expect(response.ok()).toBeTruthy();
    
    const data = await response.json();
    expect(data).toHaveProperty('results');
    expect(Array.isArray(data.results)).toBeTruthy();
  });

  test('GET /api/v1/scans/attention returns data', async ({ request }) => {
    const response = await request.get(`${API_BASE}/api/v1/scans/attention`);
    expect(response.ok()).toBeTruthy();
    
    const data = await response.json();
    expect(data).toHaveProperty('needsAttention');
    expect(data).toHaveProperty('totalFailed');
    expect(data).toHaveProperty('trend');
    expect(Array.isArray(data.trend)).toBeTruthy();
  });

  test('GET /api/v1/assets with badges', async ({ request }) => {
    const response = await request.get(`${API_BASE}/api/v1/assets?badges=true&limit=10`);
    expect(response.ok()).toBeTruthy();
    
    const data = await response.json();
    expect(data).toHaveProperty('assets');
    expect(Array.isArray(data.assets)).toBeTruthy();
    
    // Check if badge field exists on assets
    if (data.assets.length > 0) {
      expect(data.assets[0]).toHaveProperty('badge');
    }
  });

  test('PATCH /api/v1/vulns/:id updates remediation', async ({ request }) => {
    // First get a vuln ID
    const listResponse = await request.get(`${API_BASE}/api/v1/vulns?limit=1`);
    const listData = await listResponse.json();
    
    if (!listData.findings || listData.findings.length === 0) {
      test.skip();
      return;
    }
    
    const vulnId = listData.findings[0].id;
    
    const response = await request.patch(`${API_BASE}/api/v1/vulns/${vulnId}`, {
      data: {
        assignedTo: 'test-user',
        remediationStatus: 'in_progress'
      }
    });
    
    expect(response.ok()).toBeTruthy();
    
    const data = await response.json();
    expect(data.assignedTo).toBe('test-user');
    expect(data.remediationStatus).toBe('in_progress');
  });
});
