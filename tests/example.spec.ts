import { test } from "@playwright/test";

const goOffline = async (page) => {
  await page.route("**", (route) => route.abort("internetdisconnected"));
};

test("works offline", async ({ page }) => {
  await page.goto("http://localhost:3000/");
  await page.getByTestId("campaigns").click();
  await page.getByRole("button", { name: "Save offline" }).click();

  await goOffline(page);

  await page.getByTestId("record").click();
  await page.getByRole("link", { name: "Aaron Pfeffer" }).click();
});
