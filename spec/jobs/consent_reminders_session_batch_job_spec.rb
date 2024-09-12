# frozen_string_literal: true

describe ConsentRemindersSessionBatchJob do
  it "only sends emails to patients parents to whom they have not been sent yet" do
    programme = create(:programme)
    parents = create_list(:parent, 2)
    patient_with_reminder_sent =
      create(:patient, sent_reminder_at: Time.zone.today)
    patient_not_sent_reminder = create(:patient, parents:)
    patient_with_consent =
      create(:patient, :consent_given_triage_not_needed, programme:)
    session =
      create(
        :session,
        programme:,
        patients: [
          patient_with_reminder_sent,
          patient_not_sent_reminder,
          patient_with_consent
        ]
      )

    expect { described_class.perform_now(session) }.to send_email(
      to: parents.first.email
    ).and send_email(to: parents.second.email)

    expect(ActionMailer::Base.deliveries.count).to eq(2)
  end

  it "updates the sent_reminder_at attribute for patients" do
    patient = create(:patient, sent_reminder_at: nil)
    session = create(:session, patients: [patient])

    described_class.perform_now(session)
    expect(patient.reload.sent_reminder_at).to be_today
  end
end
