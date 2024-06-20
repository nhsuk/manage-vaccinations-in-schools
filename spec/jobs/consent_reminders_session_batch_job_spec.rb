require "rails_helper"

describe ConsentRemindersSessionBatchJob, type: :job do
  before { ActionMailer::Base.deliveries.clear }

  it "only sends emails to patients parents to whom they have not been sent yet" do
    patient_with_reminder_sent =
      create(:patient, sent_reminder_at: Time.zone.today)
    patient_not_sent_reminder = create(:patient)
    patient_with_consent = create(:patient, :consent_given_triage_not_needed)
    session =
      create(
        :session,
        patients: [
          patient_with_reminder_sent,
          patient_not_sent_reminder,
          patient_with_consent
        ]
      )

    expect { described_class.perform_now(session) }.to send_email(
      to: patient_not_sent_reminder.parent.email
    )

    expect(ActionMailer::Base.deliveries.count).to eq(1)
  end

  it "updates the sent_reminder_at attribute for patients" do
    patient = create(:patient, sent_reminder_at: nil)
    session = create(:session, patients: [patient])

    described_class.perform_now(session)
    expect(patient.reload.sent_reminder_at).to be_today
  end
end
