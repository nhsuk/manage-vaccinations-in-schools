import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("Vaccination refused validations", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await given_i_am_on_the_reason_vaccination_not_given_page_for_a_child();
  await when_i_continue_without_entering_anything();
  await then_i_see_the_reason_for_not_giving_the_vaccination_validation_errors();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function given_i_am_on_the_reason_vaccination_not_given_page_for_a_child() {
  await p.goto("/sessions/1/vaccinations");
  await p.getByRole("tab", { name: "Action needed" }).click();
  await p
    .getByRole("link", { name: fixtures.patientThatNeedsVaccination })
    .click();

  await p.getByRole("radio", { name: /^No/ }).click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function when_i_continue_without_entering_anything() {
  p.click("text=Continue");
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_reason_for_not_giving_the_vaccination_validation_errors() {
  await expect(
    p.locator(".nhsuk-error-message", { hasText: "Choose a reason" }),
  ).toBeVisible();
}
