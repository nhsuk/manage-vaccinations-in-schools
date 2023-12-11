import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("Consent refused during vaccination", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await given_i_am_performing_vaccinations();
  await when_i_select_a_child_with_no_consent_response();
  await and_i_select_that_i_am_getting_consent();
  await then_the_consent_form_is_prefilled();

  await given_i_call_the_parent_and_they_refuse_consent();
  await when_i_record_the_consent_refused();
  await and_i_record_the_reason_for_refusal();
  // TODO: This is a bug in the app, their status should be do not vaccinate.
  await then_i_see_the_record_vaccinations_page();
  await and_i_see_that_the_child_needs_their_refusal_checked();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function given_i_am_performing_vaccinations() {
  await p.goto("/sessions/1/vaccinations");
}

async function when_i_select_a_child_with_no_consent_response() {
  await p.getByRole("tab", { name: "Action needed" }).click();
  await p.getByRole("link", { name: fixtures.patientThatNeedsConsent }).click();
}

async function when_i_select_that_i_am_getting_consent() {
  await p.click("text=Get consent");
}
const and_i_select_that_i_am_getting_consent =
  when_i_select_that_i_am_getting_consent;

async function then_the_consent_form_is_prefilled() {
  await expect(p.locator('[name="consent[parent_name]"]')).not.toBeEmpty();
  await expect(p.locator('[name="consent[parent_phone]"]')).not.toBeEmpty();
}

async function given_i_call_the_parent_and_they_refuse_consent() {}

async function when_i_record_the_consent_refused() {
  // Who
  await p.fill('[name="consent[parent_name]"]', fixtures.parentName);
  await p.fill('[name="consent[parent_phone]"]', "07700900000");
  await p.getByRole("radio", { name: fixtures.parentRole }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  // Do they agree
  await p.getByRole("radio", { name: "No, they do not agree" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function and_i_record_the_reason_for_refusal() {
  // Why do they not agree
  await p.getByRole("radio", { name: "Personal choice" }).click();

  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_i_see_the_record_vaccinations_page() {
  await expect(p.locator("h1")).toContainText("Record vaccinations");
}

async function and_i_see_that_the_child_needs_their_refusal_checked() {
  await expect(p.locator(".nhsuk-notification-banner__content")).toContainText(
    `Consent saved for ${fixtures.patientThatNeedsConsent}`,
  );
  const row = p.locator(`tr`, { hasText: fixtures.patientThatNeedsConsent });
  await expect(row).toBeVisible();
}
