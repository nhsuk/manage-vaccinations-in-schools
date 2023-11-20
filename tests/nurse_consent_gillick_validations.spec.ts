import { test, expect, Page } from "@playwright/test";
import { signInTestUser } from "./shared/sign_in";

let p: Page;

test("Consent via Gillick competence validations", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();
  await and_i_am_signed_in();

  await given_i_am_assessing_a_child_for_gillick_competence();
  await when_i_continue_without_entering_anything();
  await then_the_gillick_assessment_validation_errors_are_displayed();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function and_i_am_signed_in() {
  await signInTestUser(p);
}

async function given_i_am_assessing_a_child_for_gillick_competence() {
  await p.goto("/sessions/1/vaccinations");
  await p.getByRole("tab", { name: "Action needed" }).click();
  await p.getByRole("link", { name: "Alexandra Sipes" }).click();

  await p.getByRole("radio", { name: "Gillick competence" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByRole("button", { name: "Give your assessment" }).click();
}

async function when_i_continue_without_entering_anything() {
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_the_gillick_assessment_validation_errors_are_displayed() {
  const alert = p.getByRole("alert");
  await expect(alert).toBeVisible();
  await expect(alert).toContainText("Choose if they are Gillick competent");
  await expect(alert).toContainText("Enter details of your assessment");
}
