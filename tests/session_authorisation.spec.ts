import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("Session authorisation", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await when_i_sign_in_as_a_nurse_from_another_team();
  await and_i_go_to_the_sessions_list();
  await then_i_should_see_only_my_session();

  await when_i_go_to_a_session_belonging_to_another_team();
  await then_i_should_get_an_error();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_sign_in_as_a_nurse_from_another_team() {
  await signInTestUser(
    p,
    "nurse.jackie@example.com",
    "nurse.jackie@example.com",
  );
}

async function and_i_go_to_the_sessions_list() {
  await p.goto("/sessions");
}

async function then_i_should_see_only_my_session() {
  await expect(
    p.getByRole("heading", { name: "Today’s sessions" }),
  ).toBeVisible();
  await expect(p.locator(".nhsuk-table__body .nhsuk-table__row")).toHaveCount(
    1,
  );
  await expect(p.locator(".nhsuk-table__body .nhsuk-table__row")).toHaveText(
    fixtures.secondSchoolName,
  );
}

async function when_i_go_to_a_session_belonging_to_another_team() {
  await p.goto("/sessions/1");
}

async function then_i_should_get_an_error() {
  await expect(
    p.getByRole("heading", { name: "Page not found" }),
  ).toBeVisible();
}
