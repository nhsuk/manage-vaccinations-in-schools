import { test, expect, Page } from "@playwright/test";

let p: Page;

test("Parental consent", async ({ page }) => {
  p = page;

  await given_the_app_is_setup();

  await given_i_am_on_the_edit_name_page();
  await when_i_continue_without_entering_anything();
  await then_i_see_the_name_validations_errors();
  await when_i_choose_that_the_child_uses_a_common_name_and_continue();
  await then_i_see_the_common_name_validation_errors();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function given_i_am_on_the_edit_name_page() {
  await p.goto("/sessions/1/consents/start");
  await p.getByRole("button", { name: "Start now" }).click();
}

async function when_i_continue_without_entering_anything() {
  await p.getByRole("button", { name: "Continue" }).click();
}

async function when_i_choose_that_the_child_uses_a_common_name_and_continue() {
  await p.getByText("Yes").click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function then_i_see_the_name_validations_errors() {
  const alert = p.getByRole("alert");
  await expect(alert).toBeVisible();
  await expect(alert).toContainText("Enter a first name");
  await expect(alert).toContainText("Enter a last name");
  await expect(alert).toContainText(
    "Tell us whether they use a different name",
  );
}

async function then_i_see_the_common_name_validation_errors() {
  const alert = p.getByRole("alert");
  await expect(alert).toBeVisible();
  await expect(alert).toContainText("Enter a name");
}
