import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("School - match response", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await when_i_go_to_the_session_page();
  await and_i_click_on_the_check_consent_responses_link();
  await and_i_click_on_the_unmatched_responses_link();
  await then_i_am_on_the_unmatched_responses_page();

  await when_i_click_on_an_unmatched_response();
  await then_i_am_on_the_consent_form_page();
  await and_i_can_see_the_patient_details();
  await and_i_can_see_the_consent_details();
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

async function and_i_click_on_the_check_consent_responses_link() {
  await p.getByRole("link", { name: "Check consent responses" }).click();
}

async function and_i_click_on_the_unmatched_responses_link() {
  await p
    .getByRole("link", {
      name: /responses? need matching with records in the cohort/,
    })
    .click();
}

async function then_i_am_on_the_unmatched_responses_page() {
  await expect(
    p.getByRole("heading", { name: fixtures.schoolName }),
  ).toBeVisible();
}

async function when_i_click_on_an_unmatched_response() {
  await p
    .getByRole("link", { name: fixtures.unmatchedConsentFormParentName })
    .click();
}

async function then_i_am_on_the_consent_form_page() {
  await expect(
    p.getByRole("heading", {
      name: `Consent response for ${fixtures.unmatchedConsentFormParentName}`,
    }),
  ).toBeVisible();
}

async function and_i_can_see_the_patient_details() {
  const detailsCard = p
    .locator("div.nhsuk-card")
    .filter({ has: p.getByRole("heading", { name: "Child details" }) });

  await expect(detailsCard).toBeVisible();
  await expect(detailsCard).toHaveText(
    new RegExp("Name" + fixtures.unmatchedConsentFormChildName),
  );
}

async function and_i_can_see_the_consent_details() {
  const consentCard = p
    .locator("div.nhsuk-card")
    .filter({ has: p.getByRole("heading", { name: "Consent" }) });

  await expect(consentCard).toBeVisible();
  await expect(consentCard).toHaveText(
    new RegExp("Name" + fixtures.unmatchedConsentFormParentName),
  );
}
