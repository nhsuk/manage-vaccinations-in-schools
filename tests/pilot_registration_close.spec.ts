import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared";

let p: Page;

test("Pilot registration - close", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();
  await and_i_sign_in();
  await when_i_visit_the_parents_registration_page();
  await then_i_see_the_registration_form();

  await when_i_to_to_the_who_has_registered();
  await then_i_see_the_parents_who_have_registered_page();

  await when_click_the_link_to_close_registration();
  await then_i_see_the_confirm_close_registration_page();

  await when_i_return_to_the_list_of_participants();
  await then_i_see_the_parents_who_have_registered_page();

  await when_click_the_link_to_close_registration();
  await and_i_click_the_back_link();
  await then_i_see_the_parents_who_have_registered_page();

  await when_click_the_link_to_close_registration();
  await and_i_confirm_closing_registration();
  await then_i_can_see_that_registration_is_closed();
  await and_the_link_to_close_registration_is_gone();

  await when_i_visit_the_parents_registration_page();
  await then_i_see_the_registration_is_closed_page();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_sign_in() {
  await signInTestUser(p);
}

async function when_i_visit_the_parents_registration_page() {
  await p.goto("/schools/1/registration/new");
}

async function then_i_see_the_registration_form() {
  await expect(
    p.getByRole("heading", {
      name: "Register your interest in the NHS school vaccinations pilot",
    }),
  ).toBeVisible();
}

async function when_i_to_to_the_who_has_registered() {
  await p.goto("/pilot");
  await p.click("text=See who’s interested in the pilot");
}

async function when_click_the_link_to_close_registration() {
  await p
    .getByRole("link", {
      name: "Close pilot to new participants at this school",
    })
    .click();
}

async function then_i_see_the_confirm_close_registration_page() {
  await expect(
    p.getByRole("heading", {
      name: "Are you sure you want to close the pilot to new participants at this school?",
    }),
  ).toBeVisible();
}

async function when_i_return_to_the_list_of_participants() {
  await p
    .getByRole("link", { name: "No, return to list of participants" })
    .click();
}

async function and_i_click_the_back_link() {
  await p.getByRole("link", { name: "Back" }).click();
}

async function then_i_see_the_parents_who_have_registered_page() {
  await expect(
    p.getByRole("heading", { name: "Parents interested in the pilot" }),
  ).toBeVisible();
}

async function and_i_confirm_closing_registration() {
  await p
    .getByRole("button", { name: "Yes, close the pilot to new participants" })
    .click();
}

async function then_i_can_see_that_registration_is_closed() {
  await expect(
    p.getByText("Pilot is now closed to new participants"),
  ).toBeVisible();
}

async function and_the_link_to_close_registration_is_gone() {
  await expect(
    p.getByRole("link", {
      name: "Close pilot to new participants at this school",
    }),
  ).not.toBeVisible();
}

async function then_i_see_the_registration_is_closed_page() {
  await expect(
    p.getByRole("heading", {
      name: "The deadline for registering your interest in the NHS school vaccinations pilot has passed",
    }),
  ).toBeVisible();
}
