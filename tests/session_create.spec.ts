import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("Session create", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await when_i_go_to_the_sessions_list();
  await and_i_click_on_the_add_session_button();
  await then_i_see_the_location_page();

  await when_i_submit_without_choosing_a_location();
  await then_i_see_the_location_page_with_errors();

  await when_i_choose_my_location();
  await then_i_see_the_vaccine_page();

  await when_i_submit_without_choosing_a_vaccine();
  await then_i_see_the_vaccine_page_with_errors();

  await when_i_choose_a_vaccine();
  await then_i_see_the_timeline_page();

  await when_i_choose_my_timeline();
  await then_i_see_the_confirm_details_page();

  await when_i_click_on_the_confirm_button();
  await then_i_see_the_session_details_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function when_i_go_to_the_sessions_list() {
  await p.goto("/sessions");
}

async function and_i_click_on_the_add_session_button() {
  await p.click("text=Add a new session");
}

async function then_i_see_the_location_page() {
  await expect(
    p.getByRole("heading", {
      name: "Which school is it at?",
    }),
  ).toBeVisible();
}

async function when_i_submit_without_choosing_a_location() {
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_location_page_with_errors() {
  await expect(p.getByRole("alert")).toContainText("Choose a school");
}

async function when_i_choose_my_location() {
  await p.click("text=" + fixtures.schoolName);
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_vaccine_page() {
  await expect(
    p.getByRole("heading", {
      name: "Which routine vaccination is being given?",
    }),
  ).toBeVisible();
}

async function when_i_submit_without_choosing_a_vaccine() {
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_vaccine_page_with_errors() {
  await expect(p.getByRole("alert")).toContainText("Choose a vaccine");
}

async function when_i_choose_a_vaccine() {
  await p.click("text=HPV");
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_confirm_details_page() {
  await expect(
    p.getByRole("heading", { name: "Check and confirm details" }),
  ).toBeVisible();

  await expect(p.locator(".nhsuk-card")).toHaveText(
    new RegExp("School" + fixtures.schoolName),
  );

  await expect(p.locator(".nhsuk-card")).toHaveText(
    new RegExp("Vaccine" + "HPV"),
  );
}

async function when_i_click_on_the_confirm_button() {
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_i_see_the_session_details_page() {
  // TODO: Test for the session; page properly
  await expect(
    p.getByRole("heading", { name: "Check consent responses" }),
  ).toBeVisible();
}

async function then_i_see_the_timeline_page() {
  await expect(
    p.getByRole("heading", {
      name: "What’s the timeline for consent requests?",
    }),
  ).toBeVisible();
}

async function when_i_choose_my_timeline() {
  await p.getByRole("radio", { name: "14 days before the session" }).click();
  await p
    .getByRole("radio", { name: "7 days after the first consent request" })
    .click();
  await p
    .getByRole("radio", {
      name: "Allow responses until the day of the session",
    })
    .click();
  await p.getByRole("button", { name: "Continue" }).click();
}
