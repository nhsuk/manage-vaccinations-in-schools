import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared/sign_in";

let p: Page;

test("Consent - No response", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await when_i_select_a_child_with_no_consent_response();
  await and_i_click_get_consent();
  await then_the_consent_form_is_empty();

  // Consent - No response
  await when_i_submit_a_consent_with_no_response();
  await then_i_see_the_triage_list();

  await when_i_select_a_child_with_no_consent_response();
  await and_i_click_get_consent();
  await then_the_consent_form_is_prepopulated();

  // Consent - With response
  await when_i_submit_a_consent_with_a_response();
  await then_i_see_the_triage_list();

  await when_i_click_the_triage_complete_tab();
  await then_the_patient_is_triaged();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function when_i_select_a_child_with_no_consent_response() {
  await p.goto("/sessions/1/triage");
  await p.getByRole("tab", { name: "Get consent" }).click();
  await p.getByRole("link", { name: "Alexandra Sipes" }).click();
}

async function when_i_click_get_consent() {
  await p.getByRole("button", { name: "Get consent" }).click();
}
const and_i_click_get_consent = when_i_click_get_consent;

async function when_i_click_the_triage_complete_tab() {
  await p.getByRole("tab", { name: "Triage complete" }).click();
}

async function when_i_submit_a_consent_with_no_response() {
  // Who
  await p.fill('[name="consent[parent_name]"]', "Jane Doe");
  await p.fill('[name="consent[parent_phone]"]', "07700900000");
  await p.click("text=Mum");
  await p.getByRole("button", { name: "Continue" }).click();

  // Do they agree
  await p.getByRole("radio", { name: "No response" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  // Check answers
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function when_i_submit_a_consent_with_a_response() {
  await p.getByRole("button", { name: "Continue" }).click();

  // Do they agree
  await p.getByRole("radio", { name: "Yes, they agree" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  // Health questions
  const radio = (n: number) =>
    `input[name="consent[question_${n}][response]"][value="no"]`;
  await p.click(radio(0));
  await p.click(radio(1));
  await p.click(radio(2));
  await p.click(radio(3));

  // Triage
  await p.fill('[name="consent[triage][notes]"]', "Some notes");
  await p.getByRole("radio", { name: "Ready to vaccinate" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  // Check answers
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_i_see_the_triage_list() {
  await expect(p.locator("h1")).toContainText("Triage");
}

async function then_the_consent_form_is_empty() {
  await expect(p.locator('[name="consent[parent_name]"]')).toBeEmpty();
  await expect(p.locator('[name="consent[parent_phone]"]')).toBeEmpty();
  await expect(p.locator("text=Mum")).not.toBeChecked();
}

async function then_the_consent_form_is_prepopulated() {
  await expect(p.locator('[name="consent[parent_name]"]')).toHaveValue(
    "Jane Doe",
  );
  await expect(p.locator('[name="consent[parent_phone]"]')).toHaveValue(
    "07700900000",
  );
  await expect(p.locator("text=Mum")).toBeChecked();
}

async function then_the_patient_is_triaged() {
  await expect(
    p.getByRole("row", {
      name: "Alexandra Sipes Vaccinate",
    }),
  ).toBeVisible();
}
