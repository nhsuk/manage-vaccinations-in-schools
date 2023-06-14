import { test, expect } from "@playwright/test";

test("Performing triage", async ({ page, context }) => {
  await page.goto("/reset");

  await page.goto("/sessions/1");
  await page.getByRole("link", { name: "Triage" }).click();

  await expect(page.locator("h1")).toContainText("Triage");

  // Patient 1: Aaron Pfeffer
  await expect(
    page.locator("#patients tr:first-child td:first-child")
  ).toContainText("Aaron Pfeffer");

  await expect(
    page.locator("#patients tr:first-child td:nth-child(3)")
  ).toContainText("To do");

  await expect(
    page.locator("#patients tr:first-child td:nth-child(3) div")
  ).toHaveClass(/nhsuk-tag--grey/);

  // Patient 2: Alaia Lakin
  await expect(
    page.locator("#patients tr:nth-child(2) td:first-child")
  ).toContainText("Alaia Lakin");

  await expect(
    page.locator("#patients tr:nth-child(2) td:nth-child(3)")
  ).toContainText("Ready for session");

  await expect(
    page.locator("#patients tr:nth-child(2) td:nth-child(3) div")
  ).toHaveClass(/nhsuk-tag--green/);

  // Patient 3: Aliza Kshlerin
  await expect(
    page.locator("#patients tr:nth-child(3) td:first-child")
  ).toContainText("Aliza Kshlerin");

  await expect(
    page.locator("#patients tr:nth-child(3) td:nth-child(3)")
  ).toContainText("Ready for session");

  await expect(
    page.locator("#patients tr:nth-child(3) td:nth-child(3) div")
  ).toHaveClass(/nhsuk-tag--green/);

  // Patient 4: Amalia Wiza
  await expect(
    page.locator("#patients tr:nth-child(4) td:first-child")
  ).toContainText("Amalia Wiza");

  await expect(
    page.locator("#patients tr:nth-child(4) td:nth-child(3)")
  ).toContainText("Do not vaccinate");

  await expect(
    page.locator("#patients tr:nth-child(4) td:nth-child(3) div")
  ).toHaveClass(/nhsuk-tag--red/);
});
