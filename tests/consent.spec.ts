import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared/sign_in";

let p: Page;

test("Check consent responses", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();
  await when_i_go_to_the_consent_page();
  await then_i_see_the_consent_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function when_i_go_to_the_consent_page() {
  await p.goto("/sessions/1/consents");
}

async function then_i_see_the_consent_page() {
  await expect(p.locator("h1")).toHaveText("Check consent responses");
}
