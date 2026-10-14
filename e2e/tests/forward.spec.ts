import { test, expect } from '@playwright/test';

test('Success PoW', async ({ page }) => {
  test.setTimeout(60_000);
  const renderer = await page.evaluate(() => {
    const canvas = document.createElement('canvas');
    const gl = canvas.getContext('webgl');
    const info = gl?.getExtension('WEBGL_debug_renderer_info');
    return info ? gl.getParameter(info.UNMASKED_RENDERER_WEBGL) : 'no webgl';
  });
  const start = new Date().getTime();

  await page.goto('http://localhost:8080/');

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/HumansGate/, {timeout: 120_000});

  const end = new Date().getTime();
  console.log('Time', end - start , 'on', renderer);
});
