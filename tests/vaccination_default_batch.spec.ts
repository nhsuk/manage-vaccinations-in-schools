import { test, expect, Page } from "@playwright/test";

let p: Page;

test("Sets default batch for today", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();

  await when_i_go_to_the_vaccinations_page();
  await and_i_click_on_the_patient("Ernie Funk");
  await and_i_record_a_vaccination();
  await and_i_select_the_batch("IE5343");
  await and_i_set_the_batch_to_be_the_default_for_today();
  await and_i_press_continue();
  await then_i_should_see_the_check_answers_page();

  await when_i_press_confirm();
  await then_i_should_see_a_success_message();

  await when_i_click_on_the_tab("Action needed (7)");
  await and_i_click_on_the_patient("Man Swaniawski");
  await and_i_record_a_vaccination();
  await then_i_should_see_the_check_answers_page();
  await and_the_batch_should_be_displayed("IE5343");
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_vaccinations_page() {
  await p.goto("/sessions/1/vaccinations");
}

async function when_i_click_on_the_tab(name: string) {
  await p.getByRole("tab", { name: name, exact: true }).click();
}

async function and_i_record_a_vaccination() {
  await p.click("text=Yes, they got the HPV vaccine");
  await p.click("text=Left arm");
  await p.click("text=Continue");
}

async function and_i_select_the_batch(batch: string) {
  await p.click(`text=${batch}`);
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

async function when_i_click_on_the_patient(name: string) {
  await p.getByRole("link", { name: name }).click();
}
const and_i_click_on_the_patient = when_i_click_on_the_patient;

async function and_the_batch_should_be_displayed(batch: string) {
  await expect(p.getByText(batch)).toBeVisible();
}
