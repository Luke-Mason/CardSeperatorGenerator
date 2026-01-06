import { test, expect } from '@playwright/test';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8080';
const FRONTEND_URL = process.env.FRONTEND_URL || 'http://localhost:5173';

test.describe('Post-Deployment Verification', () => {
  test('backend health check', async ({ request }) => {
    const response = await request.get(`${BACKEND_URL}/api/health`);
    expect(response.ok()).toBeTruthy();

    const json = await response.json();
    expect(json.status).toBe('ok');
    expect(json.database).toBe('ok');
    expect(json.minio).toBe('ok');
  });

  test('backend sets endpoint', async ({ request }) => {
    const response = await request.get(`${BACKEND_URL}/api/sets`);
    expect(response.ok()).toBeTruthy();

    const json = await response.json();
    expect(Array.isArray(json)).toBeTruthy();
  });

  test('frontend loads successfully', async ({ page }) => {
    await page.goto(FRONTEND_URL);
    await expect(page).toHaveTitle(/Card Separator/i);
  });

  test('can load sets through UI', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Wait for page to load
    await page.waitForLoadState('networkidle');

    // Find and fill set ID input
    const setInput = page.locator('input[placeholder*="OP-01"]');
    await setInput.fill('OP-01');

    // Click load cards button
    await page.click('button:has-text("Load Cards")');

    // Wait for cards to load
    await page.waitForSelector('.card, [data-testid="card"]', { timeout: 30000 });

    // Verify cards are displayed
    const cards = await page.locator('.card, [data-testid="card"]').count();
    expect(cards).toBeGreaterThan(0);
  });

  test('backend image proxy works', async ({ request }) => {
    const testImageUrl = 'https://optcgapi.com/images/OP01-001.jpg';
    const encodedUrl = encodeURIComponent(testImageUrl);

    const response = await request.get(`${BACKEND_URL}/api/images/thumbnail?url=${encodedUrl}`);
    expect(response.ok()).toBeTruthy();
    expect(response.headers()['content-type']).toContain('image');
  });

  test('can sync sets via API', async ({ request }) => {
    const response = await request.post(`${BACKEND_URL}/api/sets/sync`);
    expect(response.ok()).toBeTruthy();

    const json = await response.json();
    expect(json.synced_sets).toBeGreaterThan(0);
  });

  test('cache stats endpoint works', async ({ request }) => {
    const response = await request.get(`${BACKEND_URL}/api/cache/stats`);
    expect(response.ok()).toBeTruthy();

    const json = await response.json();
    expect(json).toHaveProperty('total_sets');
    expect(json).toHaveProperty('total_cards');
    expect(json).toHaveProperty('total_images');
  });
});

test.describe('User Workflows', () => {
  test('complete card separator workflow', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Step 1: Load a set
    await page.fill('input[placeholder*="OP-01"]', 'OP-01');
    await page.click('button:has-text("Load Cards")');
    await page.waitForSelector('.card, [data-testid="card"]', { timeout: 30000 });

    // Step 2: Apply filters (if available)
    const colorFilter = page.locator('select, input').filter({ hasText: /color/i }).first();
    if (await colorFilter.count() > 0) {
      await colorFilter.selectOption({ label: 'Red' });
    }

    // Step 3: Verify filtered results
    await page.waitForTimeout(1000);
    const filteredCards = await page.locator('.card, [data-testid="card"]').count();
    expect(filteredCards).toBeGreaterThan(0);

    // Step 4: Test print preview (if available)
    const printButton = page.locator('button:has-text("Print")').first();
    if (await printButton.count() > 0) {
      // Just verify button exists, don't actually trigger print
      expect(await printButton.isVisible()).toBeTruthy();
    }
  });

  test('error handling for invalid set', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Try to load an invalid set
    await page.fill('input[placeholder*="OP-01"]', 'INVALID-SET-99999');
    await page.click('button:has-text("Load Cards")');

    // Should show error message or no cards
    await page.waitForTimeout(3000);
    const errorMessage = page.locator('text=/error|not found|no cards/i');
    const cards = page.locator('.card, [data-testid="card"]');

    // Either error message should be shown or no cards should be loaded
    expect((await errorMessage.count()) > 0 || (await cards.count()) === 0).toBeTruthy();
  });
});

test.describe('Performance', () => {
  test('page load time is acceptable', async ({ page }) => {
    const startTime = Date.now();
    await page.goto(FRONTEND_URL);
    await page.waitForLoadState('networkidle');
    const loadTime = Date.now() - startTime;

    // Page should load in less than 5 seconds
    expect(loadTime).toBeLessThan(5000);
  });

  test('API response time is acceptable', async ({ request }) => {
    const startTime = Date.now();
    const response = await request.get(`${BACKEND_URL}/api/health`);
    const responseTime = Date.now() - startTime;

    expect(response.ok()).toBeTruthy();
    // Health check should respond in less than 1 second
    expect(responseTime).toBeLessThan(1000);
  });
});
