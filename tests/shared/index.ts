export { signInTestUser } from "./sign_in";

// These fixtures need to be updated whenever the test data is regenerated
// from the seed data and the data changes in significant ways.
export const fixtures = {
  parentName: "Lauren Pacocha", // Made up / arbitrary
  parentRole: "Mum",

  // Get from /sessions/1/consents, "No response" tab
  patientThatNeedsConsent: "Ahmad Langworth",
  secondPatientThatNeedsConsent: "Harold Macejkovic",

  // Get from /sessions/1/consents, "Consent conflicts" tab
  patientWithConflictingConsent: "Betsey Hegmann",

  // Get from /sessions/1/triage, "Triage needed" tab; check that they don't
  // have existing triage
  patientThatNeedsTriage: "Farah Welch",
  secondPatientThatNeedsTriage: "Janeth Larkin",

  // Get from /sessions/1/vaccinations, "Action needed" tab
  patientThatNeedsVaccination: "Mina DuBuque",
  secondPatientThatNeedsVaccination: "Raymundo Towne",

  // Get from /sessions/1/patients/Y/vaccinations/batch/edit
  vaccineBatch: "EP2141",

  // Get from /sessions, signed in as Nurse Joy
  schoolName: "Dorothy Barley Junior School and Special Needs Base",

  // Get from /sessions, signed in as Nurse Jackie
  secondSchoolName: /The Halley Academy/,

  // A 'given' consent response from /schools/1, signed in as Nurse Joy
  unmatchedConsentFormParentName: "Royal Cassin",
  unmatchedConsentFormChildName: "Valrie Murray",
  cohortRecordChildNameForUnmatchedConsentForm: "Ahmad Langworth",

  // School from /pilot/registrations
  pilotSchoolName: "Holy Rosary Catholic Primary Academy",

  // Children whose parents have expressed interest in the pilot These should
  // all exist in the downloaded list of registered parents from
  // /pilot/registrations or from the "registrations" section of the example
  // campaign CSV. We only the first 3.
  registeredChildren: [
    { firstName: "Ray", lastName: "O'Conner", fullName: "Ray O'Conner" },
    {
      firstName: "Louis",
      lastName: "Williamson",
      fullName: "Louis Williamson",
    },
    {
      firstName: "Sylvester",
      lastName: "Heidenreich",
      fullName: "Sylvester Heidenreich",
    },
  ],
};

export function formatDate(date: Date): string {
  return date.toLocaleDateString("en-GB", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
}
