import { test, expect, Page } from "@playwright/test";

let p: Page;

test("Parental consent", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await when_i_go_to_the_consent_start_page();
  await then_i_see_the_consent_start_page();

  await when_i_click_the_start_button();
  await then_i_see_the_edit_name_page_for_the_first_form();

  await when_i_go_to_the_consent_start_page();
  await and_i_click_the_start_button();
  await then_i_see_the_edit_name_page_for_the_second_form();

  await when_i_go_to_the_first_form();
  await then_i_see_the_consent_start_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_consent_start_page() {
  await p.goto("/sessions/1/consents/start");
}

async function when_i_click_the_start_button() {
  await p.getByRole("button", { name: "Start now" }).click();
}
const and_i_click_the_start_button = when_i_click_the_start_button;

async function then_i_see_the_consent_start_page() {
  await expect(p.locator("h1")).toContainText(
    "Give or refuse consent for an HPV vaccination",
  );
}

async function then_i_see_the_edit_name_page_for_the_first_form() {
  expect(p.url()).toContain("/1/edit/name");
}

async function then_i_see_the_edit_name_page_for_the_second_form() {
  expect(p.url()).toContain("/2/edit/name");
}

async function when_i_go_to_the_first_form() {
  await p.goto("/sessions/1/consents/1/edit/name");
}
