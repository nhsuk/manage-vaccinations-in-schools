import { test, expect, Page } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

const checkAccessibility = async (page: Page) => {
  const accessibilityScanResults = await new AxeBuilder({ page }).analyze();
  expect(accessibilityScanResults.violations).toHaveLength(0);
};

test("Accessibility", async ({ page }) => {
  // Home page
  await page.goto("/reset");
  await expect(page.locator("h1")).toContainText(
    "Manage vaccinations in schools",
  );
  await checkAccessibility(page);

  // Log in page
  await page.getByRole("link", { name: "Start now" }).click();
  await expect(page.locator("h1")).toContainText("Log in");
  await checkAccessibility(page);

  // Logging in
  await page.getByLabel("Email address").fill("nurse.joy@example.com");
  await page
    .getByLabel("Password", { exact: true })
    .fill("nurse.joy@example.com");
  await page.getByRole("button", { name: "Log in" }).click();
  await expect(page.locator("h1")).toContainText("Mavis");
  await checkAccessibility(page);

  // Vaccines page
  await page.getByRole("heading", { name: "Vaccines" }).click();
  await expect(page.locator("h1")).toContainText("Vaccines");
  await checkAccessibility(page);

  // Vaccine page
  await page.getByRole("link", { name: "Gardasil 9" }).click();
  await expect(page.locator("h1")).toContainText("Gardasil 9");
  await checkAccessibility(page);
});
