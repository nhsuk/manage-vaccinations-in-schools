import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("Consent - conflicting", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await given_i_am_checking_consent();
  await when_i_select_a_child_with_conflicting_consent();
  await then_i_see_the_patient_has_conflicting_consent();

  await when_i_attempt_to_contact_the_parent_who_refused();
  await then_i_see_the_consent_response_page();

  await when_i_submit_a_consent_with_no_health_concerns();
  await then_i_see_the_success_banner();

  await when_i_select_the_same_patient();
  await then_i_see_the_patient_has_consent_given();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function given_i_am_checking_consent() {
  await p.goto("/sessions/1/consents");
}

async function when_i_select_a_child_with_conflicting_consent() {
  await p.getByRole("link", { name: "Conflicts" }).click();
  await p
    .getByRole("link", { name: fixtures.patientWithConflictingConsent })
    .click();
}

async function then_i_see_the_patient_has_conflicting_consent() {
  await expect(
    p.getByRole("heading", { name: "Conflicting consent" }),
  ).toBeVisible();
}

async function when_i_attempt_to_contact_the_parent_who_refused() {
  await p
    .getByRole("link", { name: /Contact.*the parent who refused/ })
    .click();
}

async function then_i_see_the_consent_response_page() {
  await expect(p.getByRole("heading", { name: "Do they agree" })).toBeVisible();
}

async function when_i_submit_a_consent_with_no_health_concerns() {
  // Consent
  await p.getByRole("radio", { name: "Yes, they agree" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  // Health questions
  const radio = (n: number) =>
    `input[name="consent[question_${n}][response]"][value="no"]`;

  await p.click(radio(0));
  await p.click(radio(1));
  await p.click(radio(2));
  await p.getByRole("radio", { name: "Yes, it’s safe to vaccinate" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  // Check answers page
  // BUG: this should be 'Consent updated to given (phone)'
  await expect(p.locator("main")).toContainText(
    "Consent updated to given (online)",
  );
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_i_see_the_success_banner() {
  await expect(p.getByRole("heading", { name: "Success" })).toBeVisible();
}

async function when_i_select_the_same_patient() {
  await p.getByRole("link", { name: "Given" }).click();
  await p
    .getByRole("link", { name: fixtures.patientWithConflictingConsent })
    .click();
}

async function then_i_see_the_patient_has_consent_given() {
  await expect(
    p.getByRole("heading", { name: "Safe to vaccinate" }),
  ).toBeVisible();
}
