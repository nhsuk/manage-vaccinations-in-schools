import { test, expect, Page } from "@playwright/test";

let p: Page;

test("Parental consent - Consent refused", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await when_i_go_through_the_consent_journey();
  await then_i_see_the_consent_page();

  await when_i_refuse_consent();
  await and_i_click_continue();
  await then_i_see_the_reason_page();

  await when_i_choose_contains_gelatine_as_the_reason();
  await and_i_click_continue();
  await then_i_see_the_consent_confirm_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_through_the_consent_journey() {
  await p.goto("/sessions/1/consents/start");
  await p.getByRole("button", { name: "Start now" }).click();

  // Name
  await p.getByLabel("First name").fill("Joe");
  await p.getByLabel("Last name").fill("Test");
  await p.getByText("Yes").click();
  await p.getByLabel("Known as").fill("LittleJoeTests");
  await and_i_click_continue();

  // Date of birth
  await p.getByLabel("Day").fill("01");
  await p.getByLabel("Month").fill("01");
  await p.getByLabel("Year").fill("2010");
  await and_i_click_continue();

  // School
  await p.getByText("Yes, they go to this school").click();
  await and_i_click_continue();

  // Parent details
  await p.getByLabel("Your name").fill("Joe Senior");
  await p.getByRole("radio", { name: "Dad" }).click();
  await p.getByLabel("Email address").fill("joe.senior@example.com");
  await and_i_click_continue();
}

async function and_i_click_continue() {
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_consent_confirm_page() {
  await expect(p.locator("h1")).toContainText("Check your answers and confirm");
}

async function then_i_see_the_consent_page() {
  await expect(p.locator("h1")).toContainText(
    "Do you agree to them having the HPV vaccination?",
  );
}

async function when_i_refuse_consent() {
  await p.getByRole("radio", { name: "No" }).click();
}

async function then_i_see_the_reason_page() {
  await expect(p.locator("h1")).toContainText(
    "Please tell us why you do not agree",
  );
}

async function when_i_choose_contains_gelatine_as_the_reason() {
  await p.click("text=Vaccine contains gelatine from pigs");
}
