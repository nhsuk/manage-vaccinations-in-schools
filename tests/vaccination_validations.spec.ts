import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("Vaccination validations", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await given_i_am_on_the_vaccination_page_for_a_child();
  await when_i_continue_without_entering_anything();
  await then_the_vaccination_validation_errors_are_displayed();

  await given_i_move_on_to_the_how_the_vaccine_was_given_page();
  await when_i_continue_without_entering_anything();
  await then_i_see_the_how_the_vaccine_was_given_validation_errors();

  await given_i_move_on_to_the_batch_selection_page();
  await when_i_continue_without_entering_anything();
  await then_i_see_the_batch_validation_errors();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function given_i_am_on_the_vaccination_page_for_a_child() {
  await p.goto("/sessions/1/vaccinations");
  await p.getByRole("tab", { name: "Action needed" }).click();
  await p
    .getByRole("link", { name: fixtures.patientThatNeedsVaccination })
    .click();
}

async function when_i_continue_without_entering_anything() {
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_the_vaccination_validation_errors_are_displayed() {
  await expect(
    p.getByRole("alert").getByText("Choose if they got the vaccine"),
  ).toBeVisible();
}

async function given_i_move_on_to_the_how_the_vaccine_was_given_page() {
  await p.getByRole("radio", { name: "Yes" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_how_the_vaccine_was_given_validation_errors() {
  await expect(
    p.locator(".nhsuk-error-message", {
      hasText: "Choose a method of delivery",
    }),
  ).toBeVisible();

  await expect(
    p.locator(".nhsuk-error-message", { hasText: "Choose a delivery site" }),
  ).toBeVisible();
}

async function given_i_move_on_to_the_batch_selection_page() {
  await p.getByRole("radio", { name: "Intramuscular" }).click();
  await p.getByRole("radio", { name: "Left thigh" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_batch_validation_errors() {
  await expect(
    p.locator(".nhsuk-error-message", { hasText: "Choose a batch" }),
  ).toBeVisible();
}
