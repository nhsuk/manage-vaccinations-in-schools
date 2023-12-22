export { signInTestUser } from "./sign_in";

// These fixtures need to be updated whenever the test data is regenerated
// from the seed data and the data changes in significant ways.
export const fixtures = {
  parentName: "Lauren Pacocha", // Made up / arbitrary
  parentRole: "Mum",

  // Get from /sessions/1/consents, "No response" tab
  patientThatNeedsConsent: "Jose Pacocha",
  secondPatientThatNeedsConsent: "Sebastian Farrell",

  // Get from /sessions/1/consents, "Consent conflicts" tab
  patientWithConflictingConsent: "Gus Langworth",

  // Get from /sessions/1/triage, "Triage needed" tab; check that they don't
  // have existing triage
  patientThatNeedsTriage: "Freddie Russel",
  secondPatientThatNeedsTriage: "Marcelino Wintheiser",

  // Get from /sessions/1/vaccinations, "Action needed" tab
  patientThatNeedsVaccination: "Brittany Klocko",
  secondPatientThatNeedsVaccination: "Brenton Kautzer",

  // Get from /sessions/1/patients/Y/vaccinations/batch/edit
  vaccineBatch: "CV2898",

  // Get from /sessions, signed in as Nurse Jackie
  schoolName: /Park Wood Middle School/,
};
