import { test, expect } from "@playwright/test";

test("Records vaccinations", async ({ page }) => {
  await page.goto("/reset");

  await page.goto("/sessions/1/vaccinations");
  await expect(page.getByTestId("child-status").nth(0)).toContainText(
    "No outcome yet"
  );
});
