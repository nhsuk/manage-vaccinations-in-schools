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

  await when_i_continue_without_uploading_a_file();
  await then_i_should_see_an_error();

  await when_i_upload_a_malformed_csv();
  await then_i_should_see_an_error();

  await when_i_upload_the_cohort_file();
  await then_i_should_see_the_success_page();
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

async function when_i_upload_the_cohort_file() {
  await p.setInputFiles(
    'input[type="file"]',
    "tests/fixtures/pilot-cohort.csv",
  );
  await p.getByRole("button", { name: "Upload the cohort list" }).click();
}

async function then_i_should_see_the_success_page() {
  await expect(
    p.getByRole("heading", { name: "Cohort data uploaded" }),
  ).toBeVisible();
}

async function when_i_continue_without_uploading_a_file() {
  await p.getByRole("button", { name: "Upload the cohort list" }).click();
}

async function then_i_should_see_an_error() {
  await expect(
    p.getByRole("heading", { name: "There is a problem" }),
  ).toBeVisible();
}

async function when_i_upload_a_malformed_csv() {
  await p.setInputFiles('input[type="file"]', "tests/fixtures/malformed.csv");
  await p.getByRole("button", { name: "Upload the cohort list" }).click();
}
