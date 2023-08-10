import { test, expect, Page } from "@playwright/test";

let p: Page;

test("Vaccination default batch", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();

  // Setting the batch
  await when_i_go_to_the_vaccinations_page();
  await and_i_click_on_a_patient();
  await and_i_record_a_vaccination();
  await and_i_select_a_batch();
  await and_i_set_the_batch_to_be_the_default_for_today();
  await and_i_press_continue();
  await then_i_should_see_the_check_answers_page();

  await when_i_press_confirm();
  await then_i_should_see_a_success_message();

  // Default batch is displayed
  await when_i_click_on_the_action_needed_tab();
  await and_i_click_on_another_patient();
  await and_i_record_a_vaccination();
  await then_i_should_see_the_check_answers_page();
  await and_the_batch_should_be_displayed();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_vaccinations_page() {
  await p.goto("/sessions/1/vaccinations");
}

async function when_i_click_on_the_action_needed_tab() {
  await p.getByRole("tab", { name: "Action needed" }).click();
}

async function and_i_record_a_vaccination() {
  await p.click("text=Yes, they got the HPV vaccine");
  await p.click("text=Left arm");
  await p.click("text=Continue");
}

async function and_i_select_a_batch() {
  await p.click("text=IE5343");
}

async function and_i_set_the_batch_to_be_the_default_for_today() {
  await p.click("text=Default to this batch for today");
}

async function then_i_should_see_a_success_message() {
  await expect(p.getByRole("alert")).toContainText("Success");
}

async function then_i_should_see_the_check_answers_page() {
  await expect(p.getByRole("heading")).toContainText("Check and confirm");
}

async function when_i_press_confirm() {
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function and_i_press_continue() {
  await p.click("text=Continue");
}

async function and_i_click_on_a_patient() {
  await p.getByRole("link", { name: "Ernie Funk" }).click();
}

async function and_i_click_on_another_patient() {
  await p.getByRole("link", { name: "Man Swaniawski" }).click();
}

async function and_the_batch_should_be_displayed() {
  await expect(p.getByText("IE5343")).toBeVisible();
}
