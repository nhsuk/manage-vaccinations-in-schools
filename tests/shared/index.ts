export { signInTestUser } from "./sign_in";

// These fixtures need to be updated whenever the test data is regenerated
// from the seed data and the data changes in significant ways.
export const fixtures = {
  parentName: "Lauren Pacocha", // Made up / arbitrary
  parentRole: "Mum",

  // Get from /sessions/1/consents, "No response" tab
  patientThatNeedsConsent: "Jose Pacocha",
  secondPatientThatNeedsConsent: "Silvia Waters",

  // Get from /sessions/1/consents, "Consent conflicts" tab
  patientWithConflictingConsent: "Corrinne Hahn",

  // Get from /sessions/1/triage, "Triage needed" tab
  patientThatNeedsTriage: "Michale Fisher",
  secondPatientThatNeedsTriage: "Shenika Hammes",

  // Get from /sessions/1/vaccinations, "Action needed" tab
  patientThatNeedsVaccination: "Brittany Klocko",
  secondPatientThatNeedsVaccination: "Carla Reynolds",

  // Get from /sessions/1/patients/Y/vaccinations/batch/edit
  vaccineBatch: "KD5966",

  // Get from /sessions, signed in as Nurse Jackie
  schoolName: /Fallibroome High School/,
};
