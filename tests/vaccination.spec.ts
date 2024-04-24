import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("Vaccination", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await when_i_go_to_the_vaccinations_page();
  await when_i_click_on_a_patient();
  await then_i_see_the_vaccination_page();
  await then_i_see_the_responses_to_health_questions();

  // Successful vaccination
  await when_i_record_a_vaccination();
  await then_i_should_see_the_select_batch_page();

  await when_i_select_a_batch();
  await then_i_should_see_the_check_answers_page();

  await when_i_press_confirm();
  await then_i_should_see_a_success_message();
  await and_i_should_see_the_outcome_as_vaccinated();

  await when_i_click_on_the_vaccinated_tab();
  await when_i_click_on_a_patient();
  await then_i_should_see_the_vaccination_details();

  // Unsuccessful vaccination
  await when_i_click_on_back();
  await when_i_click_on_another_patient();
  await when_i_record_an_unsuccessful_vaccination();
  await then_i_should_see_the_reason_page();

  await when_i_choose_a_reason();
  await when_i_press_confirm();
  await then_i_should_see_a_success_message();
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

async function when_i_click_on_a_patient() {
  await p
    .getByRole("link", { name: fixtures.patientThatNeedsVaccination })
    .click();
}

async function then_i_see_the_vaccination_page() {
  await expect(p.locator("h1")).toContainText(
    fixtures.patientThatNeedsVaccination,
  );
}

async function then_i_see_the_responses_to_health_questions() {
  await expect(
    p.locator(".nhsuk-card", { hasText: "Consent given by" }),
  ).toHaveText(/Responses to health questions/);

  await expect(
    p.locator("dt", { hasText: "Does the child have any severe allergies" }),
  ).toBeVisible();
}

async function when_i_record_a_vaccination() {
  await p.click("text=Yes, they got the HPV vaccine");
  await p.click("text=Left arm");
  await p.click("text=Continue");
}

async function then_i_should_see_the_select_batch_page() {
  await expect(p.locator("h1")).toContainText("Which batch did you use?");
}

async function when_i_select_a_batch() {
  await p.click(`text=${fixtures.vaccineBatch}`);
  await p.click("text=Continue");
}

async function then_i_should_see_a_success_message() {
  await expect(p.getByRole("alert")).toContainText("Success");
}

async function and_i_should_see_the_outcome_as_vaccinated() {
  await p.getByRole("link", { name: /^Vaccinated/ }).click();
  const row = p.locator(`tr`, {
    hasText: fixtures.patientThatNeedsVaccination,
  });
  await expect(row).toBeVisible();
  await expect(row).toContainText("Vaccinated");
}

async function then_i_should_see_the_check_answers_page() {
  await expect(p.getByRole("heading", { level: 1 })).toContainText(
    "Check and confirm",
  );
}

async function when_i_press_confirm() {
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_i_should_see_the_vaccination_details() {
  await expect(p.getByRole("heading", { name: "Vaccinated" })).toBeVisible();
}

async function when_i_click_on_the_vaccinated_tab() {
  await p.getByRole("link", { name: /^Vaccinated/ }).click();
}

async function when_i_record_an_unsuccessful_vaccination() {
  await p.click("text=No, they did not get it");
  await p.click("text=Continue");
}

async function then_i_should_see_the_reason_page() {
  await expect(p.locator("legend")).toContainText(
    "Why was the HPV vaccine not given",
  );
}

async function when_i_click_on_another_patient() {
  await p
    .getByRole("link", { name: fixtures.secondPatientThatNeedsVaccination })
    .click();
}

async function when_i_choose_a_reason() {
  await p.click("text=They were not well enough");
  await p.click("text=Continue");
}

async function when_i_click_on_back() {
  await p.click("text=Back");
}
