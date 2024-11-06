import { Context } from "artillery";
import { expect, Page } from "@playwright/test";

export async function parentJourney(page: Page, context: Context) {
  const { target, username, password, session } = context.vars;

  // Configure authentication
  const auth = Buffer.from(`${username}:${password}`).toString("base64");
  await page.setExtraHTTPHeaders({
    Authorization: `Basic ${auth}`,
  });

  // Start
  await page.goto(`${target}/consents/${session}/hpv/start`);
  await expect(page.getByRole("button", { name: "Start now" })).toBeVisible();
  await page.getByRole("button", { name: "Start now" }).click();

  // Name
  await expect(
    page.getByRole("heading", { name: "What is your child’s name?" }),
  ).toBeVisible();
  await page.getByLabel("First name", { exact: true }).fill("John");
  await page.getByLabel("Last name", { exact: true }).fill("Smith");
  await page.getByLabel("No", { exact: true }).check();
  await page.getByRole("button", { name: "Continue" }).click();

  // Date of birth
  await expect(
    page.getByRole("heading", {
      name: "What is your child’s date of birth?",
    }),
  ).toBeVisible();
  await page.getByLabel("Day").fill("1");
  await page.getByLabel("Month").fill("1");
  await page.getByLabel("Year").fill("2010");
  await page.getByRole("button", { name: "Continue" }).click();

  // Confirm school
  await expect(
    page.getByRole("heading", { name: "Confirm your child’s school" }),
  ).toBeVisible();
  await page.getByLabel("Yes, they go to this school").check();
  await page.getByRole("button", { name: "Continue" }).click();

  // About you
  await expect(page.getByRole("heading", { name: "About you" })).toBeVisible();
  await page.getByLabel("Your name").fill("Sarah Smith");
  await page.getByLabel("Mum").check();
  await page.getByLabel("Email address").fill("sarah@example.com");
  await page.getByRole("button", { name: "Continue" }).click();

  // Consent
  await expect(
    page.getByRole("heading", {
      name: "Do you agree to them having the HPV vaccination?",
    }),
  ).toBeVisible();
  await page.getByLabel("Yes, I agree").check();
  await page.getByRole("button", { name: "Continue" }).click();

  // GP
  await expect(
    page.getByRole("heading", {
      name: "Is your child registered with a GP?",
    }),
  ).toBeVisible();
  await page.getByLabel("Yes, they are registered with a GP").check();
  await page.getByLabel("Name of GP surgery").fill("Local GP");
  await page.getByRole("button", { name: "Continue" }).click();

  // Address
  await expect(
    page.getByRole("heading", { name: "Home address" }),
  ).toBeVisible();
  await page.getByLabel("Address line 1").fill("123 High St");
  await page.getByLabel("Town or city").fill("London");
  await page.getByLabel("Postcode").fill("SW1 1AA");
  await page.getByRole("button", { name: "Continue" }).click();

  // Health questions
  const healthQuestions = [
    { identifier: "severe allergies" },
    { identifier: "medical conditions" },
    { identifier: "severe reaction" },
    { identifier: "extra support" },
  ];
  for (const question of healthQuestions) {
    await expect(page.getByText(question.identifier)).toBeVisible();
    await page.getByLabel("No").check();
    await page.getByRole("button", { name: "Continue" }).click();
  }

  // Confirm
  await expect(
    page.getByRole("heading", { name: "Check your answers" }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Confirm" }).click();
  await expect(
    page.getByText("John Smith will get their HPV vaccination at school"),
  ).toBeVisible();
  await expect(
    page.getByText("We’ve sent a confirmation to sarah@example.com"),
  ).toBeVisible();
}
