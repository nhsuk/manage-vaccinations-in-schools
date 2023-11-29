export { signInTestUser } from "./sign_in";

// These fixtures need to be updated whenever the test data is regenerated
// from the seed data and the data changes in significant ways.
export const fixtures = {
  parentName: "Lauren Welch",
  parentRole: "Mum",

  patientThatNeedsConsent: "Farah Welch",
  secondPatientThatNeedsConsent: "Wonda Schuster",

  patientThatNeedsTriage: "Alma Pacocha",
  secondPatientThatNeedsTriage: "Tessie Borer",

  patientThatNeedsVaccination: "Brittany Klocko",
  secondPatientThatNeedsVaccination: "Luigi Ondricka",

  vaccineBatch: "ZS7570",
};
