import { test, expect } from "@playwright/test";
import { examplePatient } from "./example_data";

let p = null;

test("Records other delivery site", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();

  await when_i_go_to_the_vaccinations_page();
  await and_i_click_on_the_patient("Ernie Funk");
  await and_i_record_a_vaccination_with_other_delivery_site();
  await and_i_press_continue();
  await then_i_should_see_the_other_delivery_site_page();

  await when_i_select("Intramuscular");
  await and_i_select("Right arm (lower position)");
  await and_i_press_continue();
  await then_i_should_see_the_select_batch_page();

  await when_i_select_a_batch();
  await then_i_should_see_the_check_answers_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_vaccinations_page() {
  await p.goto("/sessions/1/vaccinations");
}

async function and_i_record_a_vaccination_with_other_delivery_site() {
  await p.click("text=Yes, they got the HPV vaccine");
  await p.click("text=Other");
}

async function when_i_select(text) {
  await p.getByText(text).click();
}
const and_i_select = when_i_select;

async function then_i_should_see_the_other_delivery_site_page() {
  await expect(p.getByRole("heading")).toContainText(
    "Tell us how the vaccination was given",
  );
}

async function then_i_should_see_the_check_answers_page() {
  await expect(p.getByRole("heading")).toContainText("Check and confirm");
}

async function when_i_select_a_batch() {
  await p.click("text=IE5343");
  await p.click("text=Continue");
}

async function then_i_should_see_the_select_batch_page() {
  await expect(p.locator("legend")).toContainText("Which batch did you use?");
}

async function when_i_press_continue() {
  await p.click("text=Continue");
}
const and_i_press_continue = when_i_press_continue;

async function when_i_click_on_the_patient(name: string) {
  await p.getByRole("link", { name: name }).click();
}
const and_i_click_on_the_patient = when_i_click_on_the_patient;
