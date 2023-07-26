import { test, expect } from "@playwright/test";
import { examplePatient } from "./example_data";

let p = null;

test("Records vaccinations", async ({ page }) => {
  p = page;
  await given_the_app_is_setup();

  await when_i_go_to_the_vaccinations_page();
  await then_i_should_be_on_the_tab("Action needed (8)");

  await when_i_click_on_the_patient("Ernie Funk");
  await then_i_should_see_the_vaccinations_page();
  await then_i_should_see_the_medical_history_section();

  await when_i_click_on_show_answers();
  await then_i_should_see_health_question_responses_if_present("Ernie Funk");

  await when_i_record_a_vaccination();
  await then_i_should_see_the_select_batch_page();

  await when_i_select_a_batch();
  await then_i_should_see_the_check_answers_page();

  await when_i_press_confirm();
  await then_i_should_see_a_success_message();
  await and_i_should_see_the_outcome_as_vaccinated("Ernie Funk");

  await when_i_click_on_the_tab("Vaccinated (1)");
  await then_i_should_be_on_the_tab("Vaccinated (1)");

  await when_i_click_on_the_patient("Ernie Funk");
  await then_i_should_see_the_vaccination_details();

  await when_i_click_on_back();
  await when_i_click_on_the_patient("Jessika Lindgren");
  await when_i_record_an_unsuccessful_vaccination();
  await then_i_should_see_the_reason_page();

  await when_i_choose_a_reason();
  await then_i_should_see_the_check_answers_page();

  await when_i_press_confirm();
  await then_i_should_see_a_success_message();
});

async function given_the_app_is_setup() {
  await p.goto("/reset");
}

async function when_i_go_to_the_vaccinations_page() {
  await p.goto("/sessions/1/vaccinations");
}

async function then_i_should_be_on_the_tab(name: string) {
  await expect(p.getByRole("tab", { name: name, exact: true })).toHaveAttribute(
    "aria-selected",
    "true",
  );
}

async function when_i_click_on_the_tab(name: string) {
  await p.getByRole("tab", { name: name, exact: true }).click();
}

async function then_i_should_see_the_vaccinations_page() {
  await expect(p.getByRole("heading", { name: "Child details" })).toContainText(
    "Child details",
  );
}

async function when_i_record_a_vaccination() {
  await p.click("text=Yes, they got the HPV vaccine");
  await p.click("text=Left arm");
  await p.click("text=Continue");
}

async function then_i_should_see_the_select_batch_page() {
  await expect(p.locator("legend")).toContainText("Which batch did you use?");
}

async function when_i_select_a_batch() {
  await p.click("text=IE5343");
  await p.click("text=Continue");
}

async function then_i_should_see_a_success_message() {
  await expect(p.getByRole("alert")).toContainText("Success");
}

async function and_i_should_see_the_outcome_as_vaccinated(name) {
  const row = p.locator(`tr`, { hasText: name });
  await expect(row.getByTestId("child-action")).toContainText("Vaccinate");
}

async function then_i_should_see_the_check_answers_page() {
  await expect(p.getByRole("heading")).toContainText("Check and confirm");
}

async function when_i_press_confirm() {
  await p.getByRole("button", { name: "Confirm" }).click();
}

async function when_i_click_on_the_patient(name: string) {
  await p.getByRole("link", { name: name }).click();
}
async function then_i_should_see_the_medical_history_section() {
  await p.getByRole("heading", { name: "Medical history" });
}

async function when_i_click_on_show_answers() {
  await p.getByText("Show answers").click();
}

async function then_i_should_see_health_question_responses_if_present(
  name: string,
) {
  let patient = examplePatient(name);
  let consent = patient["consent"];

  if (consent && consent["healthQuestionResponses"]) {
    for (const example_question of consent["healthQuestionResponses"]) {
      await expect(
        p.getByRole("heading", {
          name: example_question["question"],
        }),
      ).toContainText(example_question["question"]);
    }
  } else {
    expect(await p.textContent("body")).not.toContain("Health questions");
  }
}

async function then_i_should_see_the_vaccination_details() {
  await expect(
    p.getByRole("heading", { name: "Vaccination details" }),
  ).toBeVisible();
}

async function when_i_record_an_unsuccessful_vaccination() {
  await p.click("text=No, they did not get it");
  await p.click("text=Continue");
}

async function then_i_should_see_the_reason_page() {
  await expect(p.locator("legend")).toContainText(
    "Why was the HPV vaccine not given",
  );
}

async function when_i_choose_a_reason() {
  await p.click("text=They were not well enough");
  await p.click("text=Continue");
}

async function when_i_click_on_back() {
  await p.click("text=Back");
}
