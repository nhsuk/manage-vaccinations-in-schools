import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared/sign_in";

let p: Page;

test("Triage validations", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();

  // Triage page validation
  await given_i_am_on_the_triage_page_for_a_child();
  await when_i_continue_without_entering_anything();
  await then_the_triage_validation_errors_are_displayed();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await p.goto("/users/sign_in");
  await signInTestUser(p);
}

async function given_i_am_on_the_triage_page_for_a_child() {
  await p.goto("/sessions/1/triage");
  await p.getByRole("tab", { name: "Needs triage" }).click();
  await p.getByRole("link", { name: "Blaine DuBuque" }).click();
}

async function when_i_continue_without_entering_anything() {
  await p.getByRole("button", { name: "Save triage" }).click();
}

async function then_the_triage_validation_errors_are_displayed() {
  await expect(p.getByRole("alert").getByText("Choose a status")).toBeVisible();
}
