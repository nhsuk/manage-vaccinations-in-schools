import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared/sign_in";

let p: Page;

test("Session authorisation", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await when_i_sign_in_as_a_nurse_from_another_team();
  await and_i_go_to_the_sessions_list();
  await then_i_should_see_no_sessions();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_sign_in_as_a_nurse_from_another_team() {
  await signInTestUser(p, "jackie@test", "jackie@test");
}

async function and_i_go_to_the_sessions_list() {
  await p.goto("/sessions");
}

async function then_i_should_see_no_sessions() {
  await expect(
    p.getByRole("heading", { name: "School sessions" }),
  ).toBeVisible();
  await expect(p.locator(".nhsuk-table__row")).not.toBeVisible();
}
