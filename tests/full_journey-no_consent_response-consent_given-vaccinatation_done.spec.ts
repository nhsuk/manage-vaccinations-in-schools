import { test, expect, Page } from "@playwright/test";

let p: Page;

test("Full journey - no consent response - consent given - vaccination done", async ({
  page,
}) => {
  p = page;
  await given_the_app_is_setup();

  await given_i_am_doing_triage();
  await when_i_select_a_child_with_no_consent_response();
  await then_i_see_the_parents_contact_info();

  await given_i_call_the_parent_and_receive_consent();
  await when_i_record_the_consent_given();
  await and_i_record_the_triage_details();
  await then_i_see_that_the_child_is_ready_to_vaccinate();

  await given_i_am_performing_the_vaccination();
  await when_i_record_the_successful_vaccination();
  await then_i_see_that_the_child_is_vaccinated();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function given_i_am_doing_triage() {}

async function when_i_select_a_child_with_no_consent_response() {
  await p.goto("/sessions/1/triage");
  await p.getByRole("tab", { name: "Get consent" }).click();
  await p.getByRole("link", { name: "Alexandra Sipes" }).click();
}

async function then_i_see_the_parents_contact_info() {
  await expect(
    p.getByRole("heading", { name: "Alexandra Sipes" }),
  ).toBeVisible();
  await expect(p.getByText("Carl Sipes")).toBeVisible();
}

async function given_i_call_the_parent_and_receive_consent() {}

async function when_i_record_the_consent_given() {
  await p.getByRole("button", { name: "Get consent" }).click();
  await p.fill('[name="consent_response[parent_name]"]', "Carl Sipes");
  await p.fill('[name="consent_response[parent_phone]"]', "07700900000");
  await p.getByRole("radio", { name: "Dad" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByRole("radio", { name: "Yes, they agree" }).click();
  await p.getByRole("button", { name: "Continue" }).click();
}

async function and_i_record_the_triage_details() {
  const radio = (n: number) =>
    `input[name="consent_response[question_${n}][response]"][value="no"]`;

  await p.click(radio(0));
  await p.click(radio(1));
  await p.click(radio(2));
  await p.click(radio(3));
  await p.fill('[name="consent_response[triage][notes]"]', "Some notes");
  await p.getByRole("radio", { name: "Ready to vaccinate" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_i_see_that_the_child_is_ready_to_vaccinate() {
  await expect(p.locator(".nhsuk-notification-banner__content")).toContainText(
    "Consent saved for Alexandra Sipes",
  );
  await p.getByRole("tab", { name: "Triage complete" }).click();
  const row = p.locator(`tr`, { hasText: "Alexandra Sipes" });
  await expect(row.getByTestId("child-action")).toContainText("Vaccinate");
}

async function given_i_am_performing_the_vaccination() {}

async function when_i_record_the_successful_vaccination() {
  await p.goto("/sessions/1/vaccinations");
  await p.getByRole("tab", { name: "Action needed" }).click();
  await p.getByRole("link", { name: "Alexandra Sipes" }).click();

  await p.getByRole("radio", { name: "Yes, they got the HPV vaccine" }).click();
  await p.getByRole("radio", { name: "Left arm" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByRole("radio", { name: "IE5343" }).click();
  await p.getByRole("button", { name: "Continue" }).click();

  await p.getByRole("button", { name: "Confirm" }).click();
}

async function then_i_see_that_the_child_is_vaccinated() {
  await expect(p.locator(".nhsuk-notification-banner__content")).toContainText(
    "Record saved for Alexandra Sipes",
  );
  await p.getByRole("tab", { name: /^Vaccinated/ }).click();
  const row = p.locator(`tr`, { hasText: "Alexandra Sipes" });
  await expect(row.getByTestId("child-action")).toContainText("Vaccinated");
}
