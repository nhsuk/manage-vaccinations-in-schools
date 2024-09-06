import { test, expect, BrowserContext, Request, Route } from "@playwright/test";
import { exec } from "child_process";
import { promisify } from "util";

const asyncExec = promisify(exec);
const goOnline = async () => await asyncExec("bin/online");
const goOffline = async () => await asyncExec("bin/offline");

const swWaitForRequest = (context: BrowserContext, url: string) => {
  return new Promise<Request>((resolve) => {
    context.route(url, (route: Route) => {
      if (route.request().serviceWorker()) {
        resolve(route.request());
      }
      return route.continue();
    });
  });
};

test.beforeEach(async () => {
  await goOnline();
});

test.afterEach(async () => {
  goOnline();
});

test.skip("Works offline", async ({ page, context }) => {
  await page.goto("/reset");
  await expect(page.locator("h1")).toContainText(
    "Manage vaccinations in schools",
  );

  await page.getByTestId("start").click();
  await expect(page.locator("h2")).toContainText("School sessions");

  await page.getByTestId("sessions").click();
  await expect(page.locator("h2")).toContainText("HPV");

  await page.getByTestId("session-link").click();
  await expect(page.locator("h1")).toContainText("HPV programme");

  await page.getByTestId("save-offline").click();
  await expect(page.locator("h1")).toContainText("Create a password");

  await page.getByTestId("password").fill("password1234");
  await page.getByTestId("password-confirmation").fill("password1234");
  await page.getByTestId("submit").click();
  await expect(page.getByRole("heading", { name: "HPV" })).toContainText("HPV");

  await goOffline();

  await page.getByTestId("session-link").click();
  await expect(page.locator("h1")).toContainText("HPV programme");

  await page.getByRole("link", { name: "Record vaccinations" }).click();
  await expect(page.getByTestId("child-status").nth(0)).toContainText(
    "No outcome yet",
  );

  await page.getByTestId("child-link").nth(0).click();
  await expect(page.getByTestId("full-name")).toContainText("Aaron Pfeffer");

  await page.getByTestId("confirm-button").click();

  await goOnline();
  await swWaitForRequest(context, "/sessions/1/vaccinations/1/record");

  await page.goto("/sessions/1/vaccinations");
  await expect(page.getByTestId("child-status").nth(0)).toContainText(
    "Vaccinated",
  );
});
