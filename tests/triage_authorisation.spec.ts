import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared/sign_in";

let p: Page;

test("Triage authorisation", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await when_i_sign_in_as_a_nurse_from_another_team();
  await and_i_go_to_the_triage_page();
  await then_i_should_only_see_my_patients();

  await when_i_go_to_the_triage_page_of_another_team();
  await then_i_should_get_an_error();

  await when_i_go_to_triage_a_patient_belonging_to_another_team();
  await then_i_should_get_an_error();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_sign_in_as_a_nurse_from_another_team() {
  await signInTestUser(
    p,
    "nurse.jackie@example.com",
    "nurse.jackie@example.com",
  );
}

async function and_i_go_to_the_triage_page() {
  await p.goto("/sessions/2/triage");
}

async function then_i_should_only_see_my_patients() {
  await expect(
    p.locator("#needs-triage-4 .nhsuk-table__body .nhsuk-table__row"),
  ).toHaveCount(4);
}

async function when_i_go_to_the_triage_page_of_another_team() {
  await p.goto("/sessions/1/triage");
}

async function then_i_should_get_an_error() {
  await expect(
    p.getByRole("heading", { name: "Page not found" }),
  ).toBeVisible();
}

async function when_i_go_to_triage_a_patient_belonging_to_another_team() {
  await p.goto("/sessions/1/patients/1/triage");
}
