import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared";

let p: Page;

test("Session create", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await when_i_go_to_the_sessions_list();
  await and_i_click_on_the_add_session_button();
  await then_i_see_the_confirm_details_page();

  await when_i_click_on_the_confirm_button();
  await then_i_see_the_session_details_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function when_i_go_to_the_sessions_list() {
  await p.goto("/sessions");
}

async function and_i_click_on_the_add_session_button() {
  await p.click("text=Add a new session");
}

async function then_i_see_the_confirm_details_page() {
  await expect(
    p.getByRole("heading", { name: "Check and confirm details" }),
  ).toBeVisible();
}

async function when_i_click_on_the_confirm_button() {
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_i_see_the_session_details_page() {
  // TODO: Test for the session; page properly
  await expect(
    p.getByRole("heading", { name: "Check consent responses" }),
  ).toBeVisible();
}
