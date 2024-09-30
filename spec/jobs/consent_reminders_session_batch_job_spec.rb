# frozen_string_literal: true

describe ConsentRemindersSessionBatchJob do
  subject(:perform_now) do
    travel_to(today) { described_class.perform_now(session) }
  end

  let(:today) { Date.new(2024, 1, 1) }

  let(:programme) { create(:programme) }
  let(:parents) { create_list(:parent, 2) }

  let(:patient_with_reminder_sent) do
    create(
      :patient,
      :consent_request_sent,
      consent_reminder_sent_at: Date.current
    )
  end
  let(:patient_not_sent_reminder) do
    create(:patient, :consent_request_sent, parents:)
  end
  let(:patient_with_consent) do
    create(:patient, :consent_given_triage_not_needed, programme:)
  end

  let(:session) do
    create(
      :session,
      programme:,
      patients: [
        patient_with_reminder_sent,
        patient_not_sent_reminder,
        patient_with_consent
      ]
    )
  end

  it "only sends emails to patients parents to whom they have not been sent yet" do
    expect { perform_now }.to send_email(
      to: parents.first.email
    ).and send_email(to: parents.second.email)

    expect(ActionMailer::Base.deliveries.count).to eq(2)
  end

  it "updates the consent_reminder_sent_at attribute for patients" do
    expect { perform_now }.to change {
      patient_not_sent_reminder.reload.consent_reminder_sent_at
    }.to(today)
  end
end
