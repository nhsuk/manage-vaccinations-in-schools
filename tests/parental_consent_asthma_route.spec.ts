import { test, expect, Page } from "@playwright/test";

let p: Page;

test("Parental consent asthma route", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await when_i_go_to_the_consent_start_page();
  await then_i_see_the_consent_start_page();

  await when_i_fill_in_the_consent_questions_up_to_the_asthma_question();
  await then_i_see_the_asthma_question();

  await when_i_submit_that_my_son_has_an_asthma_condition();
  await then_i_see_the_first_asthma_specific_question();

  await when_i_fill_in_the_asthma_specific_questions();
  await then_i_see_the_next_non_asthma_specific_question();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");

  // Enable parent contact method feature
  await p.goto("/flipper/features/parent_contact_method");
  await expect(
    p.getByText("Home Features parent_contact_method"),
  ).toBeVisible();
  if (await p.getByText("Disabled").isVisible()) {
    await p.getByRole("button", { name: "Fully Enable" }).click();
    await expect(p.getByText("Fully enabled")).toBeVisible();
  }
}

async function when_i_go_to_the_consent_start_page() {
  await p.goto("/sessions/2/consents/start");
}

async function then_i_see_the_consent_start_page() {
  await expect(p.locator("h1")).toContainText(
    "Give or refuse consent for a flu vaccination",
  );
}

async function when_i_fill_in_the_consent_questions_up_to_the_asthma_question() {
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
}

async function then_i_see_the_asthma_question() {
  await expect(p.locator("h1")).toContainText(
    "Has your child been diagnosed with asthma?",
  );
}

async function when_i_submit_that_my_son_has_an_asthma_condition() {
  await p.getByRole("radio", { name: "Yes" }).click();
  await p
    .getByLabel("Give details")
    .fill("He has had asthma for a few years now and carries a puffer");
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_first_asthma_specific_question() {
  await expect(p.locator("h1")).toContainText(
    "Have they taken oral steroids in the last 2 weeks?",
  );
}

async function when_i_fill_in_the_asthma_specific_questions() {
  await p.getByRole("radio", { name: "No" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByRole("radio", { name: "No" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_next_non_asthma_specific_question() {
  await expect(p.locator("h1")).toContainText(
    "Has your child had a flu vaccination in the last 5 months?",
  );
}
