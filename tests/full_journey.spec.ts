import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("Full journey - consent obtained before session", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await given_i_am_checking_consent();
  await when_i_select_a_child_with_no_consent();
  await then_i_see_there_is_no_response();

  await given_i_call_the_parent_and_receive_consent();
  await when_i_record_the_consent_given();
  await and_i_record_the_triage_details();
  await then_i_see_that_the_child_has_gotten_consent();

  await given_i_am_performing_the_vaccination();
  await when_i_record_the_successful_vaccination();
  await then_i_see_that_the_child_is_vaccinated();
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

async function when_i_select_a_child_with_no_consent() {
  await p.getByRole("tab", { name: "No response" }).click();
  await p.getByRole("link", { name: fixtures.patientThatNeedsConsent }).click();
}

async function then_i_see_there_is_no_response() {
  await expect(
    p.locator(".nhsuk-card", {
      has: p.getByRole("heading", { name: "Consent" }),
    }),
  ).toContainText("No response yet");
}

async function given_i_call_the_parent_and_receive_consent() {}

async function when_i_record_the_consent_given() {
  await p.getByRole("button", { name: "Get consent" }).click();
  await p.fill('[name="consent[parent_name]"]', fixtures.parentName);
  await p.fill('[name="consent[parent_phone]"]', "07700900000");
  await p.getByRole("radio", { name: fixtures.parentRole }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByRole("radio", { name: "Yes, they agree" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function and_i_record_the_triage_details() {
  const radio = (n: number) =>
    `input[name="consent[question_${n}][response]"][value="no"]`;

  await p.click(radio(0));
  await p.click(radio(1));
  await p.click(radio(2));
  await p.click(radio(3));
  await p.fill('[name="consent[triage][notes]"]', "Some notes");
  await p.getByRole("radio", { name: "Yes, it's safe to vaccinate" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_i_see_that_the_child_has_gotten_consent() {
  await expect(p.locator(".nhsuk-notification-banner__content")).toContainText(
    `Consent saved for ${fixtures.patientThatNeedsConsent}`,
  );
  const row = p.locator(`tr`, { hasText: fixtures.patientThatNeedsConsent });
  await expect(row).toBeVisible();
}

async function given_i_am_performing_the_vaccination() {
  await p.goto("/sessions/1/vaccinations");
}

async function when_i_record_the_successful_vaccination() {
  await p.getByRole("tab", { name: "Action needed" }).click();
  await p.getByRole("link", { name: fixtures.patientThatNeedsConsent }).click();

  await p.getByRole("radio", { name: "Yes, they got the HPV vaccine" }).click();
  await p.getByRole("radio", { name: "Left arm" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByRole("radio", { name: fixtures.vaccineBatch }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_i_see_that_the_child_is_vaccinated() {
  await expect(p.locator(".nhsuk-notification-banner__content")).toContainText(
    `Record saved for ${fixtures.patientThatNeedsConsent}`,
  );
  await p.getByRole("tab", { name: /^Vaccinated/ }).click();
  const row = p.locator(`tr`, { hasText: fixtures.patientThatNeedsConsent });
  await expect(row).toBeVisible();
  await expect(row.getByTestId("child-action")).toContainText("Vaccinated");
}
