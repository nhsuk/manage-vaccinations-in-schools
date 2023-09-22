import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared/sign_in";

let p: Page;

test("Vaccination authorisation", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await when_i_sign_in_as_a_nurse_from_another_team();
  await and_i_go_to_the_vaccinations_page();
  await then_i_should_get_an_error();

  await when_i_go_to_the_record_vaccination_page_belonging_to_another_team();
  await then_i_should_get_an_error();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_sign_in_as_a_nurse_from_another_team() {
  await signInTestUser(p, "nurse.jackie@test", "nurse.jackie@test");
}

async function and_i_go_to_the_vaccinations_page() {
  await p.goto("/sessions/1/vaccinations");
}

async function then_i_should_get_an_error() {
  await expect(
    p.getByRole("heading", { name: "Page not found" }),
  ).toBeVisible();
}

async function when_i_go_to_the_record_vaccination_page_belonging_to_another_team() {
  await p.goto("/sessions/1/patients/1/vaccinations");
}
