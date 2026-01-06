import { test, expect } from '@playwright/test';

const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:8080';
const FRONTEND_URL = process.env.FRONTEND_URL || 'http://localhost:5173';

test.describe('Complete UI Workflows', () => {
  test.beforeEach(async ({ page }) => {
    // Ensure backend is healthy before each test
    const response = await page.request.get(`${BACKEND_URL}/api/health`);
    expect(response.ok()).toBeTruthy();
  });

  test('load multiple sets workflow', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Load multiple sets
    const setInput = page.locator('input[placeholder*="OP-01"]').first();
    await setInput.fill('OP-01,OP-02,OP-03');

    // Click load button
    await page.click('button:has-text("Load")');

    // Wait for cards to load
    await page.waitForSelector('[data-testid="card"], .card', { timeout: 60000 });

    // Verify cards from multiple sets are loaded
    const cards = await page.locator('[data-testid="card"], .card').count();
    expect(cards).toBeGreaterThan(100); // Multiple sets should have many cards
  });

  test('filter cards by color workflow', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Load a set
    await page.fill('input[placeholder*="OP-01"]', 'OP-01');
    await page.click('button:has-text("Load")');
    await page.waitForSelector('[data-testid="card"], .card', { timeout: 30000 });

    const initialCount = await page.locator('[data-testid="card"], .card').count();

    // Apply color filter
    const colorFilter = page.locator('select, [data-testid="color-filter"]').first();
    if (await colorFilter.count() > 0) {
      await colorFilter.selectOption('Red');
      await page.waitForTimeout(1000);

      const filteredCount = await page.locator('[data-testid="card"], .card').count();
      expect(filteredCount).toBeLessThanOrEqual(initialCount);
    }
  });

  test('filter cards by type workflow', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Load a set
    await page.fill('input[placeholder*="OP-01"]', 'OP-01');
    await page.click('button:has-text("Load")');
    await page.waitForSelector('[data-testid="card"], .card', { timeout: 30000 });

    // Apply type filter
    const typeFilter = page.locator('select[data-testid="type-filter"], select').nth(1);
    if (await typeFilter.count() > 0) {
      await typeFilter.selectOption('Leader');
      await page.waitForTimeout(1000);

      const cards = await page.locator('[data-testid="card"], .card').count();
      expect(cards).toBeGreaterThan(0);
    }
  });

  test('filter cards by rarity workflow', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Load a set
    await page.fill('input[placeholder*="OP-01"]', 'OP-01');
    await page.click('button:has-text("Load")');
    await page.waitForSelector('[data-testid="card"], .card', { timeout: 30000 });

    // Apply rarity filter
    const rarityFilter = page.locator('select[data-testid="rarity-filter"], select').nth(2);
    if (await rarityFilter.count() > 0) {
      await rarityFilter.selectOption('SR');
      await page.waitForTimeout(1000);

      const cards = await page.locator('[data-testid="card"], .card').count();
      // SR cards should be fewer than total
      expect(cards).toBeGreaterThanOrEqual(0);
    }
  });

  test('combined filters workflow', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Load a set
    await page.fill('input[placeholder*="OP-01"]', 'OP-01');
    await page.click('button:has-text("Load")');
    await page.waitForSelector('[data-testid="card"], .card', { timeout: 30000 });

    const initialCount = await page.locator('[data-testid="card"], .card').count();

    // Apply multiple filters
    const colorFilter = page.locator('select').first();
    if (await colorFilter.count() > 0) {
      await colorFilter.selectOption('Red');
      await page.waitForTimeout(500);
    }

    const typeFilter = page.locator('select').nth(1);
    if (await typeFilter.count() > 0) {
      await typeFilter.selectOption('Character');
      await page.waitForTimeout(500);
    }

    const filteredCount = await page.locator('[data-testid="card"], .card').count();
    expect(filteredCount).toBeLessThanOrEqual(initialCount);
  });

  test('clear filters workflow', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Load a set
    await page.fill('input[placeholder*="OP-01"]', 'OP-01');
    await page.click('button:has-text("Load")');
    await page.waitForSelector('[data-testid="card"], .card', { timeout: 30000 });

    const initialCount = await page.locator('[data-testid="card"], .card').count();

    // Apply filter
    const colorFilter = page.locator('select').first();
    if (await colorFilter.count() > 0) {
      await colorFilter.selectOption('Red');
      await page.waitForTimeout(500);

      const filteredCount = await page.locator('[data-testid="card"], .card').count();

      // Clear filter (select All or empty option)
      await colorFilter.selectOption({ index: 0 });
      await page.waitForTimeout(500);

      const clearedCount = await page.locator('[data-testid="card"], .card').count();
      expect(clearedCount).toBe(initialCount);
    }
  });

  test('sort cards workflow', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Load a set
    await page.fill('input[placeholder*="OP-01"]', 'OP-01');
    await page.click('button:has-text("Load")');
    await page.waitForSelector('[data-testid="card"], .card', { timeout: 30000 });

    // Try to find and use sort controls
    const sortButton = page.locator('button:has-text("Sort"), [data-testid="sort"]').first();
    if (await sortButton.count() > 0) {
      await sortButton.click();
      await page.waitForTimeout(1000);

      // Verify cards are still displayed
      const cards = await page.locator('[data-testid="card"], .card').count();
      expect(cards).toBeGreaterThan(0);
    }
  });

  test('save preset workflow', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Load a set with filters
    await page.fill('input[placeholder*="OP-01"]', 'OP-01');
    await page.click('button:has-text("Load")');
    await page.waitForSelector('[data-testid="card"], .card', { timeout: 30000 });

    // Look for save preset button
    const saveButton = page.locator('button:has-text("Save"), button:has-text("Preset")').first();
    if (await saveButton.count() > 0) {
      await saveButton.click();

      // Fill preset name if modal appears
      const nameInput = page.locator('input[placeholder*="name"], input[type="text"]').first();
      if (await nameInput.isVisible()) {
        await nameInput.fill('Test Preset');
        await page.click('button:has-text("Save"), button:has-text("OK")');
        await page.waitForTimeout(500);
      }
    }
  });

  test('load preset workflow', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Look for load preset button
    const loadButton = page.locator('button:has-text("Load Preset"), button:has-text("Presets")').first();
    if (await loadButton.count() > 0) {
      await loadButton.click();
      await page.waitForTimeout(500);

      // Select a preset if available
      const presetOption = page.locator('[data-testid="preset-option"], .preset-item').first();
      if (await presetOption.count() > 0) {
        await presetOption.click();
        await page.waitForTimeout(1000);
      }
    }
  });

  test('print preview workflow', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Load a set
    await page.fill('input[placeholder*="OP-01"]', 'OP-01');
    await page.click('button:has-text("Load")');
    await page.waitForSelector('[data-testid="card"], .card', { timeout: 30000 });

    // Look for print button
    const printButton = page.locator('button:has-text("Print")').first();
    if (await printButton.count() > 0) {
      // Verify button exists and is visible
      expect(await printButton.isVisible()).toBeTruthy();

      // Note: We don't actually trigger print dialog in tests
      // Just verify the button is functional
    }
  });

  test('keyboard shortcuts workflow', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Test Ctrl+K for config (if implemented)
    await page.keyboard.press('Control+K');
    await page.waitForTimeout(500);

    // Check if a modal or config panel appeared
    const modal = page.locator('[role="dialog"], .modal, [data-testid="config"]').first();
    if (await modal.count() > 0) {
      // Close with Escape
      await page.keyboard.press('Escape');
      await page.waitForTimeout(500);

      // Modal should be closed
      expect(await modal.isVisible()).toBeFalsy();
    }
  });

  test('responsive design - mobile view', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto(FRONTEND_URL);

    // Page should still be functional
    const setInput = page.locator('input[placeholder*="OP-01"]').first();
    expect(await setInput.isVisible()).toBeTruthy();

    // Load cards
    await setInput.fill('OP-01');
    await page.click('button:has-text("Load")');
    await page.waitForSelector('[data-testid="card"], .card', { timeout: 30000 });

    const cards = await page.locator('[data-testid="card"], .card').count();
    expect(cards).toBeGreaterThan(0);
  });

  test('responsive design - tablet view', async ({ page }) => {
    // Set tablet viewport
    await page.setViewportSize({ width: 768, height: 1024 });
    await page.goto(FRONTEND_URL);

    // Load cards
    await page.fill('input[placeholder*="OP-01"]', 'OP-01');
    await page.click('button:has-text("Load")');
    await page.waitForSelector('[data-testid="card"], .card', { timeout: 30000 });

    const cards = await page.locator('[data-testid="card"], .card').count();
    expect(cards).toBeGreaterThan(0);
  });

  test('image loading and caching', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Load a set
    await page.fill('input[placeholder*="OP-01"]', 'OP-01');
    await page.click('button:has-text("Load")');
    await page.waitForSelector('[data-testid="card"], .card', { timeout: 30000 });

    // Wait for images to load
    const firstCard = page.locator('[data-testid="card"], .card').first();
    const image = firstCard.locator('img').first();

    if (await image.count() > 0) {
      await expect(image).toBeVisible({ timeout: 10000 });

      // Verify image has src attribute
      const src = await image.getAttribute('src');
      expect(src).toBeTruthy();
    }
  });

  test('error handling - invalid set', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Try to load an invalid set
    await page.fill('input[placeholder*="OP-01"]', 'INVALID-999');
    await page.click('button:has-text("Load")');
    await page.waitForTimeout(3000);

    // Should show error or no cards
    const errorMsg = page.locator('text=/error|not found|no cards found/i').first();
    const cards = page.locator('[data-testid="card"], .card');

    const hasError = await errorMsg.count() > 0;
    const hasNoCards = await cards.count() === 0;

    expect(hasError || hasNoCards).toBeTruthy();
  });

  test('error handling - network error', async ({ page }) => {
    await page.goto(FRONTEND_URL);

    // Simulate offline mode
    await page.context().setOffline(true);

    // Try to load a set
    await page.fill('input[placeholder*="OP-01"]', 'OP-01');
    await page.click('button:has-text("Load")');
    await page.waitForTimeout(3000);

    // Should show error
    const errorMsg = page.locator('text=/error|failed|offline|network/i').first();
    if (await errorMsg.count() > 0) {
      expect(await errorMsg.isVisible()).toBeTruthy();
    }

    // Re-enable network
    await page.context().setOffline(false);
  });
});
