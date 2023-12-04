export { signInTestUser } from "./sign_in";

// These fixtures need to be updated whenever the test data is regenerated
// from the seed data and the data changes in significant ways.
export const fixtures = {
  parentName: "Lauren Pfeffer", // Made up / arbitrary
  parentRole: "Mum",

  // Get from /sessions/1/triage, "Get consent" tab
  patientThatNeedsConsent: "Davis Pfeffer",
  secondPatientThatNeedsConsent: "Verlie Gorczany",

  // Get from /sessions/1/triage, "Needs triage" tab
  patientThatNeedsTriage: "Brittany Klocko",
  secondPatientThatNeedsTriage: "Loris Effertz",

  // Get from /sessions/1/vaccinations, "Action needed" tab
  patientThatNeedsVaccination: "Fonda Krajcik",
  secondPatientThatNeedsVaccination: "Sebastian Farrell",

  // Get from /sessions, signed in as Nurse Jackie
  schoolName: /Roman Hill Primary School/,

  // Get from /sessions/1/patients/Y/vaccinations/batch/edit
  vaccineBatch: "QM4000",
};
