import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("Pilot registration", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();

  await when_i_go_to_the_registration_page_for_a_school();
  await then_i_see_the_page_with_the_school_name();

  await when_i_click_submit();
  await then_it_shows_me_validation_errors();

  await when_i_enter_my_details();
  await and_i_enter_my_childs_details();
  await and_i_check_the_conditions_for_taking_part();
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
  await expect(alert).toContainText(
    "Enter the first line of the child’s address",
  );
  await expect(alert).toContainText("Enter the town or city the child is in");
  await expect(alert).toContainText("Enter the child’s postcode");
  await expect(alert).toContainText("Enter the child’s date of birth");
  await expect(alert).toContainText("Enter the child’s first name");
  await expect(alert).toContainText("Enter the child’s last name");
  await expect(alert).toContainText("Enter your email address");
  await expect(alert).toContainText("Enter your name");
  await expect(alert).toContainText("Choose your relationship");
  await expect(alert).toContainText(
    "Tell us whether the child use a different name",
  );
  await expect(alert).toContainText(
    "You must agree to all of the conditions for taking part in the pilot",
  );
}

async function when_i_enter_my_details() {
  await p.getByLabel("Your name").fill("Big Daddy Tests");
  await p.getByLabel("Dad").check();
  await p.getByLabel("Email address").fill("daddy.tests@example.com");
  await p.getByLabel("Phone number").fill("07123456789");
}

async function and_i_enter_my_childs_details() {
  await p.getByLabel("First name").fill("Bobby");
  await p.getByLabel("Last name").fill("Tests");
  await p.getByLabel("Yes").check();
  await p.getByLabel("Preferred name").fill("Drop Table");
  await p.getByLabel("Day").fill("01");
  await p.getByLabel("Month").fill("01");
  await p.getByLabel("Year").fill("2020");
  await p.getByLabel("Address line 1").fill("1 Test Street");
  await p.getByLabel("Address line 1").fill("2nd Floor");
  await p.getByLabel("Town or city").fill("Testville");
  await p.getByLabel("Postcode").fill("TE1 1ST");
  await p.getByLabel("NHS number").fill("999 888 7777");
}

async function and_i_check_the_conditions_for_taking_part() {
  await p.getByLabel("I agree to take part in the pilot").check();
  await p
    .getByLabel(
      "I agree to share my contact details with NHS England for the purpose of administering payments and electronic communications",
    )
    .check();
  await p
    .getByLabel(
      "I confirm I’ve responded to the school’s regular request for consent for my child’s HPV vaccination",
    )
    .check();
  await p
    .getByLabel("I agree to my child’s vaccination session being observed")
    .check();
}

async function then_i_see_the_confirmation_message() {
  await expect(
    p.getByRole("heading", {
      name: "Thank you for registering your interest in the NHS school vaccinations pilot",
    }),
  ).toBeVisible();
}
