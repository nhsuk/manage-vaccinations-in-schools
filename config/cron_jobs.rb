# frozen_string_literal: true

CRON_JOBS = {
  clinic_session_invitations: {
    cron: "every day at 9am",
    class: "EnqueueClinicSessionInvitationsJob",
    description: "Send school clinic invitation emails to parents"
  },
  invalidate_self_consents: {
    cron: "every day at 2am",
    class: "InvalidateSelfConsentsJob",
    description:
      "Invalidate all self-consents and associated triage for the previous day"
  },
  patients_clear_registration: {
    cron: "every day at 5:00",
    class: "PatientsClearRegistrationJob",
    description:
      "Clears the registration of patients for the previous academic year"
  },
  remove_import_csv: {
    cron: "every day at 1am",
    class: "RemoveImportCSVJob",
    description: "Remove CSV data from old cohort and immunisation imports"
  },
  school_consent_requests: {
    cron: "every day at 4pm",
    class: "EnqueueSchoolConsentRequestsJob",
    description:
      "Send school consent request emails to parents for each session"
  },
  school_consent_reminders: {
    cron: "every day at 4pm",
    class: "EnqueueSchoolConsentRemindersJob",
    description:
      "Send school consent reminder emails to parents for each session"
  },
  school_session_reminders: {
    cron: "every day at 9am",
    class: "SendSchoolSessionRemindersJob",
    description: "Send school session reminder emails to parents"
  },
  status_updater: {
    cron: "every day at 3am",
    class: "StatusUpdaterJob",
    description: "Updates the status of all patients"
  },
  trim_active_record_sessions: {
    cron: "every day at 2am",
    class: "TrimActiveRecordSessionsJob",
    description: "Remove ActiveRecord sessions older than 30 days"
  },
  update_patients_from_pds: {
    cron: "every day at 6:00 and 18:00",
    class: "EnqueueUpdatePatientsFromPDSJob",
    description: "Keep patient details up to date with PDS."
  },
  vaccination_confirmations: {
    cron: "every day at 13:00 and 16:00 and 19:00",
    class: "SendVaccinationConfirmationsJob",
    description: "Send vaccination confirmation emails to parents"
  }
}.freeze
