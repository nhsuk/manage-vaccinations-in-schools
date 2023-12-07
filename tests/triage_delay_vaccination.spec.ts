import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;

test("Triage - delay vaccination", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();
  await when_i_go_to_the_triage_page();

  await when_i_click_on_a_patient();
  await and_i_enter_a_note_and_delay_vaccination();
  await when_i_click_to_view_the_child_record();
  await then_they_should_have_the_status_banner_delay_vaccination();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function when_i_go_to_the_triage_page() {
  await p.goto("/sessions/1/triage");
}

async function when_i_click_on_a_patient() {
  await p.getByRole("link", { name: fixtures.patientThatNeedsTriage }).click();
}

async function and_i_enter_a_note_and_delay_vaccination() {
  await p.getByLabel("Triage notes").fill("Not feeling well, called");
  await p.getByRole("radio", { name: "delay vaccination" }).click();
  await p.getByRole("button", { name: "Save triage" }).click();
}

async function when_i_click_to_view_the_child_record() {
  await p.click("text=View child record");
}

async function then_they_should_have_the_status_banner_delay_vaccination() {
  await expect(
    p.locator(".nhsuk-heading-m", { hasText: /Delay vaccination/ }),
  ).toBeVisible();
}
