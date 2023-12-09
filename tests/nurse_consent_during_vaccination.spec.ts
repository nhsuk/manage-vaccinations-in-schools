import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("Records consent and then allows vaccination", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await when_i_go_to_the_vaccinations_page();
  await when_i_click_on_a_patient_that_needs_consent();
  await then_i_see_the_vaccination_page();

  await when_i_click_yes_i_am_contacting_a_parent();
  await and_i_click_continue();
  await then_i_see_the_new_consent_form();

  await when_i_go_through_the_consent_and_triage_forms();
  await then_i_see_the_vaccination_form();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function when_i_go_to_the_vaccinations_page() {
  await p.goto("/sessions/1/vaccinations");
}

async function when_i_click_on_a_patient_that_needs_consent() {
  await p.getByRole("link", { name: fixtures.patientThatNeedsConsent }).click();
}

async function then_i_see_the_vaccination_page() {
  expect(await p.innerText("h1")).toContain(fixtures.patientThatNeedsConsent);
}

async function when_i_click_yes_i_am_contacting_a_parent() {
  await p.click("text=Get consent");
}

async function and_i_click_continue() {
  await p.click("text=Continue");
}

async function then_i_see_the_new_consent_form() {
  expect(await p.innerText("h1")).toContain(
    "Who are you trying to get consent from?",
  );
}

async function when_i_go_through_the_consent_and_triage_forms() {
  // Who
  await p.fill('[name="consent[parent_name]"]', fixtures.parentName);
  await p.fill('[name="consent[parent_phone]"]', "07700900000");
  await p.getByRole("radio", { name: fixtures.parentRole }).click();
  await p.click("text=Continue");

  // Do they agree
  await p.click("text=Yes, they agree");
  await p.click("text=Continue");

  // Health questions
  const radio = (n: number) =>
    `input[name="consent[question_${n}][response]"][value="no"]`;

  await p.click(radio(0));
  await p.click(radio(1));
  await p.click(radio(2));

  // Triage
  await p.click("text=Yes, it's safe to vaccinate");
  await p.click("text=Continue");

  // Check answers
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_i_see_the_vaccination_form() {
  expect(await p.innerText("h1")).toContain("Did they get the vaccine?");
}
