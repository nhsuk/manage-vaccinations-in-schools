import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("Vaccination other delivery site", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await when_i_go_to_the_vaccinations_page();
  await and_i_click_on_a_patient();
  await and_i_record_a_vaccination_with_other_delivery_site();
  await and_i_press_continue();
  await then_i_should_see_the_other_delivery_site_page();

  await when_i_select_intramuscular();
  await and_i_select_right_arm_lower_position();
  await and_i_press_continue();
  await then_i_should_see_the_select_batch_page();

  await when_i_select_a_batch();
  await then_i_should_see_the_check_answers_page();
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

async function and_i_record_a_vaccination_with_other_delivery_site() {
  await p.click("text=Yes, they got the HPV vaccine");
  await p.click("text=Other");
}

async function when_i_select_intramuscular() {
  await p.getByText("Intramuscular").click();
}

async function and_i_select_right_arm_lower_position() {
  await p.getByText("Right arm (lower position)").click();
}

async function then_i_should_see_the_other_delivery_site_page() {
  await expect(p.getByRole("heading", { level: 1 })).toContainText(
    "Tell us how the vaccination was given",
  );
}

async function then_i_should_see_the_check_answers_page() {
  await expect(p.getByRole("heading", { level: 1 })).toContainText(
    "Check and confirm",
  );
}

async function when_i_select_a_batch() {
  await p.click(`text=${fixtures.vaccineBatch}`);
  await p.click("text=Continue");
}

async function then_i_should_see_the_select_batch_page() {
  await expect(p.locator("legend")).toContainText("Which batch did you use?");
}

async function and_i_press_continue() {
  await p.click("text=Continue");
}

async function and_i_click_on_a_patient() {
  await p
    .getByRole("link", { name: fixtures.patientThatNeedsVaccination })
    .click();
}
