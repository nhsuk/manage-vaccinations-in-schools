import { test, expect, Page, APIRequestContext } from "@playwright/test";
import { signInTestUser, fixtures } from "./shared";

let p: Page;
let r: APIRequestContext;
let registrationPage: string;
let locationName: string;

test("Pilot registration - check-boxes", async ({ page, request }) => {
  p = page;
  r = request;

  await given_a_location_requiring_permission_to_observe();

  await when_i_go_to_the_registration_page_for_a_school();
  await and_i_enter_all_the_details();
  await and_i_check_all_the_boxes_except_the_one_to_agree_to_take_part();
  await and_i_click_submit();
  await then_i_see_a_message_saying_i_must_agree_to_all_conditions();

  await when_i_check_all_the_boxes_except_the_one_to_share_contact_details();
  await and_i_click_submit();
  await then_i_see_a_message_saying_i_must_agree_to_all_conditions();

  await when_i_check_all_the_boxes_except_the_one_about_regular_consent();
  await and_i_click_submit();
  await then_i_see_a_message_saying_i_must_agree_to_all_conditions();

  await when_i_check_all_the_boxes_except_the_one_about_observation();
  await and_i_click_submit();
  await then_i_see_a_message_saying_i_must_agree_to_all_conditions();

  await when_i_check_all_the_boxes();
  await and_i_click_submit();
  await then_i_see_the_confirmation_message();
});

async function given_a_location_requiring_permission_to_observe() {
  let response = await r.post("/testing/generate-campaign", {
    data: {
      location: {
        permission_to_observe_required: true,
      },
    },
    timeout: 10000,
    headers: {
      Accept: "application/json",
    },
  });
  let json = await response.json();

  registrationPage = json.registrationPage;
  locationName = json.locationName;
}

async function when_i_go_to_the_registration_page_for_a_school() {
  await p.goto(registrationPage);
}

async function and_i_click_submit() {
  await p.click("button[type='submit']");
}

async function and_i_enter_all_the_details() {
  // Parent details
  await p.getByLabel("Your name").fill("Big Daddy Tests");
  await p.getByLabel("Dad").check();
  await p.getByLabel("Email address").fill("daddy.tests@example.com");
  await p.getByLabel("Phone number").fill("07123456789");

  // Child details
  await p.getByLabel("First name").fill("Bobby");
  await p.getByLabel("Last name").fill("Tests");
  await p.getByLabel("Yes").check();
  await p.getByLabel("Preferred name").fill("Drop Table");
  await p.getByLabel("Day").fill("01");
  await p.getByLabel("Month").fill("01");
  await p.getByLabel("Year").fill("2020");
  await p.getByLabel("Address line 1").fill("1 Test Street");
  await p.getByLabel("Address line 1").fill("2nd Floor");
  await p.getByLabel("Town or city").fill("Testville");
  await p.getByLabel("Postcode").fill("TE1 1ST");
  await p.getByLabel("NHS number").fill("999 888 7777");
}

async function and_i_check_all_the_boxes_except_the_one_to_agree_to_take_part() {
  await p.getByLabel("I agree to take part in the pilot").uncheck();
  await p.getByLabel("I agree to share my contact details").check();
  await p.getByLabel("I confirm I’ve responded to the school").check();
  await p
    .getByLabel("I agree to my child’s vaccination session being observed")
    .check();
}

async function then_i_see_a_message_saying_i_must_agree_to_all_conditions() {
  const alert = p.getByRole("alert");
  await expect(alert).toBeVisible();
  await expect(alert).toContainText(
    "You must agree to all of the conditions for taking part in the pilot",
  );
}

async function when_i_check_all_the_boxes_except_the_one_to_share_contact_details() {
  await p.getByLabel("I agree to take part in the pilot").check();
  await p.getByLabel("I agree to share my contact details").uncheck();
  await p.getByLabel("I confirm I’ve responded to the school").check();
  await p
    .getByLabel("I agree to my child’s vaccination session being observed")
    .check();
}

async function when_i_check_all_the_boxes_except_the_one_about_regular_consent() {
  await p.getByLabel("I agree to take part in the pilot").check();
  await p.getByLabel("I agree to share my contact details").check();
  await p.getByLabel("I confirm I’ve responded to the school").uncheck();
  await p
    .getByLabel("I agree to my child’s vaccination session being observed")
    .check();
}

async function when_i_check_all_the_boxes_except_the_one_about_observation() {
  await p.getByLabel("I agree to take part in the pilot").check();
  await p.getByLabel("I agree to share my contact details").check();
  await p.getByLabel("I confirm I’ve responded to the school").check();
  await p
    .getByLabel("I agree to my child’s vaccination session being observed")
    .uncheck();
}

async function when_i_check_all_the_boxes() {
  await p.getByLabel("I agree to take part in the pilot").check();
  await p.getByLabel("I agree to share my contact details").check();
  await p.getByLabel("I confirm I’ve responded to the school").check();
  await p
    .getByLabel("I agree to my child’s vaccination session being observed")
    .check();
}

async function then_i_see_the_confirmation_message() {
  await expect(
    p.getByRole("heading", {
      name: "Thank you for registering your interest in the NHS school vaccinations pilot",
    }),
  ).toBeVisible();
}
