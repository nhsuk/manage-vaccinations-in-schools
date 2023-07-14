import { expect } from "@playwright/test";
import { patientExpectations } from "./example_data";

let p = null;

export async function init_page(page) {
  p = page;
}

export async function given_the_app_is_setup() {
  await p.goto("/reset");
}

export async function when_i_click_on_the_tab(name: string) {
  await p.getByRole("tab", { name: name, exact: true }).click();
}

export async function when_i_click_on_the_patient(name) {
  await p.getByRole("link", { name: name }).click();
}

export async function when_i_click_on_the_option(option) {
  await p.getByRole("radio", { name: option }).click();
}

export async function then_i_should_be_on_the_tab(name: string) {
  await expect(p.getByRole("tab", { name: name, exact: true })).toHaveAttribute(
    "aria-selected",
    "true",
  );
}

export async function then_i_should_see_a_banner_for_the_patient(name) {
  const patient = patientExpectations[name];
  const title = patient["bannerTitle"];
  const colourClass = "app-consent-banner--" + patient["actionColour"];
  const content = patient["bannerContent"];

  if (title == null) return;

  await expect(
    p.locator(".app-consent-banner > span"),
    `[${name}] Banner title`,
  ).toHaveText(title);
  await expect(
    p.locator("div.app-consent-banner"),
    `[${name}] Banner colour`,
  ).toHaveClass(new RegExp(colourClass));

  if (content != null)
    for (let text of content) await expect(p.getByText(text)).toBeVisible();
}

export function humanise(str: string) {
  return capitalise(str.replace(/_/g, " "));
}

export function capitalise(str: string) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}
