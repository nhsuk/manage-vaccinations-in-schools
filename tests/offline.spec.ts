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
      return route.fulfill();
    });
  });
};

test.beforeEach(async () => {
  await goOnline();
});

test.afterEach(async () => {
  goOnline();
});

test("Works offline", async ({ page, context }) => {
  await page.goto("/reset");
  await expect(page.locator("h1")).toContainText("Your campaigns");

  await page.getByTestId("campaigns").click();
  await expect(page.locator("h1")).toContainText("HPV campaign");

  await page.getByTestId("save-offline").click();

  // Wait for all the requests to finish and be cached
  await page.waitForTimeout(100);

  await goOffline();

  await page.getByTestId("record").click();
  await expect(page.getByTestId("child-status").nth(0)).toContainText(
    "Not yet"
  );

  await page.getByTestId("child-link").nth(0).click();
  await expect(page.getByTestId("full-name")).toContainText("Aaron Pfeffer");

  await page.getByTestId("confirm-button").click();

  await goOnline();
  await swWaitForRequest(context, "/ping");

  await page.goto("/campaigns/1/children");
  await expect(page.getByTestId("child-status").nth(0)).toContainText(
    "Vaccinated"
  );
});
