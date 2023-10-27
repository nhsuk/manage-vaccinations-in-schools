import { test, expect, Page } from "@playwright/test";

let p: Page;

test("Parental consent change answers", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await when_i_go_to_the_consent_start_page();
  await then_i_see_the_consent_start_page();

  await when_i_fill_in_the_all_the_consent_questions();
  await then_i_see_the_consent_confirm_page();

  await when_i_click_on_the_change_link_of_the_second_answer();
  await then_i_see_the_health_question();

  await when_i_change_my_answer_to_yes();
  await and_i_click_continue();
  await then_i_see_the_consent_confirm_page();
  await and_i_see_the_answer_i_changed_is_yes();

  await when_i_click_the_confirm_button();
  await then_i_see_the_confirmation_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_consent_start_page() {
  await p.goto("/sessions/2/consents/start");
}

async function then_i_see_the_consent_start_page() {
  await expect(p.locator("h1")).toContainText(
    "Give or refuse consent for a flu vaccination",
  );
}

async function when_i_fill_in_the_all_the_consent_questions() {
  await p.getByRole("button", { name: "Start now" }).click();

  await p.getByLabel("First name").fill("Joe");
  await p.getByLabel("Last name").fill("Test");
  await p.getByText("Yes").click();
  await p.getByLabel("Known as").fill("LittleJoeTests");
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByLabel("Day").fill("01");
  await p.getByLabel("Month").fill("01");
  await p.getByLabel("Year").fill("2010");
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByText("Yes, they go to this school").click();
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByLabel("Your name").fill("Joe Senior");
  await p.getByRole("radio", { name: "Dad" }).click();
  await p.getByLabel("Email address").fill("joe.senior@example.com");
  await p.getByLabel("Phone number").fill("07123456789");
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByRole("radio", { name: "I do not have specific needs" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByText("Yes, I agree to them having a nasal vaccine").click();
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByLabel("Yes, they are registered with a GP").click();
  await p.getByLabel("Name of GP surgery").fill("Test GP Surgery");
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByLabel("Address line 1").fill("1 Test Street");
  await p.getByLabel("Town or city").fill("Test Town");
  await p.getByLabel("Postcode").fill("TE1 1ST");
  await p.getByRole("button", { name: "Continue" }).click();

  for (let i = 1; i <= 8; i++) {
    await p.getByRole("radio", { name: "No" }).click();
    await p.getByRole("button", { name: "Continue" }).click();
  }
}

async function then_i_see_the_consent_confirm_page() {
  await expect(p.locator("h1")).toContainText("Check your answers and confirm");
}

async function when_i_click_on_the_change_link_of_the_second_answer() {
  await p
    .getByRole("link", { name: "Change your answer to health question 4" })
    .click();
}

async function then_i_see_the_health_question() {
  await expect(p.locator("h1")).toContainText(
    "Has your child had a flu vaccination in the last 5 months?",
  );
}

async function when_i_change_my_answer_to_yes() {
  await p.getByRole("radio", { name: "Yes" }).click();
  await p.getByLabel("Give details").fill("He had the flu a month ago");
}

async function and_i_click_continue() {
  await p.getByRole("button", { name: "Continue" }).click();
}

async function and_i_see_the_answer_i_changed_is_yes() {
  await expect(p.getByText("Yes – He had the flu a month ago")).toBeVisible();
}

async function when_i_click_the_confirm_button() {
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_i_see_the_confirmation_page() {
  await expect(p.locator("h1")).toContainText(
    "Joe Test will get their nasal flu vaccination at school",
  );
}
