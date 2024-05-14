import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("Consent refused validations", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await given_i_am_on_the_reasons_for_consent_refusal_page();
  await when_i_continue_without_entering_anything();
  await then_i_see_reasons_for_consent_refusal_validation_errors();

  await given_i_select_other_reason();
  await when_i_continue_without_entering_anything();
  await then_i_see_the_reason_notes_page();

  await when_i_continue_without_entering_anything();
  await then_i_see_the_reason_notes_validation_errors();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function given_i_am_on_the_reasons_for_consent_refusal_page() {
  await p.goto("/sessions/1/consents");
  await p.getByRole("link", { name: "No consent" }).click();
  await p.getByRole("link", { name: fixtures.patientThatNeedsConsent }).click();
  await p.getByRole("button", { name: "Get consent" }).click();

  await p.fill('[name="consent[parent_name]"]', "Carl Sipes");
  await p.fill('[name="consent[parent_phone]"]', "07700900000");
  await p.getByRole("radio", { name: "Dad" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByRole("radio", { name: "No, they do not agree" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function when_i_continue_without_entering_anything() {
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_reasons_for_consent_refusal_validation_errors() {
  await expect(p.getByRole("alert").getByText("Choose a reason")).toBeVisible();
}

async function given_i_select_other_reason() {
  await p.getByRole("radio", { name: "Other" }).click();
}

async function then_i_see_the_reason_notes_page() {
  await expect(
    p.getByRole("heading", { name: "Why are they refusing to give consent?" }),
  ).toBeVisible();
}

async function then_i_see_the_reason_notes_validation_errors() {
  await expect(
    p.getByRole("alert").getByText("Enter details for refusing"),
  ).toBeVisible();
}
