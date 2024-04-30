import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared";

let p: Page;

test("Pilot - upload cohort", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await when_i_visit_the_pilot_dashboard();
  await then_i_should_see_the_manage_pilot_page();

  await when_i_click_the_upload_cohort_link();
  await then_i_should_see_the_upload_cohort_page();

  await when_i_continue_without_uploading_a_file();
  await then_i_should_see_an_error();

  await when_i_upload_a_malformed_csv();
  await then_i_should_see_an_error();

  await when_i_upload_a_cohort_file_with_invalid_headers();
  await then_i_should_the_errors_page_with_invalid_headers();
  await and_i_should_be_able_to_go_back_to_the_upload_page();

  await when_i_upload_a_cohort_file_with_invalid_fields();
  await then_i_should_the_errors_page_with_invalid_fields();
  await and_i_should_be_able_to_go_to_the_upload_page();

  await when_i_upload_the_cohort_file();
  await then_i_should_see_the_success_page();
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

async function when_i_click_the_upload_cohort_link() {
  await p.getByRole("link", { name: "Upload the cohort list" }).click();
}

async function then_i_should_see_the_upload_cohort_page() {
  await expect(
    p.getByRole("heading", { name: "Upload the cohort list" }),
  ).toBeVisible();
  await expect(p.locator(".nhsuk-inset-text")).toContainText(
    "Your current cohort has 21 children",
  );
}

async function when_i_upload_the_cohort_file() {
  await p.setInputFiles(
    'input[type="file"]',
    "spec/fixtures/cohort_list/valid_cohort.csv",
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
  await p.setInputFiles(
    'input[type="file"]',
    "spec/fixtures/cohort_list/malformed.csv",
  );
  await p.getByRole("button", { name: "Upload the cohort list" }).click();
}

async function when_i_upload_a_cohort_file_with_invalid_headers() {
  await p.setInputFiles(
    'input[type="file"]',
    "spec/fixtures/cohort_list/invalid_headers.csv",
  );
  await p.getByRole("button", { name: "Upload the cohort list" }).click();
}

async function then_i_should_the_errors_page_with_invalid_headers() {
  await expect(
    p.getByRole("heading", {
      level: 1,
      name: "The cohort list could not be added",
    }),
  ).toBeVisible();
  await expect(p.getByRole("heading", { level: 2, name: "CSV" })).toBeVisible();
}

async function and_i_should_be_able_to_go_back_to_the_upload_page() {
  await p.getByRole("link", { name: "Back to cohort upload page" }).click();
}

async function when_i_upload_a_cohort_file_with_invalid_fields() {
  await p.setInputFiles(
    'input[type="file"]',
    "spec/fixtures/cohort_list/invalid_fields.csv",
  );
  await p.getByRole("button", { name: "Upload the cohort list" }).click();
}

async function then_i_should_the_errors_page_with_invalid_fields() {
  await expect(
    p.getByRole("heading", {
      level: 1,
      name: "The cohort list could not be added",
    }),
  ).toBeVisible();
  await expect(
    p.getByRole("heading", { level: 2, name: "Row 2", exact: true }),
  ).toBeVisible();
}

async function and_i_should_be_able_to_go_to_the_upload_page() {
  await p.getByRole("link", { name: "Upload a new cohort list" }).click();
}
