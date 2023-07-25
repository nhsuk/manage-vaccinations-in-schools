import { test, expect } from "@playwright/test";

let p = null;

test("Records gillick consent", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();

  await when_i_go_to_the_vaccinations_page();
  await then_i_see_the_patient_that_needs_consent();

  await when_i_click_on_the_patient();
  await then_i_see_the_no_consent_banner();

  await when_i_click_yes_gillick();
  await and_i_click_continue();
  await then_i_see_the_assessing_gillick_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_vaccinations_page() {
  await p.goto("/sessions/1/vaccinations");
}

async function then_i_see_the_patient_that_needs_consent() {
  await expect(p.getByRole("link", { name: "Alexandra Sipes" })).toBeVisible();
}

async function when_i_click_on_the_patient() {
  await p.click("text=Alexandra Sipes");
}

async function then_i_see_the_no_consent_banner() {
  await expect(p.locator(".app-consent-banner")).toContainText(
    "No-one responded to our requests for consent",
  );
}

async function when_i_click_yes_gillick() {
  await p.click("text=Yes, I am assessing Gillick competence");
}

async function and_i_click_continue() {
  await p.click("text=Continue");
}

async function then_i_see_the_assessing_gillick_page() {
  await expect(p.locator("h1")).toContainText("Gillick competence");
}
