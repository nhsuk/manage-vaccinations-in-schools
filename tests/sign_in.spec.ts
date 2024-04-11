import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared/sign_in";

let p: Page;

test("Sign-in", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await when_i_go_to_the_start_page();
  await then_i_should_see_the_sign_in_page();

  await when_i_sign_in();
  await then_i_should_see_the_dashboard();
  await and_i_should_see_a_banner_saying_i_am_signed_in();

  // Sign out
  await when_i_sign_out();
  await then_i_should_see_the_start_page();
  await and_i_should_see_a_banner_saying_i_am_signed_out();

  // Saves and redirects the user to the page they were trying to visit before
  // they were rudely interrupted by the sign-in page.
  await when_i_go_to_the_triage_page();
  await then_i_should_see_the_sign_in_page();

  await when_i_sign_in();
  await then_i_should_see_the_triage_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_start_page() {
  await p.goto("/");
  await p.getByRole("link", { name: "Start now" }).click();
}

async function then_i_should_see_the_sign_in_page() {
  await expect(p.getByRole("heading", { name: "Sign in" })).toBeVisible();
}

async function when_i_sign_in() {
  await signInTestUser(p);
}

async function then_i_should_see_the_dashboard() {
  await expect(p).toHaveURL("/dashboard");
}

async function and_i_should_see_a_banner_saying_i_am_signed_in() {
  await expect(p.locator(".nhsuk-notification-banner__content")).toContainText(
    "Signed in successfully.",
  );
}

async function when_i_sign_out() {
  await p.getByRole("button", { name: "Sign out" }).click();
}

async function then_i_should_see_the_start_page() {
  await expect(
    p.getByRole("heading", {
      name: "Manage vaccinations in schools",
    }),
  ).toBeVisible();
  await expect(p).toHaveURL("/start");
}

async function and_i_should_see_a_banner_saying_i_am_signed_out() {
  await expect(p.locator(".nhsuk-notification-banner__content")).toContainText(
    "Signed out successfully.",
  );
}

async function when_i_go_to_the_triage_page() {
  await p.goto("/sessions/1/triage");
}

async function then_i_should_see_the_triage_page() {
  await expect(p).toHaveURL("/sessions/1/triage/needed");
}
