import { test, expect } from "@playwright/test";

let p = null;

test("Records vaccinations", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();

  await when_i_go_to_the_vaccinations_page();
  await then_i_should_see_no_outcome_yet();

  await when_i_click_on_the_first_patient();
  await then_i_should_see_the_vaccinations_page();

  await when_i_record_a_vaccination();
  // await then_i_should_see_the_check_answers_page();

  // await when_i_press_confirm();
  await then_i_should_see_a_success_message();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_vaccinations_page() {
  await p.goto("/sessions/1/vaccinations");
}

async function then_i_should_see_no_outcome_yet() {
  await expect(p.getByTestId("child-status").nth(0)).toContainText(
    "No outcome yet"
  );
}

async function when_i_click_on_the_first_patient() {
  await p.getByTestId("child-link").nth(0).click();
}

async function then_i_should_see_the_vaccinations_page() {
  await expect(p.getByRole("heading", { name: "Child details" })).toContainText(
    "Child details"
  );
}

async function when_i_record_a_vaccination() {
  await p.click("text=Yes, they got the HPV vaccine");
  await p.click("text=Continue");
}

async function then_i_should_see_a_success_message() {
  await expect(p.getByRole("alert").nth(0)).toContainText("Success");
}

async function then_i_should_see_the_check_answers_page() {
  await expect(p.getByRole("heading")).toContainText("Check and confirm");
}

async function when_i_press_confirm() {
  await p.click("text=Confirm");
}
