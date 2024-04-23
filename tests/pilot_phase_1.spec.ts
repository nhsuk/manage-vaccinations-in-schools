import { test, expect, Page } from "@playwright/test";
import { signInTestUser, fixtures, formatDate } from "./shared";

let p: Page;

test("Pilot journey", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_phase_1_is_enabled();

  await given_i_am_signed_in();

  await when_i_go_to_the_sessions_page();
  await then_i_should_see_a_session_link();

  await when_i_click_on_the_session_link();
  await then_i_should_see_the_session_details_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_phase_1_is_enabled() {
  await p.goto("/flipper/features/pilot_phase_1");
  await expect(p.getByText("pilot_phase_1")).toBeVisible();

  if (await p.getByText("Disabled").isVisible()) {
    await p.getByRole("button", { name: "Fully Enable" }).click();
    await expect(p.getByText("Fully enabled")).toBeVisible();
  }
}

async function given_i_am_signed_in() {
  await signInTestUser(p);
}

async function when_i_go_to_the_sessions_page() {
  await p.goto("/sessions");
}

async function then_i_should_see_a_session_link() {
  await expect(
    p.getByRole("link", { name: fixtures.schoolName }),
  ).toBeVisible();
}

async function when_i_click_on_the_session_link() {
  await p.getByRole("link", { name: fixtures.schoolName }).click();
}

async function then_i_should_see_the_session_details_page() {
  await expect(
    p.getByRole("heading", { name: "Session details" }),
  ).toBeVisible();
}
