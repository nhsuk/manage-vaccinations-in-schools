import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared";

let p: Page;
let download;

test("Pilot - upload cohort", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await when_i_visit_the_pilot_dashboard();
  await then_i_should_see_the_manage_pilot_page();

  await when_i_click_the_registrations_link();
  await then_i_should_see_the_registrations_page();

  await when_i_click_the_download_cohort_button();
  await then_it_should_download_the_cohort_file();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function when_i_visit_the_pilot_dashboard() {
  await p.goto("/pilot");
}

async function then_i_should_see_the_manage_pilot_page() {
  await expect(
    p.getByRole("heading", { level: 1, name: "Manage pilot" }),
  ).toBeVisible();
}

async function when_i_click_the_registrations_link() {
  await p
    .getByRole("link", { name: "See who’s interested in the pilot" })
    .click();
}

async function then_i_should_see_the_registrations_page() {
  await expect(
    p.getByRole("heading", {
      level: 1,
      name: "Parents interested in the pilot",
    }),
  ).toBeVisible();
}

async function when_i_click_the_download_cohort_button() {
  [download] = await Promise.all([
    p.waitForEvent("download"),
    p
      .getByRole("link", {
        name: "Download data for registered parents (CSV)",
      })
      .click(),
  ]);
}

async function then_it_should_download_the_cohort_file() {
  expect(download.suggestedFilename()).toBe("registered_parents.csv");
}
