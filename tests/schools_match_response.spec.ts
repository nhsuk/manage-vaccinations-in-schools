import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("School - match response", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await when_i_go_to_the_session_page();
  await and_i_click_on_the_unmatched_responses_link();
  await then_i_am_on_the_unmatched_responses_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function when_i_go_to_the_session_page() {
  await p.goto("/sessions/1");
}

async function and_i_click_on_the_unmatched_responses_link() {
  await p
    .getByRole("link", {
      name: /responses? need matching with a parent record/,
    })
    .click();
}

async function then_i_am_on_the_unmatched_responses_page() {
  await expect(
    p.getByRole("heading", { name: fixtures.schoolName }),
  ).toBeVisible();
}
