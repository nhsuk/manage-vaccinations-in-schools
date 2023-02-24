import { test, expect } from "@playwright/test";
import { exec } from "child_process";
import { promisify } from "util";

const asyncExec = promisify(exec);
const goOnline = async () => await asyncExec("bin/online");
const goOffline = async () => await asyncExec("bin/offline");

test.beforeEach(async () => {
  await goOnline();
});

test.afterEach(async () => {
  goOnline();
});

test("Works offline", async ({ page }) => {
  await page.goto("/");
  await expect(page.locator("h1")).toContainText("Your campaigns");

  await page.getByTestId("campaigns").click();
  await expect(page.locator("h1")).toContainText("HPV campaign");

  await page.getByTestId("save-offline").click();

  await goOffline();

  await page.getByTestId("record").click();
  await expect(page.locator("h1")).toContainText("Record vaccinations");

  await page.getByTestId("child-link").nth(0).click();
  await expect(page.getByTestId("full-name")).toContainText("Aaron Pfeffer");
});
