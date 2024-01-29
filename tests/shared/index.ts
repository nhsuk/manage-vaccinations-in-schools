export { signInTestUser } from "./sign_in";

// These fixtures need to be updated whenever the test data is regenerated
// from the seed data and the data changes in significant ways.
export const fixtures = {
  parentName: "Lauren Pacocha", // Made up / arbitrary
  parentRole: "Mum",

  // Get from /sessions/1/consents, "No response" tab
  patientThatNeedsConsent: "Clora Mueller",
  secondPatientThatNeedsConsent: "Nathanial Jones",

  // Get from /sessions/1/consents, "Consent conflicts" tab
  patientWithConflictingConsent: "Alonzo Klocko",

  // Get from /sessions/1/triage, "Triage needed" tab; check that they don't
  // have existing triage
  patientThatNeedsTriage: "Mickey Schroeder",
  secondPatientThatNeedsTriage: "Phil Spencer",

  // Get from /sessions/1/vaccinations, "Action needed" tab
  patientThatNeedsVaccination: "Michaele Schmitt",
  secondPatientThatNeedsVaccination: "Brittany Klocko",

  // Get from /sessions/1/patients/Y/vaccinations/batch/edit
  vaccineBatch: "VU2074",

  // Get from /sessions, signed in as Nurse Joy
  schoolName: "Great Cornard Middle School",

  // Get from /sessions, signed in as Nurse Jackie
  secondSchoolName: /Kesteven and Sleaford High School Selective Academy/,

  // Any consent response from /schools/1, signed in as Nurse Joy
  unmatchedConsentFormParentName: "Kacy Mosciski",
  unmatchedConsentFormChildName: "Werner Boyle",
};
