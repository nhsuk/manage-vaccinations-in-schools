import { test, expect } from "@playwright/test";

let p = null;

test("Records consent", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();

  await when_i_go_to_the_triage_page();
  await and_i_click_the_consent_tab();
  await then_i_see_the_patient_that_needs_consent();

  await when_i_click_on_the_patient();
  await then_i_see_the_no_consent_banner();

  await when_i_click_get_consent();
  // await then_i_see_the_consent_form();

  // await when_i_enter_the_consent_details();
  // await and_i_click_continue();
  // await then_i_see_do_they_agree_page();

  // await when_i_click_yes();
  // await then_i_see_the_health_questions_page();

  // await when_i_answer_the_health_questions();
  // await and_i_click_continue();
  await then_i_see_the_check_answers_page();

  // await when_i_click_confirm();
  // await then_i_see_the_patient_details();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_triage_page() {
  await p.goto("/sessions/1/triage");
}

async function and_i_click_the_consent_tab() {
  await p.getByRole("tab", { name: "Get consent", exact: true }).click();
}

async function then_i_see_the_patient_that_needs_consent() {
  await expect(p.getByRole("link", { name: "Alexandra Sipes" })).toBeVisible();
}

async function when_i_click_on_the_patient() {
  await p.getByRole("link", { name: "Alexandra Sipes" }).click();
}

async function then_i_see_the_no_consent_banner() {
  await expect(p.locator(".app-consent-banner")).toContainText(
    "No-one responded to our requests for consent",
  );
}

async function when_i_click_get_consent() {
  await p.getByRole("button", { name: "Get consent" }).click();
}

async function then_i_see_the_check_answers_page() {
  await expect(p.locator("h1")).toContainText("Check and confirm answers");
}
