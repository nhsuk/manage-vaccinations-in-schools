import { test, expect, Page } from "@playwright/test";

let p: Page;

test("Parental consent", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await when_i_go_to_the_consent_start_page();
  await then_i_see_the_consent_start_page();

  await when_i_click_the_start_button();
  await then_i_see_the_edit_name_page();

  await when_i_enter_the_childs_name();
  await and_i_click_continue();
  await then_i_see_the_date_of_birth_page();

  await when_i_enter_the_childs_date_of_birth();
  await and_i_click_continue();
  await then_i_see_the_confirm_your_childs_school_page();

  await when_i_select_no_this_is_not_their_school();
  await and_i_click_continue();
  await then_i_see_the_cannot_consent_page();

  await when_i_click_back();
  await when_i_select_yes_this_is_their_school();
  await and_i_click_continue();
  await then_i_see_the_parent_details_page();

  await when_i_enter_the_parent_details();
  await and_i_click_continue();
  await then_i_see_the_phone_contact_page();

  await when_i_enter_the_phone_contact_details();
  await and_i_click_continue();
  await then_i_see_the_consent_page();

  await when_i_fill_in_the_consent_form();
  await and_i_click_continue();
  await then_i_see_the_gp_page();

  await when_i_fill_in_the_gp_form();
  await and_i_click_continue();
  await then_i_see_the_address_form();

  await when_i_fill_in_the_address_form();
  await and_i_click_continue();
  await then_i_see_the_first_health_question();

  await when_i_submit_all_the_health_questions();
  await then_i_see_the_consent_confirm_page();

  await when_i_click_the_confirm_button();
  await then_i_see_the_confirmation_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_click_back() {
  await p.getByRole("link", { name: "Back" }).click();
}

async function when_i_go_to_the_consent_start_page() {
  await p.goto("/sessions/2/consents/start");
}

async function when_i_click_the_start_button() {
  await p.getByRole("button", { name: "Start now" }).click();
}

async function when_i_click_the_confirm_button() {
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function when_i_enter_the_childs_name() {
  await p.getByLabel("First name").fill("Joe");
  await p.getByLabel("Last name").fill("Test");
  await p.getByText("Yes").click();
  await p.getByLabel("Known as").fill("LittleJoeTests");
}

async function when_i_enter_the_childs_date_of_birth() {
  await p.getByLabel("Day").fill("01");
  await p.getByLabel("Month").fill("01");
  await p.getByLabel("Year").fill("2010");
}

async function and_i_click_continue() {
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_consent_start_page() {
  await expect(p.locator("h1")).toContainText(
    "Give or refuse consent for a flu vaccination",
  );
}

async function then_i_see_the_consent_confirm_page() {
  await expect(p.locator("h1")).toContainText("Check your answers and confirm");
}

async function then_i_see_the_confirmation_page() {
  await expect(p.locator("h1")).toContainText(
    "Joe Test will get their nasal flu vaccination",
  );
}

async function then_i_see_the_edit_name_page() {
  await expect(p.locator("h1")).toContainText("What is your child’s name?");
}

async function then_i_see_the_date_of_birth_page() {
  await expect(p.locator("h1")).toContainText(
    "What is your child’s date of birth?",
  );
}

async function then_i_see_the_confirm_your_childs_school_page() {
  await expect(p.locator("h1")).toContainText("Confirm your child’s school");
}

async function when_i_select_no_this_is_not_their_school() {
  await p.getByText("No, they go to a different school").click();
}

async function then_i_see_the_cannot_consent_page() {
  await expect(p.locator("h1")).toContainText(
    "You cannot give or refuse consent through this service",
  );
}

async function when_i_select_yes_this_is_their_school() {
  await p.getByText("Yes, they go to this school").click();
}

async function then_i_see_the_parent_details_page() {
  await expect(p.locator("h1")).toContainText("About you");
}

async function when_i_enter_the_parent_details() {
  await p.getByLabel("Your name").fill("Joe Senior");
  await p.getByRole("radio", { name: "Dad" }).click();
  await p.getByLabel("Email address").fill("joe.senior@example.com");
  await p.getByLabel("Phone number").fill("07123456789");
}

async function then_i_see_the_consent_page() {
  await expect(p.locator("h1")).toContainText(
    "Do you agree to them having a nasal flu vaccination?",
  );
}

async function when_i_fill_in_the_consent_form() {
  await p.getByText("Yes, I agree to them having a nasal vaccine").click();
}

async function then_i_see_the_phone_contact_page() {
  await expect(p.locator("h1")).toContainText("Phone contact method");
}

async function when_i_enter_the_phone_contact_details() {
  await p.getByRole("radio", { name: "I do not have specific needs" }).click();
}

async function then_i_see_the_gp_page() {
  await expect(p.locator("h1")).toContainText(
    "Is your child registered with a GP?",
  );
}

async function when_i_fill_in_the_gp_form() {
  await p.getByLabel("Yes, they are registered with a GP").click();
  await p.getByLabel("Name of GP surgery").fill("Test GP Surgery");
}

async function then_i_see_the_address_form() {
  await expect(p.locator("h1")).toContainText("Home address");
}

async function when_i_fill_in_the_address_form() {
  await p.getByLabel("Address line 1").fill("1 Test Street");
  await p.getByLabel("Town or city").fill("Test Town");
  await p.getByLabel("Postcode").fill("TE1 1ST");
}

async function then_i_see_the_first_health_question() {
  await expect(p.locator("h1")).toContainText(
    "Has your child been diagnosed with asthma?",
  );
}

async function when_i_submit_all_the_health_questions() {
  for (let i = 1; i <= 8; i++) {
    await p.getByRole("radio", { name: "No" }).click();
    await and_i_click_continue();
  }
}
