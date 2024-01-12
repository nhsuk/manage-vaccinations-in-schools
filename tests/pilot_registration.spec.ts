import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("School - match response", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();

  await when_i_go_to_the_registration_page_for_a_school();
  await then_i_see_the_page_with_the_school_name();

  await when_i_click_submit();
  await then_it_shows_me_validation_errors();

  await when_i_enter_my_details();
  await and_i_click_submit();
  await then_i_see_the_confirmation_message();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_registration_page_for_a_school() {
  await p.goto("/schools/1/registration/new");
}

async function then_i_see_the_page_with_the_school_name() {
  await expect(
    p.getByRole("heading", { name: fixtures.schoolName }),
  ).toBeVisible();
}

async function when_i_click_submit() {
  await p.click("button[type='submit']");
}
const and_i_click_submit = when_i_click_submit;

async function then_it_shows_me_validation_errors() {
  const alert = p.getByRole("alert");
  await expect(alert).toBeVisible();
  await expect(alert).toContainText("Enter your name");
  await expect(alert).toContainText("Enter your email address");
  await expect(alert).toContainText("Choose your relationship");
}

async function when_i_enter_my_details() {
  await p.getByLabel("Your name").fill("Big Daddy Tests");
  await p.getByLabel("Dad").check();
  await p.getByLabel("Email address").fill("daddy.tests@example.com");
  await p.getByLabel("Phone number").fill("07123456789");
}

async function then_i_see_the_confirmation_message() {
  await expect(
    p.getByRole("heading", {
      name: "Thank you for registering your interest in the NHS school vaccinations pilot",
    }),
  ).toBeVisible();
}
