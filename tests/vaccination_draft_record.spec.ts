import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("Vaccination draft record", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await given_i_am_on_the_vaccination_page_for_a_child();
  await when_i_record_a_vaccination();
  await and_i_select_a_batch();
  await and_i_go_back_to_the_patient_page();
  await then_i_should_see_the_vaccinated_option_selected();

  // TODO: Currently broken.
  // await when_i_continue_to_the_batch_page();
  // await then_i_should_see_the_batch_selected();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function given_i_am_on_the_vaccination_page_for_a_child() {
  await p.goto("/sessions/1/vaccinations");
  await p.getByRole("tab", { name: "Action needed" }).click();
  await p
    .getByRole("link", { name: fixtures.patientThatNeedsVaccination })
    .click();
}

async function when_i_record_a_vaccination() {
  await p.getByRole("radio", { name: "Yes, they got the HPV vaccine" }).click();
  await p.getByRole("radio", { name: "Left arm" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function and_i_select_a_batch() {
  await p.getByRole("radio", { name: `${fixtures.vaccineBatch}` }).click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function and_i_go_back_to_the_patient_page() {
  await p.getByRole("link", { name: "Back" }).click();
  await p.getByRole("link", { name: "Back" }).click();
}

async function then_i_should_see_the_vaccinated_option_selected() {
  await expect(
    p.getByRole("radio", { name: "Yes, they got the HPV vaccine" }),
  ).toBeChecked();
  await expect(p.getByRole("radio", { name: "Left arm" })).toBeChecked();
}

// async function when_i_continue_to_the_batch_page() {
//   await p.getByRole("button", { name: "Continue" }).click();
// }

// async function then_i_should_see_the_batch_selected() {
//   await expect(p.getByRole("radio", { name: `${fixtures.vaccineBatch}` })).toBeChecked();
// }
