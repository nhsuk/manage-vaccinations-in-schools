import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared";

let p: Page;

test("Pilot - manage cohort", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await when_i_visit_the_dashboard();
  await then_i_should_see_the_manage_pilot_link();

  await when_i_click_the_manage_pilot_link();
  await then_i_should_see_the_manage_pilot_page();

  await when_i_click_the_upload_cohort_link();
  await then_i_should_see_the_upload_cohort_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function when_i_visit_the_dashboard() {
  await p.goto("/dashboard");
}

async function then_i_should_see_the_manage_pilot_link() {
  await expect(p.getByRole("link", { name: "Manage pilot" })).toBeVisible();
}

async function when_i_click_the_manage_pilot_link() {
  await p.getByRole("link", { name: "Manage pilot" }).click();
}

async function then_i_should_see_the_manage_pilot_page() {
  await expect(
    p.getByRole("heading", { level: 1, name: "Manage pilot" }),
  ).toBeVisible();
}

async function when_i_click_the_upload_cohort_link() {
  await p.getByRole("link", { name: "Upload the cohort list" }).click();
}

async function then_i_should_see_the_upload_cohort_page() {
  await expect(
    p.getByRole("heading", { name: "Upload the cohort list" }),
  ).toBeVisible();
}
