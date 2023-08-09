// Read example campaign file and extract patients by name

import * as fs from "fs";
import * as path from "path";

export const patientExpectations = {
  "Blaine DuBuque": {
    tab: "Needs triage (2)",
    action: "Triage",
    actionColour: "blue",
    bannerTitle: "Triage needed",
    triageReasons: ["Notes need triage"],
    consentResponse: "Given by",
    parentRelationship: "Mother",
  },
  "Caridad Sipes": {
    tab: "Needs triage (2)",
    action: "Triage started",
    actionColour: "aqua-green",
    bannerTitle: "Triage started",
    triageReasons: ["Notes need triage"],
  },
  "Jessika Lindgren": {
    tab: "Triage complete (2)",
    action: "Vaccinate",
    actionColour: "purple",
  },
  "Kristal Schumm": {
    tab: "Triage complete (2)",
    action: "Do not vaccinate",
    actionColour: "red",
    bannerTitle: "Do not vaccinate",
  },
  "Alexandra Sipes": {
    tab: "Get consent (2)",
    action: "Get consent",
    actionColour: "yellow",
    bannerTitle: "No-one responded to our requests for consent",
  },
  "Ernie Funk": {
    tab: "No triage needed (3)",
    action: /.*/,
    actionColour: "purple",
  },
  "Fae Skiles": {
    tab: "No triage needed (3)",
    action: "Check refusal",
    actionColour: "orange",
  },
  "Man Swaniawski": {
    tab: "No triage needed (3)",
    action: "Vaccinate",
    actionColour: "purple",
  },
};

const exampleCampaignPath = path.join(
  __dirname,
  "../../db/sample_data/example-test-campaign.json",
);
const exampleCampaign = JSON.parse(
  fs.readFileSync(exampleCampaignPath, "utf8"),
);

export function examplePatient(name: string): Record<string, any> | null {
  for (const patient of exampleCampaign.patients) {
    const fullName = patient.firstName + " " + patient.lastName;
    if (fullName === name) {
      return patient;
    }
  }
  return null;
}
