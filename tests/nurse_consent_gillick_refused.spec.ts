import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared/sign_in";

let p: Page;

test("Records gillick consent refusal", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await given_i_am_performing_vaccinations();
  await when_i_select_a_child_with_no_consent_response();
  await then_i_see_the_no_consent_banner();

  await when_i_select_that_i_am_assessing_gillick_competence();
  await then_i_see_the_gillick_competence_page();

  await when_i_confirm_they_are_gillick_competent();
  await then_i_see_the_do_they_agree_page();

  await given_the_child_does_not_agree();
  await when_i_record_that_they_dont_agree();
  await then_i_see_a_banner_showing_the_gillick_assessment_was_saved();
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
  await p.getByRole("link", { name: "Alexandra Sipes" }).click();
}

async function then_i_see_the_no_consent_banner() {
  await expect(p.locator(".app-consent-banner")).toContainText(
    "No-one responded to our requests for consent",
  );
}

async function when_i_select_that_i_am_assessing_gillick_competence() {
  await p.getByRole("button", { name: "Assess Gillick competence" }).click();
  await p.getByRole("button", { name: "Give your assessment" }).click();
}

async function then_i_see_the_gillick_competence_page() {
  await expect(p.locator("h1")).toContainText("Are they Gillick competent?");
}

async function when_i_confirm_they_are_gillick_competent() {
  await p
    .getByRole("radio", { name: "Yes, they are Gillick competent" })
    .click();
  await p.fill(
    '[name="patient_session[gillick_competence_notes]"]',
    "They were very mature",
  );
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_do_they_agree_page() {
  await expect(p.locator("h1")).toContainText("Do they agree");
}

async function given_the_child_does_not_agree() {}

async function when_i_record_that_they_dont_agree() {
  await p.getByRole("radio", { name: "No, they do not agree" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
  await p.getByRole("radio", { name: "Personal choice" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_i_see_a_banner_showing_the_gillick_assessment_was_saved() {
  await expect(p.locator(".nhsuk-notification-banner__content")).toContainText(
    "Gillick assessment saved",
  );
}
