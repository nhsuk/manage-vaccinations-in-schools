import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("School - match response", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();

  await when_i_go_to_the_registration_page_for_a_school();
  await then_i_see_the_page_with_the_school_name();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_registration_page_for_a_school() {
  await p.goto("/schools/1/registrations/new");
}

async function then_i_see_the_page_with_the_school_name() {
  await expect(
    p.getByRole("heading", { name: fixtures.schoolName }),
  ).toBeVisible();
}
