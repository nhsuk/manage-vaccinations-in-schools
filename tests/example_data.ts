// Read example campaign file and extract patients by name

import * as fs from "fs";
import * as path from "path";

const example_campaign_path = path.join(
  __dirname,
  "../db/sample_data/example-test-campaign.json"
);
const example_campaign = JSON.parse(
  fs.readFileSync(example_campaign_path, "utf8")
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
