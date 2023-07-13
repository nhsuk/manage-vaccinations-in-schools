// Read example campaign file and extract patients by name

import * as fs from "fs";
import * as path from "path";

export const patient_expectations = {
  "Blaine DuBuque": {
    tab: "Needs triage",
    action: "Triage",
    action_colour: "blue",
    banner_title: "Triage needed",
    triage_reasons: ["Notes need triage"],
    consent_response: "Given by",
    parent_relationship: "Mother",
  },
  "Caridad Sipes": {
    tab: "Needs triage",
    action: "Triage: follow up",
    action_colour: "aqua-green",
    banner_title: "Triage follow-up needed",
    triage_reasons: ["Notes need triage"],
  },
  "Jessika Lindgren": {
    tab: "Triage complete",
    action: "Vaccinate",
    action_colour: "purple",
  },
  "Kristal Schumm": {
    tab: "Triage complete",
    action: "Do not vaccinate",
    action_colour: "red",
    banner_title: "Do not vaccinate",
  },
  "Alexandra Sipes": {
    tab: "Get consent",
    action: "Get consent",
    action_colour: "yellow",
    banner_title: "No-one responded to our requests for consent",
  },
  "Ernie Funk": {
    tab: "No triage needed",
    action: /.*/,
    action_colour: "purple",
  },
  "Fae Skiles": {
    tab: "No triage needed",
    action: "Check refusal",
    action_colour: "orange",
  },
  "Man Swaniawski": {
    tab: "No triage needed",
    action: "Vaccinate",
    action_colour: "purple",
  },
};

const example_campaign_path = path.join(
  __dirname,
  "../db/sample_data/example-test-campaign.json",
);
const example_campaign = JSON.parse(
  fs.readFileSync(example_campaign_path, "utf8"),
);

export function example_patient(name: string): Record<string, any> | null {
  for (const patient of example_campaign.patients) {
    const fullName = patient.firstName + " " + patient.lastName;
    if (fullName === name) {
      return patient;
    }
  }
  return null;
}
