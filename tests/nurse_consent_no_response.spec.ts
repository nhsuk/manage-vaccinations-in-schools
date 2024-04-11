import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("Consent - No response", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await when_i_select_a_child_with_no_consent_response();
  await and_i_click_get_consent();
  await then_the_consent_form_is_prefilled();

  // Consent - No response
  await when_i_submit_a_consent_with_no_response();
  await then_i_see_the_consent_responses_page();

  await when_i_select_a_child_with_no_consent_response();
  await then_i_see_the_previous_attempt_to_get_consent();

  // Consent - With response
  await when_i_click_get_consent();
  await when_i_submit_a_consent_with_a_response();
  await then_i_see_the_consent_responses_page();
  await and_i_see_the_consent_has_been_saved();

  await when_i_go_to_the_triage_completed_tab();
  await then_the_patient_is_triaged();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function when_i_select_a_child_with_no_consent_response() {
  await p.goto("/sessions/1/consents");
  await p.getByRole("tab", { name: "No response" }).click();
  await p.getByRole("link", { name: fixtures.patientThatNeedsConsent }).click();
}

async function when_i_click_get_consent() {
  await p.getByText("Get consent").click();
}
const and_i_click_get_consent = when_i_click_get_consent;

async function then_i_see_the_previous_attempt_to_get_consent() {
  await expect(
    p.getByText(/No response when contacted.*\(phone\)/),
  ).toBeVisible();
}

async function when_i_submit_a_consent_with_no_response() {
  // Who
  await p.fill('[name="consent[parent_name]"]', fixtures.parentName);
  await p.fill('[name="consent[parent_phone]"]', "07700900000");
  await p.getByRole("radio", { name: fixtures.parentRole }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  // Do they agree
  await p.getByRole("radio", { name: "No response" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  // Check answers
  await expect(p.locator("main")).toContainText(
    "No response when contacted (phone)",
  );
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_i_see_the_consent_responses_page() {
  await expect(p.locator("h1")).toContainText("Check consent responses");
}

async function and_i_see_the_consent_has_been_saved() {
  await expect(p.locator(".nhsuk-notification-banner__content")).toContainText(
    `Record saved for ${fixtures.patientThatNeedsConsent}`,
  );
}

async function when_i_submit_a_consent_with_a_response() {
  // Do they agree
  await p.getByRole("radio", { name: "Yes, they agree" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  // Health questions
  const radio = (n: number) =>
    `input[name="consent[question_${n}][response]"][value="no"]`;
  await p.click(radio(0));
  await p.click(radio(1));
  await p.click(radio(2));

  // Triage
  await p.fill('[name="consent[triage][notes]"]', "Some notes");
  await p.getByRole("radio", { name: "Yes, it’s safe to vaccinate" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  // Check answers
  await expect(p.locator("main")).toContainText(
    "Consent updated to given (phone)",
  );
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_the_consent_form_is_prefilled() {
  await expect(p.locator('[name="consent[parent_name]"]')).not.toBeEmpty();
  await expect(p.locator('[name="consent[parent_phone]"]')).not.toBeEmpty();
}

async function when_i_go_to_the_triage_completed_tab() {
  await p.goto("/sessions/1/triage");
  await p.getByRole("link", { name: "Triage completed" }).click();
}

async function then_the_patient_is_triaged() {
  await expect(
    p.getByRole("row", { name: fixtures.patientThatNeedsConsent }),
  ).toBeVisible();
}
